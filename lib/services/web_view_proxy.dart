import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/network_proxy.dart';

/// Makes the web views of the app connect through a proxy.
///
/// Web views do their own networking outside of Dart, so the proxy has to be
/// handed to the platform. The setting is app-wide on both platforms, which
/// means it covers every web view regardless of the plugin that created it.
class WebViewProxy with Loggable {
  static const Duration _timeout = Duration(seconds: 5);

  /// Returns false only when [proxy] is active but web views can't be made
  /// to use it.
  Future<bool> apply(NetworkProxy proxy) async {
    try {
      if (Platform.isAndroid &&
          !await WebViewFeature.isFeatureSupported(
            WebViewFeature.PROXY_OVERRIDE,
          ).timeout(_timeout)) {
        logInfo('web views on this device do not support a proxy.');
        return !proxy.isActive;
      }

      final ProxyController controller = ProxyController.instance();
      if (proxy.isActive) {
        await controller
            .setProxyOverride(
              settings: ProxySettings(
                proxyRules: <ProxyRule>[ProxyRule(url: proxy.url)],
              ),
            )
            .timeout(_timeout);
      } else {
        await controller.clearProxyOverride().timeout(_timeout);
      }
      return true;
    } catch (e) {
      logError('failed to update the proxy of web views: $e');
      return !proxy.isActive;
    }
  }

  @override
  String get logIdentifier => 'WebViewProxy';
}
