import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/screens.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import 'support/golden_harness.dart';
import 'support/screen_fixtures.dart';

Widget _settings({bool signedIn = false}) {
  final GoldenTabCubit tabs = GoldenTabCubit();
  when(() => tabs.state).thenReturn(const TabState(tabs: StoryType.values));
  final GoldenAuthBloc auth = GoldenAuthBloc();
  when(() => auth.state).thenReturn(
    const AuthState.init().copyWith(
      isLoggedIn: signedIn,
      user: User.emptyWithId(signedIn ? 'alex' : ''),
    ),
  );
  return MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<TabCubit>.value(value: tabs),
      BlocProvider<AuthBloc>.value(value: auth),
    ],
    child: const SettingsScreen(),
  );
}

Widget _pins({bool empty = false}) {
  final GoldenPinCubit pins = GoldenPinCubit();
  when(() => pins.state).thenReturn(
    PinState.init().copyWith(
      pinnedStoriesIds: empty ? <int>[] : <int>[100],
      pinnedStories: empty ? <Story>[] : <Story>[const ScreenStory()],
    ),
  );
  return BlocProvider<PinCubit>.value(value: pins, child: const PinsScreen());
}

Widget _submit({bool loading = false}) {
  final GoldenSubmitCubit submit = GoldenSubmitCubit();
  when(() => submit.state).thenReturn(
    const SubmitState.init().copyWith(
      status: loading ? Status.inProgress : Status.idle,
    ),
  );
  return BlocProvider<SubmitCubit>.value(
    value: submit,
    child: const SubmitScreen(),
  );
}

Future<void> _scrollSettingsTo(WidgetTester tester, String label) async {
  final Finder target = find.text(label).first;
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _openSettings(WidgetTester tester, String label) async {
  await _scrollSettingsTo(tester, label);
  await tester.tap(find.text(label).first);
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  testGoldens('settings', <GoldenScenario>[
    GoldenScenario(
      'overview',
      _settings,
      setup: () async => seedScreenPreview(),
      covers: <String>{
        'lib/screens/settings/settings_screen.dart#SettingsScreen',
        'lib/screens/settings/settings_screen.dart#SettingsView',
      },
    ),
    GoldenScenario(
      'signed_in',
      () => _settings(signedIn: true),
      setup: () async => seedScreenPreview(),
    ),
    GoldenScenario(
      'story_appearance',
      _settings,
      setup: () async => seedScreenPreview(),
      exercise: (WidgetTester tester) =>
          _scrollSettingsTo(tester, 'Default tab bar'),
    ),
    GoldenScenario(
      'thread_preferences',
      _settings,
      setup: () async => seedScreenPreview(),
      exercise: (WidgetTester tester) => _scrollSettingsTo(tester, 'Thread'),
    ),
    GoldenScenario(
      'advanced',
      _settings,
      setup: () async => seedScreenPreview(),
      exercise: (WidgetTester tester) =>
          _scrollSettingsTo(tester, 'Accent Color'),
    ),
    GoldenScenario(
      'about_and_support',
      _settings,
      setup: () async => seedScreenPreview(),
      exercise: (WidgetTester tester) => _scrollSettingsTo(tester, 'About'),
    ),
    for (final String label in <String>[
      'Font',
      'Theme',
      'Accent Color',
      'Filter Keywords',
      'Export Favorites',
      'Import Favorites',
      'Clear Favorites',
      'Clear Cache',
      'Restore Default Settings',
    ])
      GoldenScenario(
        'dialog_${label.toLowerCase().replaceAll(' ', '_')}',
        _settings,
        setup: () async => seedScreenPreview(),
        exercise: (WidgetTester tester) => _openSettings(tester, label),
      ),
  ]);

  testGoldens('screens', <GoldenScenario>[
    const GoldenScenario(
      'submit_empty',
      _submit,
      covers: <String>{'lib/screens/submit/submit_screen.dart#SubmitScreen'},
    ),
    GoldenScenario(
      'submit_draft',
      _submit,
      exercise: (WidgetTester tester) async {
        await tester.enterText(
          find.byType(TextField).at(0),
          'Show HN: A quieter reader',
        );
        await tester.enterText(
          find.byType(TextField).at(2),
          'A small experiment in thoughtful defaults.',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        FocusManager.instance.primaryFocus?.unfocus();
      },
    ),
    GoldenScenario('submit_loading', () => _submit(loading: true)),
    GoldenScenario(
      'pins_empty',
      () => _pins(empty: true),
      covers: <String>{'lib/screens/pins/pins_screen.dart#PinsScreen'},
    ),
    GoldenScenario(
      'pins_populated',
      _pins,
      setup: () async => seedScreenPreview(),
    ),
    GoldenScenario(
      'pins_clear_confirmation',
      _pins,
      setup: () async => seedScreenPreview(),
      exercise: (WidgetTester tester) async {
        await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
        await tester.pump(const Duration(milliseconds: 400));
      },
    ),
    GoldenScenario(
      'share_story',
      () => const ShareScreen(ShareScreenArgs(item: ScreenStory())),
      setup: () async => seedScreenPreview(),
      covers: <String>{'lib/screens/share/share_screen.dart#ShareScreen'},
    ),
    GoldenScenario(
      'share_comment_with_parent',
      () => ShareScreen(
        ShareScreenArgs(item: ScreenComment(), parent: const ScreenStory()),
      ),
      setup: () async => seedScreenPreview(),
    ),
    GoldenScenario(
      'share_comment',
      () => ShareScreen(ShareScreenArgs(item: ScreenComment())),
      setup: () async => seedScreenPreview(),
    ),
    GoldenScenario(
      'qr_favorites',
      () => const QrCodeViewScreen(data: '100\n200\n300'),
      covers: <String>{
        'lib/screens/profile/qr_code_view_screen.dart#QrCodeViewScreen',
      },
    ),
    GoldenScenario(
      'qr_scanner',
      () => const QrCodeScannerScreen(),
      setup: installScreenPlatformFakes,
      covers: <String>{
        'lib/screens/profile/qr_code_scanner_screen.dart#QrCodeScannerScreen',
      },
    ),
    GoldenScenario(
      'qr_scanner_flash',
      () => const QrCodeScannerScreen(),
      setup: installScreenPlatformFakes,
      exercise: (WidgetTester tester) async {
        await tester.tap(find.byIcon(Icons.flash_on));
        await tester.pump();
      },
    ),
    GoldenScenario(
      'logs',
      () => const LogsScreen(),
      setup: installScreenPlatformFakes,
      covers: <String>{'lib/screens/logs/logs_screen.dart#LogsScreen'},
    ),
    GoldenScenario(
      'offline_web_view',
      () => const WebViewScreen(
        url: 'https://example.com/articles/a-calmer-internet',
      ),
      setup: installScreenPlatformFakes,
      covers: <String>{
        'lib/screens/web_view/web_view_screen.dart#WebViewScreen',
      },
    ),
    GoldenScenario(
      'offline_web_view_full_url',
      () => const WebViewScreen(
        url: 'https://example.com/articles/a-calmer-internet',
      ),
      setup: installScreenPlatformFakes,
      exercise: (WidgetTester tester) async {
        await tester.tap(find.text('example.com'));
        await tester.pump();
      },
    ),
  ]);
}
