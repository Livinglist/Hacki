import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/item/widgets/main_view.dart';
import 'package:hacki/screens/widgets/item_slidable.dart';
import 'package:hacki/services/services.dart';
import 'package:logger/logger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../mocks/mocks.dart';
import '../../golden_test_utils.dart';

class _MockFilterCubit extends MockCubit<FilterState> implements FilterCubit {}

class _MockOfflineRepository extends Mock implements OfflineRepository {}

class _MockHackerNewsWebRepository extends Mock
    implements HackerNewsWebRepository {}

class _MockCollapseStateCacheRepository extends Mock
    implements CollapseStateCacheRepository {}

class _MockAppLifecycleService extends Mock implements AppLifecycleService {}

const Key _replyKey = Key('parent-action-reply');
const int _storyId = 100;

Comment _comment(int id, {int? parent}) => Comment.fromJson(<String, dynamic>{
  'id': id,
  'parent': parent ?? _storyId,
  'by': 'someone',
  'text': 'Comment $id',
}).copyWith(level: parent == null ? 0 : 1);

void main() {
  late CommentsCubit cubit;
  late MockPreferenceCubit preferences;
  late MockAuthBloc auth;
  late StreamController<AppLifecycleState> lifecycle;
  late TextEditingController editingController;

  setUp(() {
    locator.registerSingleton<Logger>(MockLogger());
    lifecycle = StreamController<AppLifecycleState>.broadcast();
    editingController = TextEditingController();
    final _MockFilterCubit filter = _MockFilterCubit();
    when(() => filter.state).thenReturn(FilterState.init());
    preferences = MockPreferenceCubit();
    when(
      () => preferences.state,
    ).thenReturn(slidePreferenceState(trailing: SlideAction.goToParent));
    auth = MockAuthBloc();
    when(() => auth.state).thenReturn(const AuthState.init());
    final _MockAppLifecycleService appLifecycle = _MockAppLifecycleService();
    when(() => appLifecycle.stream).thenAnswer((_) => lifecycle.stream);
    final _MockCollapseStateCacheRepository collapseStates =
        _MockCollapseStateCacheRepository();
    when(
      () => collapseStates.saveStoryStates(any(), any()),
    ).thenAnswer((_) async {});

    cubit = CommentsCubit(
      filterCubit: filter,
      preferenceCubit: preferences,
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
    editingController.dispose();
    await locator.reset();
  });

  Future<void> settleScroll(WidgetTester tester) async {
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
  }

  void expectPosition(int index, double alignment) {
    final ItemPosition position = cubit
        .itemPositionsListener
        .itemPositions
        .value
        .singleWhere((ItemPosition position) => position.index == index);
    expect(position.itemLeadingEdge, closeTo(alignment, 0.01));
  }

  for (final bool swipe in <bool>[false, true]) {
    testWidgets(
      'Go to parent ${swipe ? 'swipe' : 'tap'} clears forward history',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        int parentActions = 0;
        final MainView mainView = MainView(
          scrollOffsetListener: ScrollOffsetListener.create(),
          commentEditingController: editingController,
          preferenceState: preferences.state,
          splitViewEnabled: false,
          onMoreTapped: (_, __) {},
          onShareTapped: (_, __) async {},
          onStoryUrlTapped: () {},
          shouldMarkNewComment: false,
          indentPadding: 8,
          indentLineWidth: 2,
          topPadding: 0,
        );
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: <BlocProvider<dynamic>>[
              BlocProvider<CommentsCubit>.value(value: cubit),
              BlocProvider<PreferenceCubit>.value(value: preferences),
              BlocProvider<AuthBloc>.value(value: auth),
            ],
            child: MaterialApp(
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
                    final Widget tile = SizedBox(
                      key: comment.id == 4 ? _replyKey : null,
                      height: comment.isRoot ? 240 : 120,
                      child: ColoredBox(
                        color: Theme.of(context).colorScheme.surface,
                        child: Text(comment.text),
                      ),
                    );
                    if (comment.id != 4) return tile;
                    return ItemSlidable(
                      item: comment,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                      onTrailingActionTapped: () {
                        parentActions++;
                        unawaited(
                          mainView.onSlideActionTapped(
                            context,
                            comment,
                            SlideAction.goToParent,
                          ),
                        );
                      },
                      child: tile,
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await settleScroll(tester);
        unawaited(
          cubit.scrollTo(index: 4, alignment: 0.15, recordNavigation: true),
        );
        await settleScroll(tester);
        unawaited(
          cubit.scrollTo(index: 7, alignment: 0.15, recordNavigation: true),
        );
        await settleScroll(tester);
        cubit.navigateBack();
        await settleScroll(tester);
        expectPosition(4, 0.15);
        expect(cubit.state.canNavigateForward, isTrue);

        if (swipe) {
          final TestGesture gesture = await tester.startGesture(
            tester.getCenter(find.byKey(_replyKey)),
          );
          await gesture.moveBy(const Offset(-80, 0));
          await tester.pump();
          await gesture.moveBy(const Offset(-270, 0));
          await tester.pump();
          await gesture.up();
        } else {
          final SlidableController controller = Slidable.of(
            tester.element(find.byKey(_replyKey)),
          )!;
          unawaited(controller.openEndActionPane());
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(SlideAction.goToParent.icon));
        }
        await settleScroll(tester);

        expect(parentActions, 1);
        expect(cubit.state.canNavigateForward, isFalse);
        expect(
          cubit.state.navigationStack.map(
            (NavigationAnchor anchor) => anchor.itemId,
          ),
          <int>[_storyId, 4, 3],
        );
        cubit.navigateBack();
        await settleScroll(tester);
        expectPosition(4, 0.15);
        cubit.navigateBack();
        await settleScroll(tester);
        expectPosition(0, 0);
      },
    );
  }
}
