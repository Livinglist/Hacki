import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/settings/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:logger/logger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';
import '../../golden_test_utils.dart';

const NetworkProxy _proxy = NetworkProxy(
  isEnabled: true,
  host: '10.0.0.2',
  port: 8080,
);

void main() {
  late MockWebViewProxy webViewProxy;
  late NetworkProxyService service;

  setUpAll(() {
    registerFallbackValue(const NetworkProxy.none());
    locator.registerSingleton<Logger>(MockLogger());
  });

  tearDownAll(locator.reset);

  setUp(() {
    ProxyHttpOverrides.proxy = const NetworkProxy.none();
    webViewProxy = MockWebViewProxy();
    when(() => webViewProxy.apply(any())).thenAnswer((_) async => true);

    // Storage kept in memory: futures of the real one complete outside of
    // the fake clock widget tests run in.
    NetworkProxy stored = const NetworkProxy.none();
    final MockPreferenceRepository preferenceRepository =
        MockPreferenceRepository();
    when(
      () => preferenceRepository.networkProxy,
    ).thenAnswer((_) async => stored);
    when(() => preferenceRepository.updateNetworkProxy(any())).thenAnswer((
      Invocation invocation,
    ) async {
      stored = invocation.positionalArguments.single as NetworkProxy;
    });

    service = NetworkProxyService(
      preferenceRepository: preferenceRepository,
      webViewProxy: webViewProxy,
    );
  });

  tearDown(() => ProxyHttpOverrides.proxy = const NetworkProxy.none());

  /// Pumps the tile on top of the real cubit and service, inside a router
  /// like the one the dialogs of the app are closed with.
  Future<void> pumpTile(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: ProxyListTile()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider<NetworkProxyCubit>(
        create: (_) => NetworkProxyCubit(networkProxyService: service),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: AppTheme.theme(
            ColorScheme.fromSeed(
              brightness: brightness,
              seedColor: Palette.deepOrange,
              dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
            ),
            Font.robotoSlab,
            isDarkModeEnabled: brightness == Brightness.dark,
            isTrueDarkModeEnabled: false,
          ),
          builder: (BuildContext context, Widget? child) =>
              RepaintBoundary(key: goldenKey, child: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.byType(ProxyListTile));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  group('ProxyListTile', () {
    testWidgets('shows only its title while no proxy is used', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester);

      expect(find.text('Proxy'), findsOneWidget);
      expect(tester.widget<ListTile>(find.byType(ListTile)).subtitle, isNull);
    });

    testWidgets('shows the address of the proxy in use', (
      WidgetTester tester,
    ) async {
      await service.update(_proxy);
      await pumpTile(tester);

      expect(find.text('10.0.0.2:8080'), findsOneWidget);
    });

    testWidgets('opens the dialog filled with the current proxy', (
      WidgetTester tester,
    ) async {
      await service.update(_proxy);
      await pumpTile(tester);
      await openDialog(tester);

      expect(find.byType(ProxySettingsDialog), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      expect(
        tester.widget<TextField>(field('Host')).controller?.text,
        '10.0.0.2',
      );
      expect(tester.widget<TextField>(field('Port')).controller?.text, '8080');
    });
  });

  group('ProxySettingsDialog', () {
    testWidgets('saving puts every connection on the proxy', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester);
      await openDialog(tester);

      await tester.tap(find.byType(SwitchListTile));
      await tester.enterText(field('Host'), ' 10.0.0.2 ');
      await tester.enterText(field('Port'), '8080');
      await save(tester);

      expect(ProxyHttpOverrides.proxy, _proxy);
      verify(() => webViewProxy.apply(_proxy)).called(1);
      expect(find.byType(ProxySettingsDialog), findsNothing);
      expect(
        find.text('Connections now go through 10.0.0.2:8080.'),
        findsOneWidget,
      );
      expect(find.text('10.0.0.2:8080'), findsOneWidget);
    });

    testWidgets('asks for host and port before turning the proxy on', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester);
      await openDialog(tester);

      await tester.tap(find.byType(SwitchListTile));
      await save(tester);

      expect(find.text('Enter a host name or an IP address.'), findsOneWidget);
      expect(find.text('Enter a port from 1 to 65535.'), findsOneWidget);
      expect(find.byType(ProxySettingsDialog), findsOneWidget);
      expect(ProxyHttpOverrides.proxy.isActive, isFalse);
      verifyNever(() => webViewProxy.apply(any()));
    });

    testWidgets('rejects a URL as host and a port that is out of range', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester);
      await openDialog(tester);

      await tester.tap(find.byType(SwitchListTile));
      await tester.enterText(field('Host'), 'http://10.0.0.2');
      await tester.enterText(field('Port'), '70000');
      await save(tester);

      expect(find.text('Enter a host name or an IP address.'), findsOneWidget);
      expect(find.text('Enter a port from 1 to 65535.'), findsOneWidget);
      expect(ProxyHttpOverrides.proxy.isActive, isFalse);
    });

    testWidgets('accepts an IPv6 address typed with brackets', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester);
      await openDialog(tester);

      await tester.tap(find.byType(SwitchListTile));
      await tester.enterText(field('Host'), '[::1]');
      await tester.enterText(field('Port'), '3128');
      await save(tester);

      expect(
        ProxyHttpOverrides.proxy,
        const NetworkProxy(isEnabled: true, host: '::1', port: 3128),
      );
      expect(find.text('[::1]:3128'), findsOneWidget);
    });

    testWidgets('turning it off stops using the proxy but keeps the address', (
      WidgetTester tester,
    ) async {
      await service.update(_proxy);
      clearInteractions(webViewProxy);
      await pumpTile(tester);
      await openDialog(tester);

      await tester.tap(find.byType(SwitchListTile));
      await save(tester);

      const NetworkProxy off = NetworkProxy(
        isEnabled: false,
        host: '10.0.0.2',
        port: 8080,
      );
      expect(ProxyHttpOverrides.proxy, off);
      verify(() => webViewProxy.apply(off)).called(1);
      expect(find.text('Proxy is off.'), findsOneWidget);
      expect(find.text('10.0.0.2:8080'), findsNothing);

      await openDialog(tester);
      expect(
        tester.widget<TextField>(field('Host')).controller?.text,
        '10.0.0.2',
      );
    });

    testWidgets('can be turned off without a valid address', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester);
      await openDialog(tester);

      await save(tester);

      expect(find.byType(ProxySettingsDialog), findsNothing);
      expect(find.text('Proxy is off.'), findsOneWidget);
    });

    testWidgets('cancel changes nothing', (WidgetTester tester) async {
      await service.update(_proxy);
      clearInteractions(webViewProxy);
      await pumpTile(tester);
      await openDialog(tester);

      await tester.tap(find.byType(SwitchListTile));
      await tester.enterText(field('Host'), '192.168.1.1');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(ProxySettingsDialog), findsNothing);
      expect(ProxyHttpOverrides.proxy, _proxy);
      verifyNever(() => webViewProxy.apply(any()));
    });

    testWidgets('says so when web views cannot use the proxy', (
      WidgetTester tester,
    ) async {
      when(() => webViewProxy.apply(any())).thenAnswer((_) async => false);
      await pumpTile(tester);
      await openDialog(tester);

      await tester.tap(find.byType(SwitchListTile));
      await tester.enterText(field('Host'), '10.0.0.2');
      await tester.enterText(field('Port'), '8080');
      await save(tester);

      expect(find.textContaining('except for web views'), findsOneWidget);
    });

    testWidgets('golden: proxy in use', (WidgetTester tester) async {
      await service.update(_proxy);
      await pumpTile(tester);
      await openDialog(tester);

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/proxy_settings_dialog.png'),
      );
    });

    testWidgets('golden: missing address, dark theme', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester, brightness: Brightness.dark);
      await openDialog(tester);
      await tester.tap(find.byType(SwitchListTile));
      await save(tester);

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/proxy_settings_dialog_errors_dark.png'),
      );
    });
  });
}
