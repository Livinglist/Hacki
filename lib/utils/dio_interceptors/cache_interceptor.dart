import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/dio/cached_response.dart';

class CacheInterceptor extends InterceptorsWrapper {
  CacheInterceptor()
      : super(
          onResponse: (
            Response<dynamic> response,
            ResponseInterceptorHandler handler,
          ) async {
            final String key = response.requestOptions.uri.toString();

            if (response.statusCode == HttpStatus.ok) {
              final CachedResponse<dynamic> cachedResponse =
                  CachedResponse<dynamic>.fromResponse(response);
              _cache[key] = cachedResponse;
            }

            return handler.next(response);
          },
          onRequest: (
            RequestOptions options,
            RequestInterceptorHandler handler,
          ) async {
            final String key = options.uri.toString();
            final CachedResponse<dynamic>? cachedResponse = _cache[key];

            if (cachedResponse != null &&
                DateTime.now()
                        .difference(cachedResponse.setDateTime)
                        .inSeconds <
                    _delay.inSeconds) {
              return handler.resolve(cachedResponse);
            }

            return handler.next(options);
          },
        );

  static const Duration _delay = AppDurations.oneMinute;
  static final Map<String, CachedResponse<dynamic>> _cache =
      <String, CachedResponse<dynamic>>{};
}
