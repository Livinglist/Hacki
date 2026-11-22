import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/pins/pins_screen.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/utils/haptic_feedback_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockPinCubit extends MockCubit<PinState> implements PinCubit {}

class _MockPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

final Story _story = Story.fromJson(const <String, dynamic>{
  'id': 1,
  'title': 'A pinned story',
});

void main() {
  late _MockPinCubit pinCubit;
  late StreamController<PinState> pinChanges;
  late List<String> haptics;
  late bool wasHapticsEnabled;

  setUp(() {
    pinCubit = _MockPinCubit();
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

  Future<void> pumpPins(WidgetTester tester, {bool hasPins = true}) async {
    whenListen(
      pinCubit,
      pinChanges.stream,
      initialState: PinState.init().copyWith(
        pinnedStoriesIds: hasPins ? <int>[_story.id] : <int>[],
        pinnedStories: hasPins ? <Story>[_story] : <Story>[],
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
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<PinCubit>.value(value: pinCubit),
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

  testWidgets('shows pinned stories instead of the empty message', (
    WidgetTester tester,
  ) async {
    await pumpPins(tester);

    expect(find.byType(StoryTile), findsOneWidget);
    expect(
      find.byKey(ValueKey<String>('${_story.id}-PinnedStoryTile')),
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
}
