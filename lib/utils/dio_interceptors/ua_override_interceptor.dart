import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/extensions/extensions.dart';

class UAOverrideInterceptor extends Interceptor with Loggable {
  UAOverrideInterceptor({String? userAgent})
    : _userAgent =
          userAgent ??
          (Platform.isIOS || Platform.isMacOS
              ? Constants.iphoneUserAgent
              : Constants.androidUserAgent);

  final String _userAgent;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logInfo('user agent: $_userAgent');
    options.headers[HttpHeaders.userAgentHeader] = _userAgent;
    super.onRequest(options, handler);
  }

  @override
  String get logIdentifier => 'UAOverrideInterceptor';
}
