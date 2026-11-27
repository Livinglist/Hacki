import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/services/services.dart';
import 'package:logger/logger.dart';
import 'package:material_ui/material_ui.dart' show AppLifecycleState;
import 'package:mocktail/mocktail.dart';

import '../../mocks/mocks.dart';

class _MockFilterCubit extends MockCubit<FilterState> implements FilterCubit {}

class _MockPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

class _MockOfflineRepository extends Mock implements OfflineRepository {}

class _MockHackerNewsWebRepository extends Mock
    implements HackerNewsWebRepository {}

class _MockCollapseStateCacheRepository extends Mock
    implements CollapseStateCacheRepository {}

class _MockAppLifecycleService extends Mock implements AppLifecycleService {}

const int _storyId = 100;
const int _threadId = 200;

Comment _comment(
  int id, {
  required int parent,
  int level = 0,
  List<int> kids = const <int>[],
}) => Comment.fromJson(<String, dynamic>{
  'id': id,
  'parent': parent,
  'by': 'author',
  'text': 'Comment $id',
  'kids': kids,
}).copyWith(level: level);

Comment _threadRoot() =>
    _comment(_threadId, parent: _storyId, kids: const <int>[1, 4]);

List<Comment> _thread() => <Comment>[
  _comment(1, parent: _threadId, kids: const <int>[2]),
  _comment(2, parent: 1, level: 1, kids: const <int>[3]),
  _comment(3, parent: 2, level: 2),
  _comment(4, parent: _threadId),
];

Future<void> _waitUntilLoaded(CommentsCubit cubit) async {
  if (cubit.state.status == CommentsStatus.allLoaded) return;
  await cubit.stream
      .firstWhere(
        (CommentsState state) => state.status == CommentsStatus.allLoaded,
      )
      .timeout(const Duration(seconds: 5));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockPreferenceCubit preferenceCubit;
  late PreferenceState preferences;
  late _MockOfflineRepository offlineRepository;
  late MockHackerNewsRepository hackerNewsRepository;
  late _MockCollapseStateCacheRepository collapseStateCacheRepository;
  late StreamController<AppLifecycleState> lifecycle;
  late List<CommentsCubit> cubits;

  CommentsCubit buildCubit({Item? item, bool offline = true}) {
    final _MockFilterCubit filterCubit = _MockFilterCubit();
    when(() => filterCubit.state).thenReturn(FilterState.init());
    final _MockAppLifecycleService appLifecycle = _MockAppLifecycleService();
    when(() => appLifecycle.stream).thenAnswer((_) => lifecycle.stream);

    final CommentsCubit cubit = CommentsCubit(
      filterCubit: filterCubit,
      preferenceCubit: preferenceCubit,
      isOfflineReading: offline,
      item: item ?? _threadRoot(),
      defaultFetchMode: FetchMode.eager,
      defaultCommentsOrder: CommentsOrder.oldestFirst,
      commentCache: CommentCache(),
      offlineRepository: offlineRepository,
      hackerNewsRepository: hackerNewsRepository,
      hackerNewsWebRepository: _MockHackerNewsWebRepository(),
      collapseStateCacheRepository: collapseStateCacheRepository,
      appLifecycleService: appLifecycle,
    );
    cubits.add(cubit);
    return cubit;
  }

  Comment comment(CommentsCubit cubit, int id) =>
      cubit.state.comments.singleWhere((Comment comment) => comment.id == id);

  Future<void> load(CommentsCubit cubit) async {
    await cubit.init();
    await _waitUntilLoaded(cubit);
  }

  setUp(() async {
    locator.registerSingleton<Logger>(MockLogger());
    cubits = <CommentsCubit>[];
    lifecycle = StreamController<AppLifecycleState>.broadcast();
    preferences = PreferenceState.init().copyWithPreference(
      const PreserveCollapseStateAfterScreenExit(val: false),
    );
    preferenceCubit = _MockPreferenceCubit();
    when(() => preferenceCubit.state).thenAnswer((_) => preferences);
    offlineRepository = _MockOfflineRepository();
    hackerNewsRepository = MockHackerNewsRepository();
    collapseStateCacheRepository = _MockCollapseStateCacheRepository();
    when(
      () => collapseStateCacheRepository.cachedItemIdToPreviousStates,
    ).thenReturn(<int, Map<int, Comment>>{});
    when(
      () => collapseStateCacheRepository.saveStoryStates(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => offlineRepository.getCachedCommentsStream(ids: any(named: 'ids')),
    ).thenAnswer((Invocation invocation) {
      final List<int> ids = invocation.namedArguments[#ids]! as List<int>;
      final List<Comment> comments = ids.contains(_threadId)
          ? <Comment>[
              _threadRoot(),
              ..._thread().map(
                (Comment comment) => comment.copyWith(level: comment.level + 1),
              ),
            ]
          : _thread();
      return Stream<Comment>.fromIterable(comments);
    });

    // Clear the session cache through the existing preservation preference.
    final CommentsCubit reset = buildCubit(item: Story.placeholder());
    reset.emit(reset.state.copyWith(status: CommentsStatus.allLoaded));
    await reset.close();
    preferences = PreferenceState.init().copyWithPreference(
      const PersistCollapseStateAcrossSessions(val: false),
    );
  });

  tearDown(() async {
    for (final CommentsCubit cubit in cubits) {
      if (!cubit.isClosed) await cubit.close();
    }
    await lifecycle.close();
    await locator.reset();
  });

  test(
    'restores nested collapse state when reopening a comment thread',
    () async {
      final CommentsCubit first = buildCubit();
      await load(first);
      first.collapse(comment(first, 2));
      first.collapse(comment(first, 1));
      await first.close();

      final CommentsCubit reopened = buildCubit();
      await load(reopened);

      expect(comment(reopened, 1).isCollapsedByUser, isTrue);
      expect(comment(reopened, 2).isCollapsedByUser, isTrue);
      expect(comment(reopened, 2).isHiddenByUser, isTrue);
      expect(comment(reopened, 3).isHiddenByUser, isTrue);
      expect(comment(reopened, 4).isHiddenByUser, isFalse);

      reopened.uncollapse(comment(reopened, 1));
      expect(comment(reopened, 2).isHiddenByUser, isFalse);
      expect(comment(reopened, 2).isCollapsedByUser, isTrue);
      expect(comment(reopened, 3).isHiddenByUser, isTrue);
      verifyNever(
        () => collapseStateCacheRepository.saveStoryStates(any(), any()),
      );
    },
  );

  test(
    'restores persisted state and saves it under the comment thread ID',
    () async {
      preferences = PreferenceState.init();
      when(
        () => collapseStateCacheRepository.cachedItemIdToPreviousStates,
      ).thenReturn(<int, Map<int, Comment>>{
        _threadId: <int, Comment>{
          1: _thread().first.copyWith(isCollapsedByUser: true),
        },
      });
      final CommentsCubit cubit = buildCubit();
      await load(cubit);

      expect(comment(cubit, 1).isCollapsedByUser, isTrue);
      expect(comment(cubit, 2).isHiddenByUser, isTrue);
      expect(comment(cubit, 3).isHiddenByUser, isTrue);

      cubit.uncollapse(comment(cubit, 1));
      lifecycle.add(AppLifecycleState.inactive);
      await Future<void>.delayed(Duration.zero);

      final Map<int, Comment> saved =
          verify(
                () => collapseStateCacheRepository.saveStoryStates(
                  _threadId,
                  captureAny(),
                ),
              ).captured.single
              as Map<int, Comment>;
      expect(saved.keys, unorderedEquals(<int>[1, 2, 3, 4]));
      expect(saved[1]!.isCollapsedByUser, isFalse);
      expect(saved[2]!.isHiddenByUser, isFalse);
      expect(saved[3]!.isHiddenByUser, isFalse);
    },
  );

  test('starts expanded when preserving collapse state is disabled', () async {
    final CommentsCubit first = buildCubit();
    await load(first);
    first.collapse(comment(first, 1));
    await first.close();
    preferences = preferences.copyWithPreference(
      const PreserveCollapseStateAfterScreenExit(val: false),
    );

    final CommentsCubit reopened = buildCubit();
    await load(reopened);

    expect(
      reopened.state.comments.any(
        (Comment comment) =>
            comment.isCollapsedByUser || comment.isHiddenByUser,
      ),
      isFalse,
    );
    verifyNever(
      () => collapseStateCacheRepository.saveStoryStates(any(), any()),
    );
  });

  test('keeps story and comment thread collapse states independent', () async {
    final CommentsCubit thread = buildCubit();
    await load(thread);
    thread.collapse(comment(thread, 1));
    await thread.close();

    final Story story = Story.fromJson(const <String, dynamic>{
      'id': _storyId,
      'kids': <int>[_threadId],
    });
    final CommentsCubit storyThread = buildCubit(item: story);
    await load(storyThread);
    expect(comment(storyThread, 1).isCollapsedByUser, isFalse);
    storyThread.collapse(comment(storyThread, 4));
    await storyThread.close();

    final CommentsCubit reopened = buildCubit();
    await load(reopened);
    expect(comment(reopened, 1).isCollapsedByUser, isTrue);
    expect(comment(reopened, 4).isCollapsedByUser, isFalse);
  });

  test('preserves comment thread collapse state on refresh', () async {
    when(
      () => hackerNewsRepository.fetchItem(id: _threadId),
    ).thenAnswer((_) async => _threadRoot());
    when(
      () => hackerNewsRepository.fetchAllCommentsRecursivelyStream(
        ids: any(named: 'ids'),
        getFromCache: any(named: 'getFromCache'),
      ),
    ).thenAnswer((_) => Stream<Comment>.fromIterable(_thread()));
    final CommentsCubit cubit = buildCubit(offline: false);
    await load(cubit);
    cubit.collapse(comment(cubit, 1));

    await cubit.refresh(onError: null, fetchFromWeb: false);
    await _waitUntilLoaded(cubit);

    expect(comment(cubit, 1).isCollapsedByUser, isTrue);
    expect(comment(cubit, 2).isHiddenByUser, isTrue);
    expect(comment(cubit, 3).isHiddenByUser, isTrue);
    expect(comment(cubit, 4).isHiddenByUser, isFalse);
  });
}
