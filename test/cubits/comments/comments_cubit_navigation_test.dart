import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/item/widgets/widgets.dart';
import 'package:hacki/screens/widgets/shine_overlay.dart';
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

/// Registers the navigation and comment-visibility tests and their fixtures.
///
/// Calling this entry point installs per-test setup and teardown hooks. Those
/// hooks register the test logger, create and seed a cubit with mocked
/// dependencies, and later close the cubit and fixture streams and reset the
/// service locator. Widget tests also mount thread fixtures and advance their
/// fake clocks to observe scrolling, layout changes, and rendered pixels.
void main() {
  late CommentsCubit cubit;
  late _MockPreferenceCubit preferenceCubit;
  late _MockThreadNavigationButtonCubit buttonCubit;
  late StreamController<AppLifecycleState> lifecycle;
  late StreamController<PreferenceState> preferenceChanges;
  late PreferenceState preferenceState;
  late CommentsCubit Function() createCubit;
  late Map<int, double> commentHeights;

  void seedComments() {
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
  }

  setUp(() {
    locator.registerSingleton<Logger>(MockLogger());
    lifecycle = StreamController<AppLifecycleState>.broadcast();
    preferenceChanges = StreamController<PreferenceState>.broadcast();
    preferenceState = PreferenceState.init();
    commentHeights = <int, double>{};
    final _MockFilterCubit filterCubit = _MockFilterCubit();
    when(() => filterCubit.state).thenReturn(FilterState.init());
    preferenceCubit = _MockPreferenceCubit();
    when(() => preferenceCubit.state).thenAnswer((_) => preferenceState);
    when(
      () => preferenceCubit.stream,
    ).thenAnswer((_) => preferenceChanges.stream);
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

    createCubit = () => CommentsCubit(
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
    cubit = createCubit();
    seedComments();
  });

  tearDown(() async {
    await cubit.close();
    await preferenceChanges.close();
    await lifecycle.close();
    await locator.reset();
  });

  void changePreference(Preference<dynamic> preference) {
    preferenceState = preferenceState.copyWithPreference(preference);
    preferenceChanges.add(preferenceState);
  }

  Future<void> startWithPreferences(
    WidgetTester tester,
    PreferenceState initial,
  ) => tester.runAsync(() async {
    await cubit.close();
    preferenceState = initial;
    cubit = createCubit();
    seedComments();
  });

  /// Mounts and settles the thread fixture using [tester].
  ///
  /// [tester] controls the widget tree, frames, and test binding. This helper
  /// changes its surface to 390 by 600 logical pixels and registers teardown
  /// that restores the binding's default surface size.
  ///
  /// [captureKey], when supplied, identifies a wrapping [RepaintBoundary] that
  /// pixel-comparison tests can capture later; mounting the fixture does not
  /// itself capture an image.
  ///
  /// [theme] overrides the default [MaterialApp] theme when supplied.
  ///
  /// [animateCollapse] uses [AnimatedCrossFade] with production timing.
  /// Its default false value makes comment-height changes immediate.
  ///
  /// Mounting provides the existing fixture cubits, attaches the list's scroll
  /// controller and position listener, and forwards scroll notifications to the
  /// comments cubit. It pumps frames until scheduled animations settle, which
  /// can rebuild widgets and update reported positions. Pending visibility
  /// timers require the additional clock advancement in [settleCollapse].
  Future<void> pumpThread(
    WidgetTester tester, {
    GlobalKey? captureKey,
    ThemeData? theme,
    bool animateCollapse = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Value providers leave cubit ownership with the per-test teardown hooks.
    final Widget app = MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<CommentsCubit>.value(value: cubit),
        BlocProvider<PreferenceCubit>.value(value: preferenceCubit),
        BlocProvider<ThreadNavigationButtonCubit>.value(value: buttonCubit),
      ],
      child: FeatureDiscovery(
        child: MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Stack(
              children: <Widget>[
                NotificationListener<ScrollNotification>(
                  onNotification: cubit.onThreadScrollNotification,
                  child: BlocBuilder<CommentsCubit, CommentsState>(
                    buildWhen:
                        (CommentsState previous, CommentsState current) =>
                            previous.comments != current.comments,
                    builder: (BuildContext context, CommentsState state) {
                      return ScrollablePositionedList.builder(
                        itemScrollController: cubit.itemScrollController,
                        itemPositionsListener: cubit.itemPositionsListener,
                        itemCount: state.comments.length + 2,
                        itemBuilder: (BuildContext context, int index) {
                          if (index == 0) return const SizedBox(height: 100);
                          if (index > state.comments.length) {
                            return const SizedBox(height: 600);
                          }
                          final Comment comment = state.comments[index - 1];
                          final GlobalKey? key = cubit.globalKeys[comment.id];
                          if (comment.isHiddenByUser) {
                            return SizedBox.shrink(key: key);
                          }
                          if (animateCollapse) {
                            // A long jump can build the same comment in both
                            // package lists. Local keys allow both copies while
                            // preserving each copy's animation identity.
                            return AnimatedCrossFade(
                              key: ValueKey<String>(
                                'animated-comment-${comment.id}',
                              ),
                              duration: CommentsCubit.collapseAnimationDuration,
                              crossFadeState: comment.isCollapsedByUser
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                              firstChild: const SizedBox(
                                height: 40,
                                width: double.infinity,
                              ),
                              secondChild: SizedBox(
                                height:
                                    commentHeights[comment.id] ??
                                    (comment.isRoot ? 240 : 40),
                                width: double.infinity,
                                child: Text(comment.text),
                              ),
                            );
                          }
                          return SizedBox(
                            key: key,
                            height: comment.isCollapsedByUser
                                ? 40
                                : commentHeights[comment.id] ??
                                      (comment.isRoot ? 240 : 40),
                            child: Text(comment.text),
                          );
                        },
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
    );
    await tester.pumpWidget(
      captureKey == null ? app : RepaintBoundary(key: captureKey, child: app),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settleScroll(WidgetTester tester) async {
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
  }

  Future<void> settleCommentJump(WidgetTester tester) async {
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
    }
  }

  Future<Uint8List> capturePixels(
    WidgetTester tester,
    GlobalKey captureKey,
  ) async {
    final RenderRepaintBoundary boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return (await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage();
      final ByteData bytes = (await image.toByteData())!;
      final Uint8List pixels = bytes.buffer.asUint8List();
      image.dispose();
      return pixels;
    }))!;
  }

  int changedPixels(
    Uint8List actual,
    Uint8List baseline,
    Rect region, {
    required int width,
    required int height,
  }) {
    final Rect clipped = region.intersect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    int changed = 0;
    for (int y = clipped.top.ceil(); y < clipped.bottom.floor(); y++) {
      for (int x = clipped.left.ceil(); x < clipped.right.floor(); x++) {
        final int offset = (y * width + x) * 4;
        int difference = 0;
        for (int channel = 0; channel < 3; channel++) {
          difference += (actual[offset + channel] - baseline[offset + channel])
              .abs();
        }
        if (difference > 12) changed++;
      }
    }
    return changed;
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

  /// Advances [tester] through a collapse or expansion and its scroll
  /// correction.
  ///
  /// [tester] supplies the fake clock and rendered frames. The initial pump
  /// builds the changed comment state, the timed pump advances the shared
  /// animation duration and any due visibility timer, and [settleScroll] drains
  /// the resulting frame callbacks, corrective scrolling, and list reanchoring.
  /// These pumps can rebuild the fixture and change its measured item
  /// positions.
  Future<void> settleCollapse(WidgetTester tester) async {
    // Start the animation and its post-frame timer before advancing time.
    await tester.pump();
    // A pending timer does not itself keep pumpAndSettle running.
    await tester.pump(CommentsCubit.collapseAnimationDuration);
    await settleScroll(tester);
  }

  for (final bool startsAboveViewport in <bool>[false, true]) {
    testWidgets('collapse restores a reverse-sliver tile initially '
        '${startsAboveViewport ? 'above' : 'inside'} the viewport', (
      WidgetTester tester,
    ) async {
      commentHeights[3] = 3000;
      await pumpThread(tester, animateCollapse: true);

      unawaited(cubit.scrollTo(index: 7, alignment: 0.15));
      await settleScroll(tester);
      // The jump leaves a later comment as the layout center. Manually moving
      // back puts this long comment in the reverse sliver, where shrinking it
      // moves its top down rather than leaving its top in place.
      final double viewportHeight = tester
          .getSize(find.byType(ScrollablePositionedList))
          .height;
      // The target can be outside the cache after the jump. Its expanded
      // height and the three intervening comment heights locate its top.
      // The fixture's list starts at y=0, so its normalized edges convert
      // directly to logical pixels in this calculation.
      final double targetTop =
          alignmentOf(7) * viewportHeight -
          (commentHeights[3]! + 40 + 240 + 40);
      await tester.drag(
        find.byType(ScrollablePositionedList),
        Offset(0, (startsAboveViewport ? -180 : 120) - targetTop),
      );
      await settleScroll(tester);
      expect(
        alignmentOf(3),
        startsAboveViewport ? lessThan(0) : greaterThan(0.1),
      );

      cubit.collapse(cubit.state.comments[2]);
      await settleCollapse(tester);

      expectPosition(3, 0.15);
      expect(cubit.state.navigationStack, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('collapse restores a tile that disappears above the viewport', (
    WidgetTester tester,
  ) async {
    commentHeights[3] = 1800;
    await pumpThread(tester, animateCollapse: true);
    unawaited(cubit.scrollTo(index: 3, alignment: -0.5));
    await settleScroll(tester);
    expectPosition(3, -0.5);

    // Only the expanded body intersects the viewport. After it shrinks, the
    // entire tile is above the viewport and absent from the position listener.
    cubit.collapse(cubit.state.comments[2]);
    await settleCollapse(tester);

    expectPosition(3, 0.15);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapse leaves a fully visible tile at its reading position', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester, animateCollapse: true);
    unawaited(cubit.scrollTo(index: 3, alignment: 0.3));
    await settleScroll(tester);

    cubit.collapse(cubit.state.comments[2]);
    await settleCollapse(tester);

    // A visible tile keeps the reading position rather than landing at 0.15.
    expectPosition(3, 0.3);
    expect(cubit.state.navigationStack, isEmpty);
  });

  testWidgets('a newer jump supersedes pending collapse correction', (
    WidgetTester tester,
  ) async {
    commentHeights[3] = 1800;
    await pumpThread(tester, animateCollapse: true);
    unawaited(cubit.scrollTo(index: 3, alignment: -0.5));
    await settleScroll(tester);

    cubit.collapse(cubit.state.comments[2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // The header has stable geometry while the comment shrinks. A stale
    // correction would pull the viewport away from this newer destination.
    unawaited(cubit.scrollTo(index: 0));
    await settleCollapse(tester);

    expectPosition(0, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uncollapsing cancels pending collapse correction', (
    WidgetTester tester,
  ) async {
    commentHeights[3] = 1800;
    await pumpThread(tester, animateCollapse: true);
    unawaited(cubit.scrollTo(index: 3, alignment: -0.5));
    await settleScroll(tester);

    cubit.collapse(cubit.state.comments[2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // The default programmatic expansion cancels the old correction without
    // requesting a new visibility correction of its own.
    cubit.uncollapse(cubit.state.comments[2]);
    await settleCollapse(tester);

    expect(cubit.state.comments[2].isCollapsedByUser, isFalse);
    expectPosition(3, -0.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'expanding a near-top tile restores its heading after animation',
    (WidgetTester tester) async {
      commentHeights[3] = 1800;
      // Seed the collapsed state before attachment so setup cannot schedule a
      // visibility correction that competes with the expansion under test.
      cubit.collapse(cubit.state.comments[2]);
      await pumpThread(tester, animateCollapse: true);
      unawaited(cubit.scrollTo(index: 3, alignment: 0.05));
      await settleScroll(tester);
      expectPosition(3, 0.05);

      cubit.uncollapse(cubit.state.comments[2], ensureVisible: true);
      await settleCollapse(tester);

      expect(cubit.state.comments[2].isCollapsedByUser, isFalse);
      expectPosition(3, 0.15);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('manual scrolling cancels collapse correction with history off', (
    WidgetTester tester,
  ) async {
    await startWithPreferences(
      tester,
      PreferenceState.init().copyWithPreference(
        const HistoryButtonsPreference(val: false),
      ),
    );
    commentHeights[3] = 1800;
    await pumpThread(tester, animateCollapse: true);
    unawaited(cubit.scrollTo(index: 3, alignment: -0.5));
    await settleScroll(tester);

    cubit.collapse(cubit.state.comments[2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(ScrollablePositionedList)),
    );
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump(const Duration(milliseconds: 16));
    // Hold the pointer down while the timer deadline passes, keeping fling
    // movement out of the observation of whether correction was cancelled.
    await settleCollapse(tester);

    // Layout may leave the tile visible at another position or remove it from
    // the listener. The forbidden outcome is the correction's landing at 0.15.
    final ItemPosition? target = cubit.itemPositionsListener.itemPositions.value
        .where((ItemPosition position) => position.index == 3)
        .firstOrNull;
    expect(
      target?.itemLeadingEdge,
      isNot(closeTo(0.15, 0.01)),
      reason: "The correction must not scroll back over the user's gesture",
    );
    await gesture.up();
    await settleScroll(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing cancels pending collapse correction', (
    WidgetTester tester,
  ) async {
    commentHeights[3] = 1800;
    await pumpThread(tester, animateCollapse: true);
    unawaited(cubit.scrollTo(index: 3, alignment: -0.5));
    await settleScroll(tester);

    cubit.collapse(cubit.state.comments[2]);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    // Complete stream cleanup outside the fake-clock zone, then pass the old
    // timer deadline to expose any callbacks retained after the cubit closes.
    await tester.runAsync(cubit.close);
    await tester.pump(CommentsCubit.collapseAnimationDuration);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  for (final bool skipButtonsEnabled in <bool>[true, false]) {
    testWidgets(
      'history off with skip buttons ${skipButtonsEnabled ? 'on' : 'off'} '
      'skips history while comment jumps keep working',
      (WidgetTester tester) async {
        await startWithPreferences(
          tester,
          PreferenceState.init()
              .copyWithPreference(const HistoryButtonsPreference(val: false))
              .copyWithPreference(
                SkipButtonsPreference(val: skipButtonsEnabled),
              ),
        );
        await pumpThread(tester);

        cubit.scrollToNextRoot();
        await settleScroll(tester);
        expectPosition(3, 0.15);
        cubit.scrollToNextRoot();
        await settleScroll(tester);
        expectPosition(5, 0.15);
        cubit.scrollToPreviousRoot();
        await settleScroll(tester);
        expectPosition(3, 0.15);

        final Future<void> searchJump = cubit.scrollToComment(
          cubit.state.comments.last,
        );
        await settleScroll(tester);
        await searchJump;
        expectPosition(7, 0.15);

        final Future<void> topJump = cubit.scrollTo(
          index: 0,
          recordNavigation: true,
        );
        await settleScroll(tester);
        await topJump;
        expectPosition(0, 0);
        expect(cubit.state.navigationStack, isEmpty);

        final List<CommentsState> emitted = <CommentsState>[];
        final StreamSubscription<CommentsState> subscription = cubit.stream
            .listen(emitted.add);
        addTearDown(subscription.cancel);
        await tester.drag(
          find.byType(ScrollablePositionedList),
          const Offset(0, -90),
        );
        await settleScroll(tester);
        final double scrolledAlignment = alignmentOf(0);
        cubit
          ..navigateBack()
          ..navigateForward();
        await settleScroll(tester);
        expectPosition(0, scrolledAlignment);
        expect(cubit.state.navigationStack, isEmpty);
        expect(cubit.state.hasScrolledFromNavigation, isFalse);
        expect(emitted, isEmpty);
      },
    );
  }

  testWidgets('history navigation works with skip buttons disabled', (
    WidgetTester tester,
  ) async {
    await startWithPreferences(
      tester,
      PreferenceState.init().copyWithPreference(
        const SkipButtonsPreference(val: false),
      ),
    );
    await pumpThread(tester);
    expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    expect(find.byIcon(Icons.turn_left), findsOneWidget);
    expect(find.byIcon(Icons.turn_right), findsOneWidget);

    final Future<void> jump = cubit.scrollToComment(cubit.state.comments[2]);
    await settleScroll(tester);
    await jump;
    expectPosition(3, 0.15);
    expect(cubit.state.navigationStack.last.targetComment?.id, 3);

    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(0, 0);
    await tester.tap(find.byIcon(Icons.turn_right));
    await settleScroll(tester);
    expectPosition(3, 0.15);

    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -90),
    );
    await settleScroll(tester);
    expect(cubit.state.hasScrolledFromNavigation, isTrue);
    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(3, 0.15);
    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(0, 0);
  });

  testWidgets('toggling skip buttons preserves active history', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    final List<NavigationAnchor> saved = cubit.state.navigationStack;

    changePreference(const SkipButtonsPreference(val: false));
    await settleScroll(tester);
    expect(cubit.state.navigationStack, same(saved));
    expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
    expect(find.byIcon(Icons.turn_left), findsOneWidget);
    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(3, 0.15);

    changePreference(const SkipButtonsPreference(val: true));
    await settleScroll(tester);
    expect(cubit.state.navigationStack, same(saved));
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    expect(find.byIcon(Icons.turn_right), findsOneWidget);
    await tester.tap(find.byIcon(Icons.turn_right));
    await settleScroll(tester);
    expectPosition(5, 0.15);
    expect(cubit.state.navigationStack, same(saved));
  });

  testWidgets('disabling history freezes saved stops and ignores navigation', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.navigateBack();
    await settleScroll(tester);
    final List<NavigationAnchor> saved = cubit.state.navigationStack;
    final int savedIndex = cubit.state.navigationIndex;

    changePreference(const HistoryButtonsPreference(val: false));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -90),
    );
    await settleScroll(tester);
    final double scrolledAlignment = alignmentOf(3);
    cubit
      ..navigateBack()
      ..navigateForward();
    await settleScroll(tester);
    expectPosition(3, scrolledAlignment);
    expect(cubit.state.hasScrolledFromNavigation, isFalse);

    final Future<void> jump = cubit.scrollToComment(cubit.state.comments.last);
    await settleScroll(tester);
    await jump;
    expectPosition(7, 0.15);
    expect(cubit.state.navigationStack, same(saved));
    expect(cubit.state.navigationIndex, savedIndex);
  });

  testWidgets('disabling history cancels a queued manual-scroll check', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    final List<NavigationAnchor> saved = cubit.state.navigationStack;

    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -90),
    );
    changePreference(const HistoryButtonsPreference(val: false));
    await settleScroll(tester);

    expect(cubit.state.hasScrolledFromNavigation, isFalse);
    expect(cubit.state.navigationStack, same(saved));
    final double scrolledAlignment = alignmentOf(3);
    cubit.navigateBack();
    await settleScroll(tester);
    expectPosition(3, scrolledAlignment);
  });

  testWidgets('disabling history leaves an in-flight comment jump intact', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.scrollToNextRoot();
    final List<NavigationAnchor> saved = cubit.state.navigationStack;
    changePreference(const HistoryButtonsPreference(val: false));
    await settleScroll(tester);
    expectPosition(3, 0.15);
    expect(cubit.state.navigationStack, same(saved));
    expect(cubit.state.hasScrolledFromNavigation, isFalse);

    final Future<void> jump = cubit.scrollTo(
      index: 7,
      alignment: 0.15,
      recordNavigation: true,
    );
    await settleScroll(tester);
    await jump;
    expectPosition(7, 0.15);
    expect(cubit.state.navigationStack, same(saved));
  });

  testWidgets('enabling history seeds the current reading position', (
    WidgetTester tester,
  ) async {
    await startWithPreferences(
      tester,
      PreferenceState.init().copyWithPreference(
        const HistoryButtonsPreference(val: false),
      ),
    );
    await pumpThread(tester);
    final Future<void> jump = cubit.scrollTo(
      index: 5,
      alignment: 0.15,
      recordNavigation: true,
    );
    await settleScroll(tester);
    await jump;
    expect(cubit.state.navigationStack, isEmpty);

    changePreference(const HistoryButtonsPreference(val: true));
    await settleScroll(tester);
    expect(cubit.state.navigationStack, hasLength(1));
    expect(cubit.state.navigationIndex, 0);
    expect(cubit.state.canNavigateBack, isFalse);

    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -90),
    );
    await settleScroll(tester);
    expect(cubit.state.hasScrolledFromNavigation, isTrue);
    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(5, 0.15);
    expect(cubit.state.navigationIndex, 0);
  });

  testWidgets('enabling history during a jump records only its final landing', (
    WidgetTester tester,
  ) async {
    await startWithPreferences(
      tester,
      PreferenceState.init().copyWithPreference(
        const HistoryButtonsPreference(val: false),
      ),
    );
    await pumpThread(tester);
    final Future<void> jump = cubit.scrollTo(
      index: 7,
      alignment: 0.15,
      recordNavigation: true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    changePreference(const HistoryButtonsPreference(val: true));
    await settleScroll(tester);
    await jump;

    expectPosition(7, 0.15);
    expect(cubit.state.navigationStack, hasLength(1));
    expect(cubit.state.navigationIndex, 0);
    expect(cubit.state.canNavigateBack, isFalse);
    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -90),
    );
    await settleScroll(tester);
    expect(cubit.state.hasScrolledFromNavigation, isTrue);
    await tester.tap(find.byIcon(Icons.turn_left));
    await settleScroll(tester);
    expectPosition(7, 0.15);
  });

  testWidgets(
    're-enabling history records only the current disabled position',
    (WidgetTester tester) async {
      await pumpThread(tester);
      cubit.scrollToNextRoot();
      await settleScroll(tester);
      cubit.scrollToNextRoot();
      await settleScroll(tester);
      cubit.navigateBack();
      await settleScroll(tester);
      final List<NavigationAnchor> saved = cubit.state.navigationStack;
      changePreference(const HistoryButtonsPreference(val: false));
      await settleScroll(tester);

      final Future<void> jump = cubit.scrollTo(
        index: 7,
        alignment: 0.15,
        recordNavigation: true,
      );
      await settleScroll(tester);
      await jump;
      expect(cubit.state.navigationStack, same(saved));

      changePreference(const HistoryButtonsPreference(val: true));
      await settleScroll(tester);
      expect(cubit.state.navigationStack, hasLength(4));
      expect(cubit.state.navigationStack.take(2), saved.take(2));
      expect(cubit.state.navigationStack.last, saved.last);
      expect(cubit.state.navigationIndex, 2);
      expect(cubit.state.canNavigateForward, isTrue);

      await tester.drag(
        find.byType(ScrollablePositionedList),
        const Offset(0, -90),
      );
      await settleScroll(tester);
      final double scrolledAlignment = alignmentOf(7);
      await tester.tap(find.byIcon(Icons.turn_left));
      await settleScroll(tester);
      expectPosition(7, 0.15);
      cubit.navigateBack();
      await settleScroll(tester);
      expectPosition(3, 0.15);
      cubit.navigateForward();
      await settleScroll(tester);
      expectPosition(7, 0.15);
      cubit.navigateForward();
      await settleScroll(tester);
      expectPosition(7, scrolledAlignment);
      cubit.navigateForward();
      await settleScroll(tester);
      expectPosition(5, 0.15);
    },
  );

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
      if (!jumpToTop) {
        expect(
          cubit.state.navigationStack.last.targetComment,
          same(cubit.state.comments.last),
        );
      }

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
        <int>[_storyId, 3, destinationId],
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
      <int>[_storyId, 3, 7],
    );
    expect(cubit.state.canNavigateForward, isFalse);
    expect(
      cubit.state.navigationStack.last.targetComment,
      same(cubit.state.comments.last),
    );

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

  testWidgets('later jumps retain the selected comment in each history item', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    final Comment firstTarget = cubit.state.comments[2];
    final Comment secondTarget = cubit.state.comments[4];
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);

    expect(
      cubit.state.navigationStack.map((NavigationAnchor item) => item.itemId),
      <int>[_storyId, 3, 5],
    );
    expect(cubit.state.navigationStack[1].targetComment, same(firstTarget));
    expect(cubit.state.navigationStack[2].targetComment, same(secondTarget));
    final List<NavigationAnchor> saved = cubit.state.navigationStack;

    cubit.navigateBack();
    await settleScroll(tester);
    expectPosition(3, 0.15);
    expect(cubit.state.canNavigateForward, isTrue);
    expect(cubit.state.navigationStack, same(saved));
    cubit.navigateForward();
    await settleScroll(tester);
    expectPosition(5, 0.15);
    expect(cubit.state.navigationStack, same(saved));
  });

  testWidgets(
    'Back targets the selected comment after nearby row heights change',
    (WidgetTester tester) async {
      await pumpThread(tester);
      cubit.scrollToNextRoot();
      await settleScroll(tester);
      cubit.scrollToNextRoot();
      await settleScroll(tester);

      commentHeights[2] = 160;
      cubit.emit(
        cubit.state.copyWith(
          comments: cubit.state.comments
              .map(
                (Comment comment) =>
                    comment.id == 2 ? comment.copyWith(isNew: true) : comment,
              )
              .toList(),
        ),
      );
      await settleScroll(tester);
      unawaited(cubit.scrollTo(index: 5, alignment: 0.15));
      await settleScroll(tester);

      cubit.navigateBack();
      await settleScroll(tester);
      expectPosition(3, 0.15);
      expect(cubit.state.navigationStack[1].targetComment?.id, 3);
      cubit.navigateForward();
      await settleScroll(tester);
      expectPosition(5, 0.15);
    },
  );

  testWidgets('history resolves its target comment after comments move', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    cubit.scrollToNextRoot();
    await settleScroll(tester);
    final List<NavigationAnchor> saved = cubit.state.navigationStack;
    final Map<int, Comment> comments = <int, Comment>{
      for (final Comment comment in cubit.state.comments) comment.id: comment,
    };
    comments[3] = comments[3]!.copyWith(isNew: true);
    cubit.emit(
      cubit.state.copyWith(
        comments: <int>[
          1,
          2,
          5,
          6,
          3,
          4,
          7,
        ].map((int id) => comments[id]!).toList(),
      ),
    );
    await settleScroll(tester);
    unawaited(cubit.scrollTo(index: 3, alignment: 0.15));
    await settleScroll(tester);

    cubit.navigateBack();
    await settleScroll(tester);
    expect(cubit.state.comments[4].id, 3);
    expect(cubit.state.comments[4].isNew, isTrue);
    expectPosition(5, 0.15);
    expect(cubit.state.navigationStack, same(saved));
    cubit.navigateForward();
    await settleScroll(tester);
    expect(cubit.state.comments[2].id, 5);
    expectPosition(3, 0.15);
    expect(cubit.state.navigationStack, same(saved));
  });

  for (final bool hasTargetKey in <bool>[false, true]) {
    testWidgets('Back reveals a saved target hidden by its collapsed parent '
        '${hasTargetKey ? 'with' : 'without'} a target key', (
      WidgetTester tester,
    ) async {
      await pumpThread(tester);
      final Future<void> jump = cubit.scrollToComment(cubit.state.comments[3]);
      await settleScroll(tester);
      await jump;
      unawaited(
        cubit.scrollTo(index: 7, alignment: 0.15, recordNavigation: true),
      );
      await settleScroll(tester);
      final List<NavigationAnchor> saved = cubit.state.navigationStack;
      expect(saved[1].targetComment?.id, 4);
      if (hasTargetKey) cubit.globalKeys[4] = GlobalKey();
      cubit.collapse(cubit.state.comments[2]);
      await settleScroll(tester);
      expect(cubit.state.comments[3].isHiddenByUser, isTrue);
      unawaited(cubit.scrollTo(index: 7, alignment: 0.15));
      await settleScroll(tester);

      await tester.tap(find.byIcon(Icons.turn_left));
      await settleCommentJump(tester);
      expect(cubit.state.comments[2].isCollapsedByUser, isFalse);
      expect(cubit.state.comments[3].isHiddenByUser, isFalse);
      expectPosition(4, 0.15);
      expect(cubit.state.navigationStack, same(saved));
      expect(cubit.state.canNavigateForward, isTrue);
      await tester.tap(find.byIcon(Icons.turn_right));
      await settleCommentJump(tester);
      expectPosition(7, 0.15);
      expect(cubit.state.navigationStack, same(saved));
    });
  }

  testWidgets('rapid Forward cancels an unfinished Back comment jump', (
    WidgetTester tester,
  ) async {
    await pumpThread(tester);
    final Future<void> jump = cubit.scrollToComment(cubit.state.comments[3]);
    await settleScroll(tester);
    await jump;
    unawaited(
      cubit.scrollTo(index: 7, alignment: 0.15, recordNavigation: true),
    );
    await settleScroll(tester);
    final List<NavigationAnchor> saved = cubit.state.navigationStack;

    cubit
      ..navigateBack()
      ..navigateForward();
    await settleCommentJump(tester);
    expectPosition(7, 0.15);
    expect(cubit.state.navigationIndex, 2);
    expect(cubit.state.navigationStack, same(saved));
  });

  testWidgets(
    'a target removed during its jump does not unfold a stale comment',
    (WidgetTester tester) async {
      cubit.emit(
        cubit.state.copyWith(
          comments: cubit.state.comments
              .map(
                (Comment comment) => comment.id == 4
                    ? comment.copyWith(isCollapsedByUser: true)
                    : comment,
              )
              .toList(),
        ),
      );
      await pumpThread(tester);
      final Future<void> jump = cubit.scrollToComment(cubit.state.comments[3]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      cubit.emit(
        cubit.state.copyWith(
          comments: cubit.state.comments
              .where((Comment comment) => comment.id != 4)
              .toList(),
        ),
      );
      await settleScroll(tester);
      await jump;
      expect(
        cubit.state.comments.any((Comment comment) => comment.id == 4),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a target replaced during its jump keeps its latest state', (
    WidgetTester tester,
  ) async {
    cubit.emit(
      cubit.state.copyWith(
        comments: cubit.state.comments
            .map(
              (Comment comment) => comment.id == 4
                  ? comment.copyWith(isCollapsedByUser: true)
                  : comment,
            )
            .toList(),
      ),
    );
    await pumpThread(tester);
    final Future<void> jump = cubit.scrollToComment(cubit.state.comments[3]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    cubit.emit(
      cubit.state.copyWith(
        comments: cubit.state.comments.map((Comment comment) {
          if (comment.id == 4) {
            return comment.copyWith(
              isCollapsedByUser: false,
              isHiddenByUser: true,
              isNew: true,
            );
          }
          return comment.id == 3
              ? comment.copyWith(isCollapsedByUser: true)
              : comment;
        }).toList(),
      ),
    );
    await settleScroll(tester);
    await jump;
    expect(cubit.state.comments[2].isCollapsedByUser, isFalse);
    expect(cubit.state.comments[3].isHiddenByUser, isFalse);
    expect(cubit.state.comments[3].isNew, isTrue);
  });

  testWidgets('comment flash is visible within 300 ms of the settled jump', (
    WidgetTester tester,
  ) async {
    cubit.globalKeys[3] = GlobalKey();
    await pumpThread(tester);

    final Future<void> jump = cubit.scrollToComment(cubit.state.comments[2]);
    await settleScroll(tester);
    expectPosition(3, 0.15);
    expect(find.byType(ShineOverlay), findsNothing);

    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(ShineOverlay), findsNothing);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(ShineOverlay), findsOneWidget);

    await jump;
    await tester.pumpAndSettle();
    expect(find.byType(ShineOverlay), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a superseding jump cancels the pending comment flash', (
    WidgetTester tester,
  ) async {
    cubit.globalKeys[3] = GlobalKey();
    await pumpThread(tester);

    final Future<void> jump = cubit.scrollToComment(cubit.state.comments[2]);
    await settleScroll(tester);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(ShineOverlay), findsNothing);

    final Future<void> nextJump = cubit.scrollTo(index: 5, alignment: 0.15);
    await settleScroll(tester);
    await jump;
    await nextJump;
    expectPosition(5, 0.15);
    expect(find.byType(ShineOverlay), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final bool scrollDown in <bool>[false, true]) {
    testWidgets(
      'comment shine follows manual scrolling ${scrollDown ? 'down' : 'up'}',
      (WidgetTester tester) async {
        final GlobalKey captureKey = GlobalKey();
        final GlobalKey targetKey = GlobalKey();
        cubit.globalKeys[3] = targetKey;
        await pumpThread(
          tester,
          captureKey: captureKey,
          theme: ThemeData.dark(),
        );
        final Future<void> jump = cubit.scrollToComment(
          cubit.state.comments[2],
        );
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.byType(ShineOverlay).evaluate().isNotEmpty) break;
        }
        expect(find.byType(ShineOverlay), findsOneWidget);
        // Let the gentle flash fade in before sampling its painted pixels.
        await tester.pump(const Duration(milliseconds: 200));
        final Finder capture = find.byKey(captureKey);
        final Offset origin = tester.getTopLeft(capture);
        final Rect before = tester
            .getRect(find.byKey(targetKey))
            .shift(-origin);

        // Keep the pointer down so the later comparison cannot include fling
        // movement while waiting for the shine to finish.
        final double direction = scrollDown ? -1 : 1;
        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byType(ScrollablePositionedList)),
        );
        await gesture.moveBy(Offset(0, direction * 20));
        await tester.pump();
        await gesture.moveBy(Offset(0, direction * 120));
        await tester.pump(const Duration(milliseconds: 16));
        final Rect after = tester.getRect(find.byKey(targetKey)).shift(-origin);
        expect((after.top - before.top).abs(), greaterThan(100));
        final Uint8List shining = await capturePixels(tester, captureKey);

        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(find.byType(ShineOverlay), findsNothing);
        expect(tester.getRect(find.byKey(targetKey)).shift(-origin), after);
        final Uint8List baseline = await capturePixels(tester, captureKey);
        final Size size = tester.getSize(capture);
        final Rect newBand = scrollDown
            ? Rect.fromLTRB(after.left, after.top, after.right, before.top)
            : Rect.fromLTRB(
                after.left,
                before.bottom,
                after.right,
                after.bottom,
              );
        final Rect abandonedBand = scrollDown
            ? Rect.fromLTRB(
                before.left,
                after.bottom,
                before.right,
                before.bottom,
              )
            : Rect.fromLTRB(before.left, before.top, before.right, after.top);
        expect(
          changedPixels(
            shining,
            baseline,
            newBand.deflate(4),
            width: size.width.round(),
            height: size.height.round(),
          ),
          greaterThan(100),
          reason: 'The shine should paint in the newly occupied comment area',
        );
        expect(
          changedPixels(
            shining,
            baseline,
            abandonedBand.deflate(4),
            width: size.width.round(),
            height: size.height.round(),
          ),
          0,
          reason:
              'The shine should leave no paint at the former screen position',
        );
        await gesture.up();
        await jump;
        await tester.pumpAndSettle();
      },
    );
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
