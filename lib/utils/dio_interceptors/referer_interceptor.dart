import 'dart:io';

import 'package:dio/dio.dart';

class RefererInterceptor extends Interceptor {
  String? _lastUrl;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_lastUrl != null) {
      options.headers[HttpHeaders.refererHeader] = _lastUrl;
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _lastUrl = response.requestOptions.uri.toString();
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    /// Don't update _lastUrl on failure, keep the last successful one
    super.onError(err, handler);
  }
}
