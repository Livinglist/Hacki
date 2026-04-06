import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hacki/extensions/extensions.dart';

class UARotationInterceptor extends Interceptor with Loggable {
  static const List<String> _iosUserAgents = <String>[
    'Mozilla/5.0 (iPhone; CPU iPhone OS 26_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) EdgiOS/146.0.3856.85 Version/26.0 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 26_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Brave/1 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.47 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/149.0 Mobile/15E148 Safari/605.1.15',
  ];
  static const List<String> _androidUserAgents = <String>[
    'Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.7680.178 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 16; LM-Q710(FGN)) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.7680.178 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 16; LM-X420) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.7680.178 Mobile Safari/537.36',
    'Mozilla/5.0 (Android 16; Mobile; rv:68.0) Gecko/68.0 Firefox/149.0',
    'Mozilla/5.0 (Android 16; Mobile; LG-M255; rv:149.0) Gecko/149.0 Firefox/149.0',
    'Mozilla/5.0 (Linux; Android 15; SM-S931B Build/AP3A.240905.015.A2; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/127.0.6533.103 Mobile Safari/537.36',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String? userAgent = Platform.isIOS || Platform.isMacOS
        ? _iosUserAgents.randomlyPicked
        : _androidUserAgents.randomlyPicked;
    logInfo('user agent: $userAgent');
    options.headers[HttpHeaders.userAgentHeader] = userAgent;
    super.onRequest(options, handler);
  }

  @override
  String get logIdentifier => 'UARotationInterceptor';
}
