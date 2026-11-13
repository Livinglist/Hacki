import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/utils.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/mocks.dart';

const NetworkProxy _proxy = NetworkProxy(
  isEnabled: true,
  host: '10.0.0.2',
  port: 8080,
);

void main() {
  late MockWebViewProxy webViewProxy;

  /// A service on top of the real storage, as after a fresh app start.
  NetworkProxyService buildService() => NetworkProxyService(
    preferenceRepository: PreferenceRepository(),
    webViewProxy: webViewProxy,
  );

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(const NetworkProxy.none());
    locator.registerSingleton<Logger>(MockLogger());
  });

  tearDownAll(locator.reset);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ProxyHttpOverrides.proxy = const NetworkProxy.none();
    webViewProxy = MockWebViewProxy();
    when(() => webViewProxy.apply(any())).thenAnswer((_) async => true);
  });

  tearDown(() => ProxyHttpOverrides.proxy = const NetworkProxy.none());

  group('NetworkProxyService', () {
    test('has no proxy when none was ever set', () async {
      final NetworkProxyService service = buildService();
      await service.init();

      expect(service.proxy, const NetworkProxy.none());
      expect(service.isAppliedToWebViews, isTrue);
      expect(ProxyHttpOverrides.proxy.isActive, isFalse);
      verifyNever(() => webViewProxy.apply(any()));
    });

    test(
      'update applies the proxy to Dart connections and web views',
      () async {
        final NetworkProxyService service = buildService();
        await service.init();

        await service.update(_proxy);

        expect(service.proxy, _proxy);
        expect(ProxyHttpOverrides.proxy, _proxy);
        verify(() => webViewProxy.apply(_proxy)).called(1);
      },
    );

    test('Dart connections are on the proxy before anything is awaited', () {
      final Completer<bool> webViews = Completer<bool>();
      when(() => webViewProxy.apply(any())).thenAnswer((_) => webViews.future);

      unawaited(buildService().update(_proxy));

      expect(ProxyHttpOverrides.proxy, _proxy);
      webViews.complete(true);
    });

    test('the proxy is back in place after the app restarts', () async {
      await buildService().update(_proxy);
      ProxyHttpOverrides.proxy = const NetworkProxy.none();
      clearInteractions(webViewProxy);

      final NetworkProxyService restarted = buildService();
      await restarted.init();

      expect(restarted.proxy, _proxy);
      expect(ProxyHttpOverrides.proxy, _proxy);
      verify(() => webViewProxy.apply(_proxy)).called(1);
    });

    test(
      'turning the proxy off keeps the address and clears web views',
      () async {
        const NetworkProxy off = NetworkProxy(
          isEnabled: false,
          host: '10.0.0.2',
          port: 8080,
        );
        final NetworkProxyService service = buildService();
        await service.update(_proxy);

        await service.update(off);

        expect(ProxyHttpOverrides.proxy.isActive, isFalse);
        verify(() => webViewProxy.apply(off)).called(1);

        final NetworkProxyService restarted = buildService();
        await restarted.init();
        expect(restarted.proxy, off);
      },
    );

    test('a proxy stored without port is read back without port', () async {
      const NetworkProxy incomplete = NetworkProxy(
        isEnabled: false,
        host: 'proxy.example.com',
        port: null,
      );
      await buildService().update(_proxy);
      await buildService().update(incomplete);

      final NetworkProxyService restarted = buildService();
      await restarted.init();

      expect(restarted.proxy, incomplete);
    });

    test('reports when web views cannot use the proxy', () async {
      when(() => webViewProxy.apply(any())).thenAnswer((_) async => false);
      final NetworkProxyService service = buildService();

      await service.update(_proxy);

      expect(service.isAppliedToWebViews, isFalse);
      expect(ProxyHttpOverrides.proxy, _proxy);
    });

    test('still applies the proxy when it cannot be stored', () async {
      final MockPreferenceRepository preferenceRepository =
          MockPreferenceRepository();
      when(
        () => preferenceRepository.updateNetworkProxy(any()),
      ).thenThrow(Exception('disk full'));
      final NetworkProxyService service = NetworkProxyService(
        preferenceRepository: preferenceRepository,
        webViewProxy: webViewProxy,
      );

      await service.update(_proxy);

      expect(ProxyHttpOverrides.proxy, _proxy);
      verify(() => webViewProxy.apply(_proxy)).called(1);
    });
  });
}
