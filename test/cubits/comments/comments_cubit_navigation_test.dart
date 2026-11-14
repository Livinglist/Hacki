import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/item/widgets/widgets.dart';
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

class _MockThreadNavigationButtonCubit
    extends MockCubit<ThreadNavigationButtonState>
    implements ThreadNavigationButtonCubit {}

const int _storyId = 100;

Comment _comment(int id, {int? parent}) => Comment.fromJson(<String, dynamic>{
  'id': id,
  'parent': parent ?? _storyId,
  'by': 'someone',
  'text': 'Comment $id',
}).copyWith(level: parent == null ? 0 : 1);

void main() {
  late CommentsCubit cubit;
  late _MockPreferenceCubit preferenceCubit;
  late _MockThreadNavigationButtonCubit buttonCubit;
  late StreamController<AppLifecycleState> lifecycle;

  setUp(() {
    locator.registerSingleton<Logger>(MockLogger());
    lifecycle = StreamController<AppLifecycleState>.broadcast();
    final _MockFilterCubit filterCubit = _MockFilterCubit();
    when(() => filterCubit.state).thenReturn(FilterState.init());
    preferenceCubit = _MockPreferenceCubit();
    when(() => preferenceCubit.state).thenReturn(PreferenceState.init());
    buttonCubit = _MockThreadNavigationButtonCubit();
    when(
      () => buttonCubit.state,
    ).thenReturn(ThreadNavigationButtonState.init());
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
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<CommentsCubit>.value(value: cubit),
          BlocProvider<PreferenceCubit>.value(value: preferenceCubit),
          BlocProvider<ThreadNavigationButtonCubit>.value(value: buttonCubit),
        ],
        child: FeatureDiscovery(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: <Widget>[
                  NotificationListener<ScrollNotification>(
                    onNotification: cubit.onThreadScrollNotification,
                    child: ScrollablePositionedList.builder(
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
                  const FloatingSkipButtons(),
                  const FloatingHistoryButtons(),
                ],
              ),
            ),
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

  double alignmentOf(int index) => cubit
      .itemPositionsListener
      .itemPositions
      .value
      .singleWhere((ItemPosition position) => position.index == index)
      .itemLeadingEdge;

  for (final bool jumpToTop in <bool>[true, false]) {
    testWidgets('Back and Forward retrace a long-press jump to the '
        '${jumpToTop ? 'top' : 'bottom'}', (WidgetTester tester) async {
      await pumpThread(tester);
      cubit.itemScrollController.jumpTo(index: 3, alignment: -0.1);
      await settleScroll(tester);
      expectPosition(3, -0.1);

      await tester.longPress(
        find.byIcon(
          jumpToTop ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        ),
      );
      await settleScroll(tester);
      final int destination = jumpToTop ? 0 : cubit.state.comments.length;
      final int destinationId = jumpToTop ? _storyId : 7;
      expectPosition(destination, 0);
      expect(
        cubit.state.navigationStack.map(
          (NavigationAnchor anchor) => anchor.itemId,
        ),
        <int>[3, destinationId],
      );
      expect(cubit.state.navigationStack.first.alignment, closeTo(-0.1, 0.01));
      expect(cubit.state.navigationStack.last.alignment, 0);

      await tester.tap(find.byIcon(Icons.turn_left));
      await settleScroll(tester);
      expectPosition(3, -0.1);
      expect(cubit.state.canNavigateBack, isFalse);

      await tester.tap(find.byIcon(Icons.turn_right));
      await settleScroll(tester);
      expectPosition(destination, 0);
      expect(cubit.state.canNavigateForward, isFalse);
      expect(cubit.state.navigationStack, hasLength(2));
    });
  }

  for (final bool jumpToTop in <bool>[true, false]) {
    testWidgets('a long-press jump to the ${jumpToTop ? 'top' : 'bottom'} '
        'after Back clears forward history', (WidgetTester tester) async {
      await pumpThread(tester);
      cubit.scrollToNextRoot();
      await settleScroll(tester);
      cubit.scrollToNextRoot();
      await settleScroll(tester);
      await tester.tap(find.byIcon(Icons.turn_left));
      await settleScroll(tester);

      await tester.longPress(
        find.byIcon(
          jumpToTop ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        ),
      );
      await settleScroll(tester);
      final int destination = jumpToTop ? 0 : cubit.state.comments.length;
      final int destinationId = jumpToTop ? _storyId : 7;
      expectPosition(destination, 0);
      expect(
        cubit.state.navigationStack.map(
          (NavigationAnchor anchor) => anchor.itemId,
        ),
        // The short reply above root 3 anchors the same reading position.
        <int>[_storyId, 2, destinationId],
      );
      expect(cubit.state.canNavigateForward, isFalse);

      await tester.tap(find.byIcon(Icons.turn_left));
      await settleScroll(tester);
      expectPosition(3, 0.15);
      await tester.tap(find.byIcon(Icons.turn_left));
      await settleScroll(tester);
      expectPosition(0, 0);

      await tester.tap(find.byIcon(Icons.turn_right));
      await settleScroll(tester);
      expectPosition(3, 0.15);
      await tester.tap(find.byIcon(Icons.turn_right));
      await settleScroll(tester);
      expectPosition(destination, 0);
      expect(cubit.state.canNavigateForward, isFalse);
      expect(cubit.state.navigationStack, hasLength(3));
    });
  }

  testWidgets('a search-result jump after Back clears forward history', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.navigateBack();
    await settleScroll(tester);

    // Search results use scrollToComment to jump within the existing thread.
    final Future<void> jump = cubit.scrollToComment(cubit.state.comments.last);
    await settleScroll(tester);
    await jump;
    expect(
      cubit.state.navigationStack.map(
        (NavigationAnchor anchor) => anchor.itemId,
      ),
      <int>[_storyId, 2, 7],
    );
    expect(cubit.state.canNavigateForward, isFalse);

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
    expectPosition(7, 0.15);
    expect(cubit.state.canNavigateForward, isFalse);
    expect(cubit.state.navigationStack, hasLength(3));
  });

  testWidgets('repeating the next root skip after Back replaces its future', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.navigateBack();
    await settleScroll(tester);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await settleScroll(tester);
    expectPosition(5, 0.15);
    expect(cubit.state.navigationStack, hasLength(3));
    expect(cubit.state.canNavigateForward, isFalse);

    cubit.navigateBack();
    await settleScroll(tester);
    expectPosition(3, 0.15);
  });

  for (final bool skipUp in <bool>[true, false]) {
    testWidgets(
      'tapping skip ${skipUp ? 'up' : 'down'} clears forward history',
      (WidgetTester tester) async {
        await pumpThread(tester);
        for (int i = 0; i < 3; i++) {
          cubit.scrollToNextRoot();
          await settleScroll(tester);
        }
        cubit.navigateBack();
        await settleScroll(tester);
        if (!skipUp) {
          cubit.navigateBack();
          await settleScroll(tester);
        }
        final int origin = skipUp ? 5 : 3;
        expectPosition(origin, 0.15);
        expect(cubit.state.canNavigateForward, isTrue);

        await tester.tap(
          find.byIcon(
            skipUp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          ),
        );
        await settleScroll(tester);
        final int destination = skipUp ? 3 : 5;
        expectPosition(destination, 0.15);
        expect(cubit.state.canNavigateForward, isFalse);
        expect(cubit.state.navigationStack, hasLength(skipUp ? 4 : 3));

        cubit.navigateBack();
        await settleScroll(tester);
        expectPosition(origin, 0.15);
        cubit.navigateForward();
        await settleScroll(tester);
        expectPosition(destination, 0.15);
        expect(cubit.state.canNavigateForward, isFalse);
      },
    );
  }

  testWidgets('long pressing at the current endpoint clears forward history', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    await tester.longPress(find.byIcon(Icons.keyboard_arrow_down));
    await settleScroll(tester);
    cubit.navigateBack();
    await settleScroll(tester);
    expect(cubit.state.canNavigateForward, isTrue);

    await tester.longPress(find.byIcon(Icons.keyboard_arrow_up));
    await settleScroll(tester);
    expectPosition(0, 0);
    expect(cubit.state.navigationStack, hasLength(1));
    expect(cubit.state.canNavigateForward, isFalse);
  });

  for (final bool arriveWithForward in <bool>[false, true]) {
    for (final double dragDy in <double>[-90, 90]) {
      testWidgets(
        'Back returns to the ${arriveWithForward ? 'Forward' : 'Back'} '
        'landing before older history after scrolling '
        '${dragDy < 0 ? 'down' : 'up'}',
        (WidgetTester tester) async {
          await pumpThread(tester);
          cubit.scrollToNextRoot();
          await settleScroll(tester);
          cubit.scrollToNextRoot();
          await settleScroll(tester);
          cubit.navigateBack();
          await settleScroll(tester);
          if (arriveWithForward) {
            cubit.navigateBack();
            await settleScroll(tester);
            cubit.navigateForward();
            await settleScroll(tester);
          }
          expectPosition(3, 0.15);
          expect(cubit.state.hasScrolledFromNavigation, isFalse);

          await tester.drag(
            find.byType(ScrollablePositionedList),
            Offset(0, dragDy),
          );
          await settleScroll(tester);
          final double scrolledAlignment = alignmentOf(3);
          expect(scrolledAlignment, isNot(closeTo(0.15, 0.01)));
          expect(cubit.state.hasScrolledFromNavigation, isTrue);
          expect(cubit.state.navigationStack, hasLength(3));

          await tester.tap(find.byIcon(Icons.turn_left));
          await settleScroll(tester);
          expectPosition(3, 0.15);
          expect(cubit.state.navigationIndex, 1);
          expect(cubit.state.navigationStack, hasLength(4));
          expect(cubit.state.hasScrolledFromNavigation, isFalse);

          await tester.tap(find.byIcon(Icons.turn_left));
          await settleScroll(tester);
          expectPosition(0, 0);
          await tester.tap(find.byIcon(Icons.turn_right));
          await settleScroll(tester);
          expectPosition(3, 0.15);
          await tester.tap(find.byIcon(Icons.turn_right));
          await settleScroll(tester);
          expectPosition(3, scrolledAlignment);
          await tester.tap(find.byIcon(Icons.turn_right));
          await settleScroll(tester);
          expectPosition(5, 0.15);
          expect(cubit.state.navigationStack, hasLength(4));
        },
      );
    }
  }

  testWidgets('scrolling away from the earliest stop enables Back to it', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.navigateBack();
    await settleScroll(tester);
    expect(cubit.state.navigationIndex, 0);
    expect(cubit.state.canNavigateBack, isFalse);

    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -80),
    );
    await settleScroll(tester);
    final double scrolledAlignment = alignmentOf(0);
    expect(cubit.state.canNavigateBack, isTrue);

    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(0, 0);
    expect(cubit.state.navigationIndex, 0);
    expect(cubit.state.canNavigateBack, isFalse);
    expect(cubit.state.navigationStack, hasLength(3));
    cubit.navigateForward();
    await settleScroll(tester);
    expectPosition(0, scrolledAlignment);
    cubit.navigateForward();
    await settleScroll(tester);
    expectPosition(3, 0.15);
  });

  testWidgets('Back preserves different offsets within the same comment', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    unawaited(
      cubit.scrollTo(index: 7, alignment: 0.15, recordNavigation: true),
    );
    await settleScroll(tester);
    cubit.navigateBack();
    await settleScroll(tester);
    cubit.navigateForward();
    await settleScroll(tester);

    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -90),
    );
    await settleScroll(tester);
    final double scrolledAlignment = alignmentOf(7);
    expect(cubit.state.hasScrolledFromNavigation, isTrue);
    cubit.navigateBack();
    await settleScroll(tester);
    expectPosition(7, 0.15);
    expect(cubit.state.navigationStack, hasLength(3));
    expect(cubit.state.navigationStack[1].itemId, 7);
    expect(cubit.state.navigationStack[2].itemId, 7);
    cubit.navigateForward();
    await settleScroll(tester);
    expectPosition(7, scrolledAlignment);
  });

  testWidgets('manually returning to the landing adds no history stop', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -90),
    );
    await settleScroll(tester);
    expect(cubit.state.hasScrolledFromNavigation, isTrue);
    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, 90),
    );
    await settleScroll(tester);
    expectPosition(3, 0.15);
    expect(cubit.state.hasScrolledFromNavigation, isFalse);

    cubit.navigateBack();
    await settleScroll(tester);
    expectPosition(0, 0);
    expect(cubit.state.navigationStack, hasLength(2));
  });

  testWidgets('a new jump after manual scrolling retains its landing', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.navigateBack();
    await settleScroll(tester);
    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -90),
    );
    await settleScroll(tester);
    final double scrolledAlignment = alignmentOf(3);

    await tester.longPress(find.byIcon(Icons.keyboard_arrow_down));
    await settleScroll(tester);
    expectPosition(7, 0);
    expect(cubit.state.navigationStack, hasLength(4));
    expect(cubit.state.navigationStack.last.itemId, 7);
    expect(cubit.state.canNavigateForward, isFalse);
    cubit.navigateBack();
    await settleScroll(tester);
    expectPosition(3, scrolledAlignment);
    cubit.navigateBack();
    await settleScroll(tester);
    expectPosition(3, 0.15);
    cubit.navigateBack();
    await settleScroll(tester);
    expectPosition(0, 0);
  });

  testWidgets(
    'Forward retains the landing and manual position before its tail',
    (WidgetTester tester) async {
      await pumpThread(tester);
      cubit.scrollToNextRoot();
      await settleScroll(tester);
      cubit.scrollToNextRoot();
      await settleScroll(tester);
      cubit.navigateBack();
      await settleScroll(tester);
      await tester.drag(
        find.byType(ScrollablePositionedList),
        const Offset(0, -90),
      );
      await settleScroll(tester);
      final double scrolledAlignment = alignmentOf(3);

      await tester.tap(find.byIcon(Icons.turn_right));
      await settleScroll(tester);
      expectPosition(5, 0.15);
      expect(cubit.state.navigationStack, hasLength(4));
      expect(cubit.state.hasScrolledFromNavigation, isFalse);
      await tester.tap(find.byIcon(Icons.turn_left));
      await settleScroll(tester);
      expectPosition(3, scrolledAlignment);
      await tester.tap(find.byIcon(Icons.turn_left));
      await settleScroll(tester);
      expectPosition(3, 0.15);
      await tester.tap(find.byIcon(Icons.turn_left));
      await settleScroll(tester);
      expectPosition(0, 0);
    },
  );

  testWidgets('Back returns to the landing after mouse wheel scrolling', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(find.byType(ScrollablePositionedList)),
        scrollDelta: const Offset(0, 90),
      ),
    );
    await settleScroll(tester);
    final double scrolledAlignment = alignmentOf(3);
    expect(scrolledAlignment, isNot(closeTo(0.15, 0.01)));
    expect(cubit.state.hasScrolledFromNavigation, isTrue);

    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(3, 0.15);
    expect(cubit.state.navigationStack, hasLength(3));
    await tester.tap(find.byIcon(Icons.turn_right));
    await settleScroll(tester);
    expectPosition(3, scrolledAlignment);
  });

  testWidgets('ordinary scrolling does not record navigation', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    unawaited(cubit.scrollTo(index: 3));
    await settleScroll(tester);
    expectPosition(3, 0);
    expect(cubit.state.navigationStack, isEmpty);
  });

  testWidgets('jumping to the current endpoint does not add history', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    await tester.longPress(find.byIcon(Icons.keyboard_arrow_up));
    await settleScroll(tester);
    expectPosition(0, 0);
    expect(cubit.state.navigationStack, isEmpty);
  });

  test('an unattached scroll does not record navigation', () async {
    await cubit.scrollTo(index: 0, recordNavigation: true);
    expect(cubit.state.navigationStack, isEmpty);
  });

  for (final bool forward in <bool>[false, true]) {
    testWidgets(
      '${forward ? 'Forward' : 'Back'} skips stops for the same viewport',
      (WidgetTester tester) async {
        await pumpThread(tester);
        cubit.itemScrollController.jumpTo(index: 3, alignment: 0.15);
        await settleScroll(tester);
        final NavigationAnchor replyAnchor = NavigationAnchor(
          itemId: 2,
          alignment: alignmentOf(2),
        );
        cubit.itemScrollController.jumpTo(
          index: forward ? 0 : 5,
          alignment: forward ? 0 : 0.15,
        );
        await settleScroll(tester);
        cubit.emit(
          cubit.state.copyWith(
            navigationStack: <NavigationAnchor>[
              const NavigationAnchor(itemId: _storyId, alignment: 0),
              replyAnchor,
              const NavigationAnchor(itemId: 3, alignment: 0.15),
              const NavigationAnchor(itemId: 5, alignment: 0.15),
            ],
            navigationIndex: forward ? 0 : 3,
          ),
        );
        await settleScroll(tester);
        final Finder button = find.byIcon(
          forward ? Icons.turn_right : Icons.turn_left,
        );

        await tester.tap(button);
        await settleScroll(tester);
        expectPosition(3, 0.15);
        await tester.tap(button);
        await settleScroll(tester);
        expectPosition(forward ? 5 : 0, forward ? 0.15 : 0);
        expect(cubit.state.navigationIndex, forward ? 3 : 0);
      },
    );

    testWidgets(
      '${forward ? 'Forward' : 'Back'} skips removed comments in one tap',
      (WidgetTester tester) async {
        await pumpThread(tester);
        cubit.itemScrollController.jumpTo(
          index: forward ? 0 : 5,
          alignment: forward ? 0 : 0.15,
        );
        await settleScroll(tester);
        cubit.emit(
          cubit.state.copyWith(
            navigationStack: const <NavigationAnchor>[
              NavigationAnchor(itemId: _storyId, alignment: 0),
              NavigationAnchor(itemId: 999, alignment: 0.15),
              NavigationAnchor(itemId: 5, alignment: 0.15),
            ],
            navigationIndex: forward ? 0 : 2,
          ),
        );
        await settleScroll(tester);

        await tester.tap(
          find.byIcon(forward ? Icons.turn_right : Icons.turn_left),
        );
        await settleScroll(tester);
        expectPosition(forward ? 5 : 0, forward ? 0.15 : 0);
        expect(cubit.state.navigationIndex, forward ? 1 : 0);
      },
    );
  }

  testWidgets('exhausting missing Back stops preserves the current landing', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    unawaited(
      cubit.scrollTo(index: 5, alignment: 0.15, recordNavigation: true),
    );
    await settleScroll(tester);
    cubit.emit(
      cubit.state.copyWith(
        navigationStack: const <NavigationAnchor>[
          NavigationAnchor(itemId: 999, alignment: 0.15),
          NavigationAnchor(itemId: 5, alignment: 0.15),
        ],
        navigationIndex: 1,
      ),
    );
    unawaited(cubit.scrollTo(index: 5, alignment: 0.15));
    await settleScroll(tester);

    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(5, 0.15);
    expect(cubit.state.navigationStack, hasLength(1));
    expect(cubit.state.navigationStack.single.itemId, 5);
    expect(cubit.state.navigationIndex, 0);
    expect(cubit.state.canNavigateBack, isFalse);

    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -90),
    );
    await settleScroll(tester);
    expect(cubit.state.canNavigateBack, isTrue);
    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(5, 0.15);
    expect(cubit.state.navigationIndex, 0);
  });

  testWidgets(
    'exhausting missing Forward stops preserves the current landing',
    (WidgetTester tester) async {
      await pumpThread(tester);
      cubit.scrollToNextRoot();
      await settleScroll(tester);
      cubit.navigateBack();
      await settleScroll(tester);
      cubit.emit(
        cubit.state.copyWith(
          navigationStack: const <NavigationAnchor>[
            NavigationAnchor(itemId: _storyId, alignment: 0),
            NavigationAnchor(itemId: 999, alignment: 0.15),
          ],
          navigationIndex: 0,
        ),
      );
      unawaited(cubit.scrollTo(index: 0));
      await settleScroll(tester);

      await tester.tap(find.byIcon(Icons.turn_right));
      await settleScroll(tester);
      expectPosition(0, 0);
      expect(cubit.state.navigationStack, hasLength(1));
      expect(cubit.state.navigationStack.single.itemId, _storyId);
      expect(cubit.state.navigationIndex, 0);
      expect(cubit.state.canNavigateForward, isFalse);

      await tester.drag(
        find.byType(ScrollablePositionedList),
        const Offset(0, -80),
      );
      await settleScroll(tester);
      expect(cubit.state.canNavigateBack, isTrue);
      await tester.tap(find.byIcon(Icons.turn_left));
      await settleScroll(tester);
      expectPosition(0, 0);
      expect(cubit.state.navigationIndex, 0);
    },
  );

  testWidgets('Forward skips nearly identical offsets within a comment', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.emit(
      cubit.state.copyWith(
        navigationStack: const <NavigationAnchor>[
          NavigationAnchor(itemId: _storyId, alignment: 0),
          NavigationAnchor(itemId: 3, alignment: 0.15),
          NavigationAnchor(itemId: 3, alignment: 0.154),
          NavigationAnchor(itemId: 5, alignment: 0.15),
        ],
        navigationIndex: 0,
      ),
    );
    await settleScroll(tester);
    await tester.tap(find.byIcon(Icons.turn_right));
    await settleScroll(tester);
    expectPosition(3, 0.15);

    await tester.tap(find.byIcon(Icons.turn_right));
    await settleScroll(tester);
    expectPosition(5, 0.15);
    expect(cubit.state.navigationIndex, 3);
  });

  testWidgets('repeating a visible search target adds no duplicate stop', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.navigateBack();
    await settleScroll(tester);
    expectPosition(3, 0.15);
    expect(cubit.state.canNavigateForward, isTrue);

    final Future<void> jump = cubit.scrollToComment(cubit.state.comments[2]);
    await settleScroll(tester);
    await jump;
    expectPosition(3, 0.15);
    expect(cubit.state.navigationStack, hasLength(2));
    expect(cubit.state.canNavigateForward, isFalse);

    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(0, 0);
    await tester.tap(find.byIcon(Icons.turn_right));
    await settleScroll(tester);
    expectPosition(3, 0.15);
  });

  testWidgets('a same-comment endpoint jump preserves meaningful offsets', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    unawaited(
      cubit.scrollTo(index: 7, alignment: 0.15, recordNavigation: true),
    );
    await settleScroll(tester);
    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -150),
    );
    await settleScroll(tester);
    final double scrolledAlignment = alignmentOf(7);
    expect(scrolledAlignment.abs(), greaterThan(0.01));

    await tester.longPress(find.byIcon(Icons.keyboard_arrow_down));
    await settleScroll(tester);
    expectPosition(7, 0);
    expect(cubit.state.navigationStack, hasLength(4));

    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(7, scrolledAlignment);
    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(7, 0.15);
    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(0, 0);
  });

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
