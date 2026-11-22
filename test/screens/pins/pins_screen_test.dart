import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/config/paths.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/item_screen.dart';
import 'package:hacki/screens/pins/pins_screen.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/utils/haptic_feedback_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockPinCubit extends MockCubit<PinState> implements PinCubit {}

class _MockPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

class _MockSplitViewCubit extends MockCubit<SplitViewState>
    implements SplitViewCubit {}

final Comment _comment = Comment.fromJson(const <String, dynamic>{
  'id': 200,
  'type': 'comment',
  'parent': 1,
  'text': 'A useful comment thread',
  'by': 'alice',
});

final Story _story = Story.fromJson(const <String, dynamic>{
  'id': 1,
  'title': 'A pinned story',
});

void main() {
  late _MockPinCubit pinCubit;
  late _MockSplitViewCubit splitViewCubit;
  late StreamController<PinState> pinChanges;
  late List<String> haptics;
  late bool wasHapticsEnabled;

  setUpAll(() {
    registerFallbackValue(ItemScreenArgs(item: _comment));
  });

  setUp(() {
    pinCubit = _MockPinCubit();
    splitViewCubit = _MockSplitViewCubit();
    when(() => splitViewCubit.state).thenReturn(const SplitViewState.init());
    pinChanges = StreamController<PinState>.broadcast();
    haptics = <String>[];
    wasHapticsEnabled = HapticFeedbackUtils.enabled;
    HapticFeedbackUtils.enabled = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        });
  });

  tearDown(() async {
    HapticFeedbackUtils.enabled = wasHapticsEnabled;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    await pinChanges.close();
  });

  Future<void> pumpPins(
    WidgetTester tester, {
    bool hasPins = true,
    ValueChanged<ItemScreenArgs>? onNavigate,
  }) async {
    whenListen(
      pinCubit,
      pinChanges.stream,
      initialState: PinState.init().copyWith(
        pinnedItemsIds: hasPins ? <int>[_story.id, _comment.id] : <int>[],
        pinnedItems: hasPins ? <Item>[_story, _comment] : <Item>[],
      ),
    );
    final _MockPreferenceCubit preferenceCubit = _MockPreferenceCubit();
    when(() => preferenceCubit.state).thenReturn(
      PreferenceState.init()
          .copyWithPreference(const RichStoryTilePreference(val: false))
          .copyWithPreference(const FaviconModePreference(val: false)),
    );
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
          BlocProvider<SplitViewCubit>.value(value: splitViewCubit),
          BlocProvider<PreferenceCubit>.value(value: preferenceCubit),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a centered message when there are no pins', (
    WidgetTester tester,
  ) async {
    await pumpPins(tester, hasPins: false);

    final Finder message = find.text('No pins here');
    expect(message, findsOneWidget);
    expect(find.byType(StoryTile), findsNothing);
    final Offset bodyCenter = tester.getCenter(find.byType(CenteredText));
    final Offset messageCenter = tester.getCenter(message);
    expect(messageCenter.dx, closeTo(bodyCenter.dx, 1));
    expect(messageCenter.dy, closeTo(bodyCenter.dy, 12));

    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(() => pinCubit.removeAll());
    expect(haptics, isEmpty);
  });

  testWidgets('shows mixed pins instead of the empty message', (
    WidgetTester tester,
  ) async {
    await pumpPins(tester);

    expect(find.byType(StoryTile), findsOneWidget);
    expect(find.byType(PinnedItemTile), findsNWidgets(2));
    expect(
      find.byKey(ValueKey<String>('${_story.id}-PinnedItemTile')),
      findsOneWidget,
    );
    expect(find.text('No pins here'), findsNothing);
  });

  for (final bool hapticsEnabled in <bool>[true, false]) {
    testWidgets(
      'confirming removal empties pins with haptics enabled: $hapticsEnabled',
      (WidgetTester tester) async {
        HapticFeedbackUtils.enabled = hapticsEnabled;
        when(() => pinCubit.removeAll()).thenAnswer((_) {
          pinChanges.add(PinState.init());
        });
        await pumpPins(tester);

        await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
        await tester.pumpAndSettle();
        expect(find.text('Remove all pins?'), findsOneWidget);
        verifyNever(() => pinCubit.removeAll());
        expect(haptics, isEmpty);

        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        verify(() => pinCubit.removeAll()).called(1);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(PinnedItemTile), findsNothing);
        expect(find.byType(StoryTile), findsNothing);
        expect(find.text('No pins here'), findsOneWidget);
        expect(
          haptics,
          hapticsEnabled
              ? <String>['HapticFeedbackType.successNotification']
              : isEmpty,
        );
      },
    );
  }

  testWidgets('canceling removal keeps pins without success feedback', (
    WidgetTester tester,
  ) async {
    await pumpPins(tester);

    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => pinCubit.removeAll());
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(StoryTile), findsOneWidget);
    expect(find.text('No pins here'), findsNothing);
    expect(haptics, isEmpty);
  });
  Finder commentTile() => find.byWidgetPredicate(
    (Widget widget) =>
        widget is PinnedItemTile && widget.item.id == _comment.id,
  );

  testWidgets('renders mixed pins and opens the pinned comment thread', (
    WidgetTester tester,
  ) async {
    ItemScreenArgs? openedThread;
    await pumpPins(
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
    await pumpPins(tester);

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
