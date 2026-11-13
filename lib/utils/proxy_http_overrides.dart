import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hacki/models/network_proxy.dart';

/// Sends every [HttpClient] of the current isolate through [proxy] while it
/// is active. That covers everything in the app that talks HTTP from Dart:
/// Dio, the `http` package, cached and plain network images.
///
/// The proxy is looked up for each request, so a change takes effect on the
/// next request without recreating any client. There is no direct fallback:
/// if the proxy can't be reached the request fails.
class ProxyHttpOverrides extends HttpOverrides {
  /// The proxy of the current isolate. Every isolate has its own, use
  /// [computeWithProxy] to carry it over to a new one.
  static NetworkProxy proxy = const NetworkProxy.none();

  /// Makes the current isolate connect through [proxy]. Meant for isolates
  /// that start without any [HttpOverrides].
  static void install(NetworkProxy proxy) {
    if (HttpOverrides.current is! ProxyHttpOverrides) {
      HttpOverrides.global = ProxyHttpOverrides();
    }
    ProxyHttpOverrides.proxy = proxy;
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    final NetworkProxy proxy = ProxyHttpOverrides.proxy;
    if (proxy.isActive) {
      return 'PROXY ${proxy.address}';
    }
    return super.findProxyFromEnvironment(url, environment);
  }
}

/// Like [compute], but the new isolate connects through the same proxy as
/// this one. A new isolate starts without [HttpOverrides], so anything it
/// fetched through plain [compute] would bypass the proxy.
Future<R> computeWithProxy<M, R>(
  ComputeCallback<M, R> callback,
  M message, {
  String? debugLabel,
}) {
  final NetworkProxy proxy = ProxyHttpOverrides.proxy;
  return compute<M, R>(
    (M message) {
      ProxyHttpOverrides.install(proxy);
      return callback(message);
    },
    message,
    debugLabel: debugLabel,
  );
}
