import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/extensions/extensions.dart';

/// Uses one stable browser UA for the process.
/// Rotating UAs per request looks like a bot to HN/Cloudflare and
/// is a common cause of extra 429s compared with URLSession.
class UARotationInterceptor extends Interceptor with Loggable {
  UARotationInterceptor()
    : _userAgent = Platform.isIOS || Platform.isMacOS
          ? Constants.iphoneUserAgent
          : _androidUserAgent;

  static const String _androidUserAgent =
      'Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.7680.178 Mobile Safari/537.36';

  final String _userAgent;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logInfo('user agent: $_userAgent');
    options.headers[HttpHeaders.userAgentHeader] = _userAgent;
    super.onRequest(options, handler);
  }

  @override
  String get logIdentifier => 'UARotationInterceptor';
}
