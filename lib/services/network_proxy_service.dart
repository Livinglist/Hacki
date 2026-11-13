import 'package:hacki/config/locator.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/network_proxy.dart';
import 'package:hacki/repositories/preference_repository.dart';
import 'package:hacki/services/web_view_proxy.dart';
import 'package:hacki/utils/proxy_http_overrides.dart';

/// Keeps every connection of the app on the proxy chosen by the user.
///
/// [init] has to complete before the first request is made, otherwise that
/// request would go out directly.
class NetworkProxyService with Loggable {
  NetworkProxyService({
    PreferenceRepository? preferenceRepository,
    WebViewProxy? webViewProxy,
  }) : _preferenceRepository =
           preferenceRepository ?? locator.get<PreferenceRepository>(),
       _webViewProxy = webViewProxy ?? WebViewProxy();

  final PreferenceRepository _preferenceRepository;
  final WebViewProxy _webViewProxy;

  NetworkProxy _proxy = const NetworkProxy.none();
  bool _isAppliedToWebViews = true;

  NetworkProxy get proxy => _proxy;

  /// False when the proxy is active but web views can't use it.
  bool get isAppliedToWebViews => _isAppliedToWebViews;

  /// Loads the stored proxy and starts using it.
  Future<void> init() async {
    try {
      _proxy = await _preferenceRepository.networkProxy;
    } catch (e) {
      logError('failed to load the proxy: $e');
    }

    ProxyHttpOverrides.proxy = _proxy;

    // Web views start without a proxy, so there is nothing to clear.
    if (_proxy.isActive) {
      _isAppliedToWebViews = await _webViewProxy.apply(_proxy);
    }
  }

  /// Stores [proxy] and uses it for every connection made from now on.
  Future<void> update(NetworkProxy proxy) async {
    _proxy = proxy;
    ProxyHttpOverrides.proxy = proxy;

    try {
      await _preferenceRepository.updateNetworkProxy(proxy);
    } catch (e) {
      logError('failed to store the proxy: $e');
    }

    _isAppliedToWebViews = await _webViewProxy.apply(proxy);
  }

  @override
  String get logIdentifier => 'NetworkProxyService';
}
