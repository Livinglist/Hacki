import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/dio/cached_response.dart';
import 'package:hacki/models/models.dart';

class StoryCacheInterceptor extends CacheInterceptor {
  StoryCacheInterceptor() : super(maxStale: AppDurations.threeMinutes);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String key = options.uri.toString();
    final bool isNewestUrl = key.contains(StoryType.latest.webPathParam);
    if (isNewestUrl) {
      handler.next(options);
    } else {
      await super.onRequest(options, handler);
    }
  }
}

class CacheInterceptor extends Interceptor with Loggable {
  CacheInterceptor({Duration? maxStale})
      : _maxStale = maxStale ?? _defaultMaxStale;

  static const Duration _defaultMaxStale = AppDurations.threeMinutes;
  static final Map<String, CachedResponse<dynamic>> _cache =
      <String, CachedResponse<dynamic>>{};

  final Duration _maxStale;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String key = options.uri.toString();
    final CachedResponse<dynamic>? cachedResponse = _cache[key];
    final bool isCacheValid = cachedResponse != null &&
        DateTime.now().difference(cachedResponse.setDateTime).inSeconds <
            _maxStale.inSeconds;

    logDebug('''
has cache: ${_cache.containsKey(key)}
is cache valid: $isCacheValid
url: $key''');

    if (isCacheValid) {
      return handler.resolve(cachedResponse);
    }

    return handler.next(options);
  }

  @override
  Future<void> onResponse(
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
  }

  @override
  String get logIdentifier => 'CacheInterceptor';
}
