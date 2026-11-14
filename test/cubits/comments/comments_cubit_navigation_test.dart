import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
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

const int _storyId = 100;

Comment _comment(int id, {int? parent}) => Comment.fromJson(<String, dynamic>{
  'id': id,
  'parent': parent ?? _storyId,
  'by': 'someone',
  'text': 'Comment $id',
}).copyWith(level: parent == null ? 0 : 1);

void main() {
  late CommentsCubit cubit;
  late StreamController<AppLifecycleState> lifecycle;

  setUp(() {
    locator.registerSingleton<Logger>(MockLogger());
    lifecycle = StreamController<AppLifecycleState>.broadcast();
    final _MockFilterCubit filterCubit = _MockFilterCubit();
    when(() => filterCubit.state).thenReturn(FilterState.init());
    final _MockPreferenceCubit preferenceCubit = _MockPreferenceCubit();
    when(() => preferenceCubit.state).thenReturn(PreferenceState.init());
    final _MockAppLifecycleService appLifecycle = _MockAppLifecycleService();
    when(() => appLifecycle.stream).thenAnswer((_) => lifecycle.stream);
    final _MockCollapseStateCacheRepository collapseStates =
        _MockCollapseStateCacheRepository();
    when(
      () => collapseStates.saveStoryStates(any(), any()),
    ).thenAnswer((_) async {});

    cubit = CommentsCubit(
      filterCubit: filterCubit,
      preferenceCubit: preferenceCubit,
      isOfflineReading: false,
      item: Story.fromJson(const <String, dynamic>{
        'id': _storyId,
        'title': 'A thread',
        'by': 'author',
      }),
      defaultFetchMode: FetchMode.eager,
      defaultCommentsOrder: CommentsOrder.natural,
      commentCache: CommentCache(),
      offlineRepository: _MockOfflineRepository(),
      hackerNewsRepository: MockHackerNewsRepository(),
      hackerNewsWebRepository: _MockHackerNewsWebRepository(),
      collapseStateCacheRepository: collapseStates,
      appLifecycleService: appLifecycle,
    );
    cubit.emit(
      cubit.state.copyWith(
        comments: <Comment>[
          _comment(1),
          _comment(2, parent: 1),
          _comment(3),
          _comment(4, parent: 3),
          _comment(5),
          _comment(6, parent: 5),
          _comment(7),
        ],
        status: CommentsStatus.allLoaded,
      ),
    );
  });

  tearDown(() async {
    await cubit.close();
    await lifecycle.close();
    await locator.reset();
  });

  Future<void> pumpThread(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScrollablePositionedList.builder(
            itemScrollController: cubit.itemScrollController,
            itemPositionsListener: cubit.itemPositionsListener,
            itemCount: cubit.state.comments.length + 2,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) return const SizedBox(height: 100);
              if (index > cubit.state.comments.length) {
                return const SizedBox(height: 600);
              }
              final Comment comment = cubit.state.comments[index - 1];
              return SizedBox(
                height: comment.isRoot ? 240 : 40,
                child: Text(comment.text),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settleScroll(WidgetTester tester) async {
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
  }

  void expectPosition(int index, double alignment) {
    final List<ItemPosition> positions = cubit
        .itemPositionsListener
        .itemPositions
        .value
        .where((ItemPosition item) => item.index == index)
        .toList();
    expect(
      positions,
      hasLength(1),
      reason: 'List item $index should be visible',
    );
    expect(positions.single.itemLeadingEdge, closeTo(alignment, 0.01));
  }

  testWidgets('Back returns one prior position per root skip', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    expectPosition(3, 0.15);

    cubit.scrollToNextRoot();
    await settleScroll(tester);
    expectPosition(5, 0.15);

    cubit.navigateBack();
    await settleScroll(tester);
    expectPosition(3, 0.15);

    cubit.navigateBack();
    await settleScroll(tester);
    expectPosition(0, 0);

    cubit.navigateForward();
    await settleScroll(tester);
    expectPosition(3, 0.15);
    cubit.navigateForward();
    await settleScroll(tester);
    expectPosition(5, 0.15);
  });

  testWidgets('Back and Forward retrace previous-root skips once per stop', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.itemScrollController.jumpTo(index: 7, alignment: 0.15);
    await settleScroll(tester);

    cubit.scrollToPreviousRoot();
    await settleScroll(tester);
    expectPosition(5, 0.15);
    cubit.scrollToPreviousRoot();
    await settleScroll(tester);
    expectPosition(3, 0.15);

    cubit.navigateBack();
    await settleScroll(tester);
    expectPosition(5, 0.15);
    cubit.navigateBack();
    await settleScroll(tester);
    expectPosition(7, 0.15);

    cubit.navigateForward();
    await settleScroll(tester);
    expectPosition(5, 0.15);
    cubit.navigateForward();
    await settleScroll(tester);
    expectPosition(3, 0.15);
  });
}
