import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/config/paths.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/item_screen.dart';
import 'package:hacki/screens/pins/pins_screen.dart';
import 'package:hacki/screens/widgets/custom_linkify/custom_linkify.dart';
import 'package:hacki/screens/widgets/pinned_item_tile.dart';
import 'package:hacki/screens/widgets/story_tile.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockPinCubit extends MockCubit<PinState> implements PinCubit {}

class _MockPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

class _MockSplitViewCubit extends MockCubit<SplitViewState>
    implements SplitViewCubit {}

final Story _story = Story.fromJson(const <String, dynamic>{
  'id': 100,
  'type': 'story',
  'title': 'A pinned story',
  'by': 'author',
});

final Comment _comment = Comment.fromJson(const <String, dynamic>{
  'id': 200,
  'type': 'comment',
  'parent': 100,
  'text': 'A useful comment thread',
  'by': 'alice',
});

void main() {
  late _MockPinCubit pinCubit;
  late _MockPreferenceCubit preferenceCubit;
  late _MockSplitViewCubit splitViewCubit;

  setUpAll(() {
    registerFallbackValue(ItemScreenArgs(item: _comment));
  });

  setUp(() {
    pinCubit = _MockPinCubit();
    when(() => pinCubit.state).thenReturn(
      PinState.init().copyWith(
        pinnedItemsIds: <int>[_story.id, _comment.id],
        pinnedItems: <Item>[_story, _comment],
      ),
    );
    preferenceCubit = _MockPreferenceCubit();
    when(() => preferenceCubit.state).thenReturn(
      PreferenceState.init()
          .copyWithPreference(const RichStoryTilePreference(val: false))
          .copyWithPreference(const FaviconModePreference(val: false)),
    );
    splitViewCubit = _MockSplitViewCubit();
    when(() => splitViewCubit.state).thenReturn(const SplitViewState.init());
  });

  Future<void> withPins(
    WidgetTester tester, {
    ValueChanged<ItemScreenArgs>? onNavigate,
  }) async {
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const PinsScreen(),
        ),
        GoRoute(
          path: Paths.item.landing,
          builder: (BuildContext context, GoRouterState state) {
            onNavigate?.call(state.extra! as ItemScreenArgs);
            return const Scaffold(body: Text('Opened thread'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<PinCubit>.value(value: pinCubit),
          BlocProvider<PreferenceCubit>.value(value: preferenceCubit),
          BlocProvider<SplitViewCubit>.value(value: splitViewCubit),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder commentTile() => find.byWidgetPredicate(
    (Widget widget) =>
        widget is PinnedItemTile && widget.item.id == _comment.id,
  );

  testWidgets('renders mixed pins and opens the pinned comment thread', (
    WidgetTester tester,
  ) async {
    ItemScreenArgs? openedThread;
    await withPins(
      tester,
      onNavigate: (ItemScreenArgs args) => openedThread = args,
    );

    expect(find.byType(PinnedItemTile), findsNWidgets(2));
    expect(find.byType(StoryTile), findsOneWidget);
    expect(tester.widget<StoryTile>(find.byType(StoryTile)).story, _story);
    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is Linkify && widget.text == _comment.text,
      ),
      findsOneWidget,
    );

    await tester.tap(commentTile());
    await tester.pumpAndSettle();

    expect(openedThread?.item, _comment);
    expect(find.text('Opened thread'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens a comment pin in the split view when enabled', (
    WidgetTester tester,
  ) async {
    when(
      () => splitViewCubit.state,
    ).thenReturn(const SplitViewState.init().copyWith(enabled: true));
    await withPins(tester);

    await tester.tap(commentTile());
    await tester.pumpAndSettle();

    final ItemScreenArgs args =
        verify(
              () => splitViewCubit.updateItemScreenArgs(captureAny()),
            ).captured.single
            as ItemScreenArgs;
    expect(args.item, _comment);
    expect(find.byType(PinsScreen), findsOneWidget);
    expect(find.text('Opened thread'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
