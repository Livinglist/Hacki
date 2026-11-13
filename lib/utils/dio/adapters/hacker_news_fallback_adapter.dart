import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Retries rate limited HTML requests through Hacki's optional VPS backend.
///
/// Working below Dio's interceptors preserves encoded forms and byte responses,
/// and keeps the backend API key out of request logs and requests to
/// Hacker News.
class HackerNewsFallbackAdapter implements HttpClientAdapter {
  HackerNewsFallbackAdapter({
    required HttpClientAdapter primary,
    HttpClientAdapter? backend,
    String backendUrl = const String.fromEnvironment('HACKI_BACKEND_URL'),
    String apiKey = const String.fromEnvironment('HACKI_BACKEND_API_KEY'),
  }) : _primary = primary,
       _backend = backend ?? IOHttpClientAdapter(),
       _backendUri = _parseBackend(backendUrl),
       _apiKey = apiKey;

  final HttpClientAdapter _primary;
  final HttpClientAdapter _backend;
  final Uri? _backendUri;
  final String _apiKey;

  static const Duration _timeout = Duration(seconds: 30);
  static const Set<int> _rateLimitedStatuses = <int>{
    HttpStatus.forbidden,
    HttpStatus.tooManyRequests,
    HttpStatus.serviceUnavailable,
  };
  static const Set<String> _strippedHeaders = <String>{
    'host',
    'connection',
    'proxy-authorization',
    'x-api-key',
  };

  static Uri? _parseBackend(String value) {
    final Uri? uri = Uri.tryParse(value);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }

    final bool loopback =
        uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '::1';
    if (uri.scheme != 'https' && !(uri.scheme == 'http' && loopback)) {
      return null;
    }
    return uri;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final Uri originalUri = options.uri;
    final Uri? backendUri = _backendUri;
    if (backendUri == null ||
        _apiKey.isEmpty ||
        originalUri.scheme != 'https' ||
        originalUri.host != 'news.ycombinator.com' ||
        originalUri.port != HttpClient.defaultHttpsPort) {
      return _primary.fetch(options, requestStream, cancelFuture);
    }

    // Dio may already have consumed a FormData or caller-supplied stream while
    // encoding it. Replay the resulting bytes instead of encoding it again.
    final Uint8List? requestBytes = requestStream == null
        ? null
        : await _readBytes(
            requestStream,
            timeout: _effectiveTimeout(options.sendTimeout),
          );
    final ResponseBody original = await _primary.fetch(
      options,
      _replay(requestBytes),
      cancelFuture,
    );
    if (!_rateLimitedStatuses.contains(original.statusCode)) {
      return original;
    }

    // Retain the original error response so existing API fallbacks and error
    // handling still work if the backend is unavailable or rate limited too.
    try {
      final Uint8List originalBytes = await _readBytes(
        original.stream,
        timeout: _effectiveTimeout(options.receiveTimeout),
      );
      original.stream = Stream<Uint8List>.value(originalBytes);
    } on Object catch (error, stackTrace) {
      // A broken rate-limit body must not prevent trying the VPS. Preserve its
      // stream error for the caller if the backend also fails.
      original.stream = Stream<Uint8List>.error(error, stackTrace);
    }
    if (options.cancelToken?.isCancelled ?? false) {
      throw options.cancelToken!.cancelError!;
    }

    final String prefix = backendUri.toString().replaceFirst(
      RegExp(r'/+$'),
      '',
    );
    final String path = originalUri.path.isEmpty ? '/' : originalUri.path;
    final String query = originalUri.hasQuery ? '?${originalUri.query}' : '';
    final Map<String, dynamic> headers = <String, dynamic>{
      for (final MapEntry<String, dynamic> header in options.headers.entries)
        if (!_strippedHeaders.contains(header.key.toLowerCase()))
          header.key: header.value,
      'X-API-Key': _apiKey,
    };
    final RequestOptions backendOptions = options.copyWith(
      baseUrl: '',
      path: '$prefix/v1/hn$path$query',
      queryParameters: <String, dynamic>{},
      headers: headers,
      // Never send the API key along a redirect, including an absolute HN URL.
      // Forms inspect the original Location/Set-Cookie response themselves.
      followRedirects: false,
      connectTimeout: _timeout,
      sendTimeout: _timeout,
      receiveTimeout: _timeout,
    );

    try {
      final ResponseBody response = await _backend.fetch(
        backendOptions,
        _replay(requestBytes),
        cancelFuture,
      );
      final Uint8List bytes = await _readBytes(response.stream);
      if (options.validateStatus(response.statusCode)) {
        response.stream = Stream<Uint8List>.value(bytes);
        return response;
      }
    } on Exception {
      if (options.cancelToken?.isCancelled ?? false) {
        throw options.cancelToken!.cancelError!;
      }
    }
    return original;
  }

  static Stream<Uint8List>? _replay(Uint8List? bytes) =>
      bytes == null ? null : Stream<Uint8List>.value(bytes);

  static Duration _effectiveTimeout(Duration? value) =>
      value != null && value > Duration.zero ? value : _timeout;

  static Future<Uint8List> _readBytes(
    Stream<Uint8List> stream, {
    Duration timeout = _timeout,
  }) async {
    final BytesBuilder builder = BytesBuilder(copy: false);
    await for (final Uint8List chunk in stream.timeout(timeout)) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  @override
  void close({bool force = false}) {
    _primary.close(force: force);
    _backend.close(force: force);
  }
}
