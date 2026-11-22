import 'package:bloc_test/bloc_test.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/widgets/pin_icon_button.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockPinCubit extends MockCubit<PinState> implements PinCubit {}

final Story _story = Story.fromJson(const <String, dynamic>{
  'id': 1,
  'title': 'A pinned story',
});

void main() {
  late _MockPinCubit pinCubit;

  setUp(() {
    pinCubit = _MockPinCubit();
    void completePinChange(Invocation invocation) {
      final VoidCallback onDone =
          invocation.namedArguments[#onDone] as VoidCallback;
      onDone();
    }

    when(
      () => pinCubit.pinStory(_story, onDone: any(named: 'onDone')),
    ).thenAnswer(completePinChange);
    when(
      () => pinCubit.unpinStory(_story, onDone: any(named: 'onDone')),
    ).thenAnswer(completePinChange);
  });

  Future<GoRouter> pumpButton(
    WidgetTester tester, {
    bool isPinned = false,
  }) async {
    when(() => pinCubit.state).thenReturn(
      PinState.init().copyWith(
        pinnedStoriesIds: isPinned ? <int>[_story.id] : <int>[],
        pinnedStories: isPinned ? <Story>[_story] : <Story>[],
      ),
    );
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) => Scaffold(
            appBar: AppBar(title: const Text('Thread')),
            body: Center(child: PinIconButton(story: _story)),
          ),
          routes: <RouteBase>[
            GoRoute(
              path: 'item',
              builder: (BuildContext context, GoRouterState state) => Scaffold(
                appBar: AppBar(title: const Text('Item')),
                body: Center(child: PinIconButton(story: _story)),
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

  for (final bool isPinned in <bool>[false, true]) {
    testWidgets(
      '${isPinned ? 'removing' : 'adding'} a pin offers navigation to all pins',
      (WidgetTester tester) async {
        final GoRouter router = await pumpButton(tester, isPinned: isPinned);

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
            () => pinCubit.unpinStory(_story, onDone: any(named: 'onDone')),
          ).called(1);
          verifyNever(
            () => pinCubit.pinStory(_story, onDone: any(named: 'onDone')),
          );
        } else {
          verify(
            () => pinCubit.pinStory(_story, onDone: any(named: 'onDone')),
          ).called(1);
          verifyNever(
            () => pinCubit.unpinStory(_story, onDone: any(named: 'onDone')),
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
      },
    );
  }

  testWidgets('the pins action works after leaving the source item', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpButton(tester);
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
}
