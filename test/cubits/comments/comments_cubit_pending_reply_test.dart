import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/services/services.dart';
import 'package:logger/logger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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

const String _me = 'me';
const int _storyId = 100;

Story _story({List<int> kids = const <int>[1, 3]}) => Story(
  descendants: 3,
  id: _storyId,
  score: 1,
  time: 0,
  by: 'op',
  title: 'A story',
  type: 'story',
  url: '',
  text: '',
  kids: kids,
  parts: const <int>[],
  hidden: false,
);

Comment _comment(
  int id, {
  required int parent,
  int level = 0,
  String by = 'someone',
  String text = 'text',
  List<int> kids = const <int>[],
  bool isCollapsedByUser = false,
  bool isHiddenByUser = false,
}) => Comment(
  id: id,
  time: 0,
  parent: parent,
  score: 0,
  by: by,
  text: text,
  kids: kids,
  dead: false,
  deleted: false,
  hidden: false,
  level: level,
  isFromCache: false,
  isCollapsedByUser: isCollapsedByUser,
  isHiddenByUser: isHiddenByUser,
);

/// A thread shaped like:
///
/// 1
///   2
/// 3
List<Comment> _thread() => <Comment>[
  _comment(1, parent: _storyId, kids: const <int>[2]),
  _comment(2, parent: 1, level: 1),
  _comment(3, parent: _storyId),
];

Future<void> _waitFor(bool Function() condition) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  while (!condition()) {
    if (stopwatch.elapsed > const Duration(seconds: 5)) {
      fail('condition was not met in time');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  // Scrolling to a new reply looks up its widget, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHackerNewsRepository hackerNewsRepository;
  late _MockCollapseStateCacheRepository collapseStateCacheRepository;
  late CommentCache commentCache;
  late StreamController<AppLifecycleState> appLifecycleStates;
  late CommentsCubit cubit;

  CommentsCubit buildCubit({
    List<Comment>? comments,
    CommentsOrder order = CommentsOrder.natural,
    FetchMode fetchMode = FetchMode.eager,
  }) {
    final _MockFilterCubit filterCubit = _MockFilterCubit();
    when(() => filterCubit.state).thenReturn(FilterState.init());
    final _MockPreferenceCubit preferenceCubit = _MockPreferenceCubit();
    when(() => preferenceCubit.state).thenReturn(PreferenceState.init());
    final _MockAppLifecycleService appLifecycleService =
        _MockAppLifecycleService();
    when(
      () => appLifecycleService.stream,
    ).thenAnswer((_) => appLifecycleStates.stream);

    final CommentsCubit cubit = CommentsCubit(
      filterCubit: filterCubit,
      preferenceCubit: preferenceCubit,
      isOfflineReading: false,
      item: _story(),
      defaultFetchMode: fetchMode,
      defaultCommentsOrder: order,
      commentCache: commentCache,
      offlineRepository: _MockOfflineRepository(),
      hackerNewsRepository: hackerNewsRepository,
      hackerNewsWebRepository: _MockHackerNewsWebRepository(),
      collapseStateCacheRepository: collapseStateCacheRepository,
      appLifecycleService: appLifecycleService,
    );
    return cubit..emit(
      cubit.state.copyWith(
        comments: comments ?? _thread(),
        status: CommentsStatus.allLoaded,
      ),
    );
  }

  List<int> ids() => cubit.state.comments.map((Comment c) => c.id).toList();

  Comment pendingReply() =>
      cubit.state.comments.singleWhere((Comment c) => c.isPending);

  Widget threadList({ValueChanged<int>? onTap}) {
    // Match MainView's header, footer and per-comment global keys. These
    // keys must remain unique while a reply is inserted and revealed.
    for (final Comment comment in cubit.state.comments) {
      cubit.globalKeys[comment.id] = GlobalKey();
    }

    return MaterialApp(
      home: Scaffold(
        body: BlocBuilder<CommentsCubit, CommentsState>(
          bloc: cubit,
          builder: (BuildContext context, CommentsState state) {
            return ScrollablePositionedList.builder(
              itemScrollController: cubit.itemScrollController,
              itemPositionsListener: cubit.itemPositionsListener,
              itemCount: state.comments.length + 2,
              minCacheExtent: 1200,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) return const SizedBox(height: 100);
                if (index == state.comments.length + 1) {
                  return const SizedBox(height: 600);
                }

                final Comment comment = state.comments[index - 1];
                if (comment.isHiddenByUser) {
                  return SizedBox.shrink(key: cubit.globalKeys[comment.id]);
                }
                return SizedBox(
                  key: cubit.globalKeys[comment.id],
                  height: 180,
                  child: InkWell(
                    key: ValueKey<String>('tap-${comment.id}'),
                    onTap: () => onTap?.call(comment.id),
                    child: Center(child: Text(comment.text)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  ItemPosition replyPosition(Comment reply) {
    final int listIndex = cubit.state.comments.indexOf(reply) + 1;
    return cubit.itemPositionsListener.itemPositions.value.singleWhere(
      (ItemPosition position) => position.index == listIndex,
    );
  }

  Future<void> settleReplyReveal(WidgetTester tester) async {
    // Linkification runs outside the widget test's fake async zone. Flush
    // its continuations after each frame used to lay out and reveal the row.
    for (int frame = 0; frame < 3; frame++) {
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    await tester.pumpAndSettle();
  }

  setUp(() {
    if (locator.isRegistered<Logger>()) {
      locator.unregister<Logger>();
    }
    locator.registerSingleton<Logger>(MockLogger());

    hackerNewsRepository = MockHackerNewsRepository();
    collapseStateCacheRepository = _MockCollapseStateCacheRepository();
    commentCache = CommentCache();
    appLifecycleStates = StreamController<AppLifecycleState>.broadcast();

    when(
      () => collapseStateCacheRepository.cachedItemIdToPreviousStates,
    ).thenReturn(<int, Map<int, Comment>>{});
    when(
      () => collapseStateCacheRepository.saveStoryStates(any(), any()),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await cubit.close();
    await appLifecycleStates.close();
  });

  group('CommentsCubit.addPendingReply', () {
    test('shows the reply directly under the comment replied to', () async {
      cubit = buildCubit();

      await cubit.addPendingReply(parentId: 1, text: 'hello', author: _me);

      final Comment reply = pendingReply();
      expect(ids(), <int>[1, reply.id, 2, 3]);
      expect(reply.parent, 1);
      expect(reply.level, 1);
      expect(reply.by, _me);
      expect(reply.text, 'hello');
      expect(reply, isA<BuildableComment>());
    });

    test('shows a reply to the story at the top of the thread', () async {
      cubit = buildCubit();

      await cubit.addPendingReply(
        parentId: _storyId,
        text: 'hello',
        author: _me,
      );

      final Comment reply = pendingReply();
      expect(ids(), <int>[reply.id, 1, 2, 3]);
      expect(reply.level, 0);
    });

    test('puts the reply last among its siblings when sorted oldest '
        'first', () async {
      cubit = buildCubit(order: CommentsOrder.oldestFirst);

      await cubit.addPendingReply(parentId: 1, text: 'hello', author: _me);
      expect(ids(), <int>[1, 2, pendingReply().id, 3]);

      await cubit.close();
      cubit = buildCubit(order: CommentsOrder.oldestFirst);

      await cubit.addPendingReply(
        parentId: _storyId,
        text: 'hello',
        author: _me,
      );
      expect(ids(), <int>[1, 2, 3, pendingReply().id]);
    });

    test('ignores a reply to something that is not in this thread', () async {
      cubit = buildCubit();

      await cubit.addPendingReply(parentId: 999, text: 'hello', author: _me);

      expect(ids(), <int>[1, 2, 3]);
    });

    test('uncollapses the comment replied to', () async {
      cubit = buildCubit(
        comments: <Comment>[
          _comment(
            1,
            parent: _storyId,
            kids: const <int>[2],
            isCollapsedByUser: true,
          ),
          _comment(2, parent: 1, level: 1, isHiddenByUser: true),
          _comment(3, parent: _storyId),
        ],
      );

      await cubit.addPendingReply(parentId: 1, text: 'hello', author: _me);

      expect(cubit.state.comments.first.isCollapsedByUser, isFalse);
      expect(pendingReply().isHiddenByUser, isFalse);
    });

    test('gives every placeholder its own id', () async {
      cubit = buildCubit();

      await cubit.addPendingReply(parentId: 1, text: 'one', author: _me);
      await cubit.addPendingReply(parentId: 3, text: 'two', author: _me);

      final List<Comment> pending = cubit.state.comments
          .where((Comment c) => c.isPending)
          .toList();
      expect(pending, hasLength(2));
      expect(pending.first.id, isNot(pending.last.id));
    });
  });

  group('reloading the thread with a pending reply', () {
    test('replaces the placeholder with what Hacker News returns', () async {
      when(
        () => hackerNewsRepository.fetchItem(id: _storyId),
      ).thenAnswer((_) async => _story());
      when(
        () => hackerNewsRepository.fetchCommentsStream(
          ids: any(named: 'ids'),
          getFromCache: any(named: 'getFromCache'),
        ),
      ).thenAnswer(
        (_) => Stream<Comment>.fromIterable(<Comment>[
          _comment(50, parent: _storyId, by: _me),
          _comment(1, parent: _storyId),
          _comment(3, parent: _storyId),
        ]),
      );
      cubit = buildCubit(fetchMode: FetchMode.lazy);
      await cubit.addPendingReply(
        parentId: _storyId,
        text: 'hello',
        author: _me,
      );

      await cubit.init();
      await _waitFor(() => cubit.state.status == CommentsStatus.allLoaded);

      expect(ids(), <int>[50, 1, 3]);
    });
  });

  group('revealing a reply in a rendered thread', () {
    testWidgets('reveals a nested reply and keeps the thread interactive', (
      WidgetTester tester,
    ) async {
      cubit = buildCubit();
      int? tappedId;
      await tester.pumpWidget(threadList(onTap: (int id) => tappedId = id));
      await tester.pumpAndSettle();

      await tester.runAsync(
        () => cubit.addPendingReply(parentId: 2, text: 'hello', author: _me),
      );
      await settleReplyReveal(tester);

      final Comment reply = pendingReply();
      expect(replyPosition(reply).itemLeadingEdge, closeTo(0.15, 0.01));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey<String>('tap-3')));
      await tester.pumpAndSettle();
      expect(tappedId, 3);

      await tester.drag(
        find.byType(ScrollablePositionedList),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      expect(replyPosition(reply).itemLeadingEdge, lessThan(0.15));
      expect(tester.takeException(), isNull);
    });

    testWidgets('expands collapsed ancestors before revealing a nested reply', (
      WidgetTester tester,
    ) async {
      cubit = buildCubit(
        comments: <Comment>[
          _comment(
            1,
            parent: _storyId,
            kids: const <int>[2],
            isCollapsedByUser: true,
          ),
          _comment(
            2,
            parent: 1,
            level: 1,
            kids: const <int>[3],
            isCollapsedByUser: true,
            isHiddenByUser: true,
          ),
          _comment(3, parent: 2, level: 2, isHiddenByUser: true),
          _comment(4, parent: _storyId),
        ],
      );
      int? tappedId;
      await tester.pumpWidget(threadList(onTap: (int id) => tappedId = id));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('tap-3')), findsNothing);

      await tester.runAsync(
        () => cubit.addPendingReply(parentId: 3, text: 'hello', author: _me),
      );
      await settleReplyReveal(tester);

      final Comment reply = pendingReply();
      expect(reply.isHiddenByUser, isFalse);
      expect(
        cubit.state.comments.any((Comment c) => c.isCollapsedByUser),
        isFalse,
      );
      expect(replyPosition(reply).itemLeadingEdge, closeTo(0.15, 0.01));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey<String>('tap-4')));
      await tester.pumpAndSettle();
      expect(tappedId, 4);
      expect(tester.takeException(), isNull);
    });

    for (final int lastChildId in <int>[6, 12, 40]) {
      testWidgets('reveals an offscreen reply after child $lastChildId '
          'when sorted oldest first', (WidgetTester tester) async {
        cubit = buildCubit(
          order: CommentsOrder.oldestFirst,
          comments: <Comment>[
            _comment(1, parent: _storyId),
            for (int id = 2; id <= lastChildId; id++)
              _comment(id, parent: 1, level: 1),
            _comment(lastChildId + 1, parent: _storyId),
          ],
        );
        int? tappedId;
        await tester.pumpWidget(threadList(onTap: (int id) => tappedId = id));
        await tester.pumpAndSettle();
        expect(
          cubit.itemPositionsListener.itemPositions.value.any(
            (ItemPosition position) => position.index == lastChildId,
          ),
          isFalse,
        );

        await tester.runAsync(
          () => cubit.addPendingReply(parentId: 1, text: 'hello', author: _me),
        );
        await settleReplyReveal(tester);

        final Comment reply = pendingReply();
        expect(tester.takeException(), isNull);
        expect(replyPosition(reply).itemLeadingEdge, closeTo(0.15, 0.01));

        await tester.tap(
          find.byKey(ValueKey<String>('tap-${lastChildId + 1}')),
        );
        await tester.pumpAndSettle();
        expect(tappedId, lastChildId + 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('stops revealing a reply removed before the next frame', (
      WidgetTester tester,
    ) async {
      cubit = buildCubit();
      await tester.pumpWidget(threadList());
      await tester.pumpAndSettle();

      await tester.runAsync(
        () => cubit.addPendingReply(parentId: 1, text: 'hello', author: _me),
      );
      cubit.emit(cubit.state.copyWith(comments: _thread()));
      await settleReplyReveal(tester);

      expect(cubit.state.comments.any((Comment c) => c.isPending), isFalse);
      expect(cubit.state.navigationStack, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group('saving collapse states', () {
    test('leaves pending replies out when the app goes to the '
        'background', () async {
      cubit = buildCubit();
      await cubit.addPendingReply(parentId: 1, text: 'hello', author: _me);

      appLifecycleStates.add(AppLifecycleState.inactive);
      await Future<void>.delayed(Duration.zero);

      final Map<int, Comment> savedStates =
          verify(
                () => collapseStateCacheRepository.saveStoryStates(
                  _storyId,
                  captureAny(),
                ),
              ).captured.last
              as Map<int, Comment>;
      expect(savedStates.keys, unorderedEquals(<int>[1, 2, 3]));
      expect(cubit.state.comments.any((Comment c) => c.isPending), isTrue);
    });
  });

  group('closing the cubit', () {
    test('purges pending replies', () async {
      cubit = buildCubit();
      await cubit.addPendingReply(parentId: 1, text: 'hello', author: _me);
      final int placeholderId = pendingReply().id;

      await cubit.close();

      expect(ids(), <int>[1, 2, 3]);
      expect(cubit.globalKeys.containsKey(placeholderId), isFalse);
      expect(commentCache.getComment(placeholderId), isNull);

      // Nothing about the placeholder is saved with the collapse states.
      final Map<int, Comment> savedStates =
          verify(
                () => collapseStateCacheRepository.saveStoryStates(
                  _storyId,
                  captureAny(),
                ),
              ).captured.last
              as Map<int, Comment>;
      expect(savedStates.keys, unorderedEquals(<int>[1, 2, 3]));

      // Posting never goes looking for the real comment on Hacker News.
      verifyZeroInteractions(hackerNewsRepository);
    });
  });

  group('CommentsCubit.updateCommentText', () {
    test('shows the edited text and keeps the collapse state', () async {
      cubit = buildCubit(
        comments: <Comment>[
          _comment(
            1,
            parent: _storyId,
            by: _me,
            text: 'before',
            isCollapsedByUser: true,
          ),
          _comment(3, parent: _storyId),
        ],
      );

      await cubit.updateCommentText(id: 1, text: 'after');

      final Comment edited = cubit.state.comments.first;
      expect(ids(), <int>[1, 3]);
      expect(edited.text, 'after');
      expect(edited.isCollapsedByUser, isTrue);
      expect(edited, isA<BuildableComment>());
    });

    test('ignores a comment that is not in this thread', () async {
      cubit = buildCubit();

      await cubit.updateCommentText(id: 999, text: 'after');

      expect(ids(), <int>[1, 2, 3]);
    });
  });
}
