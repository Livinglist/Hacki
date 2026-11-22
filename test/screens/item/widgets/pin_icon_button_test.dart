import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/widgets/custom_app_bar.dart';
import 'package:hacki/screens/item/widgets/pin_icon_button.dart';
import 'package:hacki/utils/haptic_feedback_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockPinCubit extends MockCubit<PinState> implements PinCubit {}

class _MockFavCubit extends MockCubit<FavState> implements FavCubit {}

class _MockTipsCubit extends MockCubit<TipsState> implements TipsCubit {}

final Comment _comment = Comment.fromJson(const <String, dynamic>{
  'id': 123,
  'type': 'comment',
  'by': 'alice',
  'text': 'A thread worth keeping',
});

final Story _story = Story.fromJson(const <String, dynamic>{
  'id': 1,
  'title': 'A pinned story',
});

void main() {
  late _MockPinCubit pinCubit;
  late bool wasHapticsEnabled;

  setUpAll(() {
    registerFallbackValue(_story);
  });

  setUp(() {
    pinCubit = _MockPinCubit();
    when(() => pinCubit.state).thenReturn(PinState.init());
    wasHapticsEnabled = HapticFeedbackUtils.enabled;
    HapticFeedbackUtils.enabled = false;
    void completePinChange(Invocation invocation) {
      final VoidCallback onDone =
          invocation.namedArguments[#onDone] as VoidCallback;
      onDone();
    }

    when(
      () => pinCubit.pinItem(any(), onDone: any(named: 'onDone')),
    ).thenAnswer(completePinChange);
    when(
      () => pinCubit.unpinItem(any(), onDone: any(named: 'onDone')),
    ).thenAnswer(completePinChange);
  });

  tearDown(() {
    HapticFeedbackUtils.enabled = wasHapticsEnabled;
  });

  Future<GoRouter> pumpButton(
    WidgetTester tester, {
    bool isPinned = false,
    Item? item,
    Stream<PinState>? changes,
  }) async {
    final Item target = item ?? _story;
    final PinState initialState = PinState.init().copyWith(
      pinnedItemsIds: isPinned ? <int>[target.id] : <int>[],
      pinnedItems: isPinned ? <Item>[target] : <Item>[],
    );
    if (changes == null) {
      when(() => pinCubit.state).thenReturn(initialState);
    } else {
      whenListen(pinCubit, changes, initialState: initialState);
    }
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) => Scaffold(
            appBar: AppBar(title: const Text('Thread')),
            body: Center(child: PinIconButton(item: target)),
          ),
          routes: <RouteBase>[
            GoRoute(
              path: 'item',
              builder: (BuildContext context, GoRouterState state) => Scaffold(
                appBar: AppBar(title: const Text('Item')),
                body: Center(child: PinIconButton(item: target)),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/pins',
          builder: (BuildContext context, GoRouterState state) =>
              Scaffold(appBar: AppBar(title: const Text('Pins'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider<PinCubit>.value(
        value: pinCubit,
        child: FeatureDiscovery(
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  for (final Item item in <Item>[_story, _comment]) {
    for (final bool isPinned in <bool>[false, true]) {
      testWidgets('${isPinned ? 'removing' : 'adding'} a '
          '${item is Comment ? 'comment' : 'story'} pin offers '
          'navigation to all pins', (WidgetTester tester) async {
        final GoRouter router = await pumpButton(
          tester,
          isPinned: isPinned,
          item: item,
        );

        await tester.tap(find.byTooltip('Pin to home screen'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            isPinned
                ? SnackBarMessages.storyUnpinned
                : SnackBarMessages.storyPinned,
          ),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SnackBarAction, 'See all pins'),
          findsOneWidget,
        );
        if (isPinned) {
          verify(
            () => pinCubit.unpinItem(item, onDone: any(named: 'onDone')),
          ).called(1);
          verifyNever(
            () => pinCubit.pinItem(item, onDone: any(named: 'onDone')),
          );
        } else {
          verify(
            () => pinCubit.pinItem(item, onDone: any(named: 'onDone')),
          ).called(1);
          verifyNever(
            () => pinCubit.unpinItem(item, onDone: any(named: 'onDone')),
          );
        }

        await tester.tap(find.text('See all pins'));
        await tester.pumpAndSettle();

        expect(router.state.uri.path, '/pins');
        expect(find.text('Pins'), findsOneWidget);
        expect(router.canPop(), isTrue);

        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(router.state.uri.path, '/');
        expect(find.text('Thread'), findsOneWidget);
        expect(find.byType(PinIconButton), findsOneWidget);
      });
    }
  }

  testWidgets('the pins action works after leaving the source item', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpButton(tester, item: _comment);
    router.go('/item');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Pin to home screen'));
    await tester.pumpAndSettle();
    expect(find.text('See all pins'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/');
    expect(find.text('Thread'), findsOneWidget);
    expect(find.text('See all pins'), findsOneWidget);

    await tester.tap(find.text('See all pins'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/pins');
    expect(find.text('Pins'), findsOneWidget);
  });

  testWidgets('the pin snackbar still dismisses after its duration', (
    WidgetTester tester,
  ) async {
    await pumpButton(tester);

    await tester.tap(find.byTooltip('Pin to home screen'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('See all pins'), findsOneWidget);

    await tester.pump(AppDurations.fourSeconds);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });
  testWidgets('pins and unpins a comment thread with visible feedback', (
    WidgetTester tester,
  ) async {
    final StreamController<PinState> pins =
        StreamController<PinState>.broadcast(sync: true);
    addTearDown(pins.close);
    when(
      () => pinCubit.pinItem(_comment, onDone: any(named: 'onDone')),
    ).thenAnswer((Invocation invocation) {
      pins.add(
        PinState.init().copyWith(
          pinnedItemsIds: <int>[_comment.id],
          pinnedItems: <Item>[_comment],
        ),
      );
      (invocation.namedArguments[#onDone] as VoidCallback?)?.call();
    });
    when(
      () => pinCubit.unpinItem(_comment, onDone: any(named: 'onDone')),
    ).thenAnswer((Invocation invocation) {
      pins.add(PinState.init());
      (invocation.namedArguments[#onDone] as VoidCallback?)?.call();
    });

    await pumpButton(tester, item: _comment, changes: pins.stream);

    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    expect(find.text('Added to Pins.'), findsOneWidget);
    verify(
      () => pinCubit.pinItem(_comment, onDone: any(named: 'onDone')),
    ).called(1);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    expect(find.text('Removed from Pins.'), findsOneWidget);
    verify(
      () => pinCubit.unpinItem(_comment, onDone: any(named: 'onDone')),
    ).called(1);
  });

  testWidgets('shows the pin button on a comment thread app bar', (
    WidgetTester tester,
  ) async {
    final _MockFavCubit favCubit = _MockFavCubit();
    when(() => favCubit.state).thenReturn(FavState.init());
    final _MockTipsCubit tipsCubit = _MockTipsCubit();
    when(
      () => tipsCubit.state,
    ).thenReturn(const TipsState(completedTips: <Tips>{Tips.itemScreen}));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<PinCubit>.value(value: pinCubit),
          BlocProvider<FavCubit>.value(value: favCubit),
          BlocProvider<TipsCubit>.value(value: tipsCubit),
        ],
        child: FeatureDiscovery(
          child: MaterialApp(
            home: Builder(
              builder: (BuildContext context) => Scaffold(
                appBar: CustomAppBar(
                  context: context,
                  item: _comment,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  onFontSizeTap: () {},
                  fontSizeIconButtonKey: GlobalKey(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PinIconButton), findsOneWidget);
    expect(
      tester.widget<PinIconButton>(find.byType(PinIconButton)).item,
      _comment,
    );
    expect(tester.takeException(), isNull);
  });
}
