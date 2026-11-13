import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/utils/dio/adapters/hacker_news_fallback_adapter.dart';

void main() {
  late _RecordingAdapter primary;
  late _RecordingAdapter backend;
  late Dio dio;

  setUp(() {
    primary = _RecordingAdapter(
      () => ResponseBody.fromString('rate limited', 429),
    );
    backend = _RecordingAdapter(
      () => ResponseBody.fromString(
        '<html>from the VPS</html>',
        200,
        headers: <String, List<String>>{
          'content-type': <String>['text/html; charset=utf-8'],
          'x-hacki-cache': <String>['STALE'],
        },
      ),
    );
    dio = Dio()
      ..httpClientAdapter = HackerNewsFallbackAdapter(
        primary: primary,
        backend: backend,
        backendUrl: 'https://proxy.example/hacki/',
        apiKey: 'shared-app-key',
      );
  });

  tearDown(() => dio.close(force: true));

  for (final int status in <int>[403, 429, 503]) {
    test(
      'retries HN status $status once with the original path and query',
      () async {
        primary.respond = () => ResponseBody.fromString('limited', status);
        const String url =
            'https://news.ycombinator.com/item?id=42&p=2&x=a%2Bb&x=c';

        final Response<String> response = await dio.get<String>(url);

        expect(response.data, '<html>from the VPS</html>');
        expect(response.requestOptions.uri.toString(), url);
        expect(response.headers.value('x-hacki-cache'), 'STALE');
        expect(primary.requests, hasLength(1));
        expect(backend.requests, hasLength(1));
        expect(
          backend.requests.single.uri.toString(),
          'https://proxy.example/hacki/v1/hn/item?id=42&p=2&x=a%2Bb&x=c',
        );
        expect(backend.requests.single.headers['X-API-Key'], 'shared-app-key');
        expect(
          primary.requests.single.headers.containsKey('X-API-Key'),
          isFalse,
        );
        expect(
          response.requestOptions.headers.containsKey('X-API-Key'),
          isFalse,
        );
      },
    );
  }

  test(
    'preserves escaped paths and treats an empty root path as slash',
    () async {
      await dio.get<String>('https://news.ycombinator.com/a%2Fb?x=a%2Bb');
      await dio.get<String>('https://news.ycombinator.com?p=1');

      expect(
        backend.requests.first.uri.toString(),
        'https://proxy.example/hacki/v1/hn/a%2Fb?x=a%2Bb',
      );
      expect(
        backend.requests.last.uri.toString(),
        'https://proxy.example/hacki/v1/hn/?p=1',
      );
    },
  );

  test(
    'POST replays encoded form bytes and preserves cookies and 302',
    () async {
      backend.respond = () => ResponseBody.fromString(
        '',
        302,
        isRedirect: true,
        headers: <String, List<String>>{
          'location': <String>['/'],
          'set-cookie': <String>['user=hn-session; HttpOnly; Secure'],
        },
      );

      final Response<List<int>> response = await dio.post<List<int>>(
        'https://news.ycombinator.com/comment?next=1',
        data: <String, String>{'acct': 'alice', 'pw': 'a+b&c', 'text': 'Hi!'},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: <String, String>{'Cookie': 'user=hn-session'},
          responseType: ResponseType.bytes,
          validateStatus: (int? status) => status == 302,
        ),
      );

      expect(response.statusCode, 302);
      expect(response.headers.value('location'), '/');
      expect(response.headers.value('set-cookie'), contains('user=hn-session'));
      expect(backend.requests.single.method, 'POST');
      expect(backend.requests.single.headers['Cookie'], 'user=hn-session');
      expect(
        backend.requests.single.contentType,
        Headers.formUrlEncodedContentType,
      );
      expect(backend.bodies.single, primary.bodies.single);
      expect(
        utf8.decode(backend.bodies.single!),
        'acct=alice&pw=a%2Bb%26c&text=Hi%21',
      );
      expect(backend.requests.single.followRedirects, isFalse);
    },
  );

  test(
    'replays a single-subscription streaming body without re-encoding',
    () async {
      final StreamController<List<int>> body = StreamController<List<int>>()
        ..add(<int>[0, 255, 127])
        ..add(<int>[1, 2]);
      unawaited(body.close());

      await dio.request<String>(
        'https://news.ycombinator.com/r',
        data: body.stream,
        options: Options(
          method: 'PATCH',
          contentType: 'application/octet-stream',
        ),
      );

      expect(backend.requests.single.method, 'PATCH');
      expect(backend.bodies.single, <int>[0, 255, 127, 1, 2]);
      expect(backend.bodies.single, primary.bodies.single);
    },
  );

  test('byte responses retain their original bytes', () async {
    backend.respond = () => ResponseBody.fromBytes(<int>[0, 255, 127], 200);

    final Response<List<int>> response = await dio.get<List<int>>(
      'https://news.ycombinator.com/item?id=1',
      options: Options(responseType: ResponseType.bytes),
    );

    expect(response.data, <int>[0, 255, 127]);
  });

  test('tries the backend when the original rate-limit body fails', () async {
    primary.respond = () => ResponseBody(
      Stream<Uint8List>.error(const SocketException('HN body truncated')),
      429,
    );

    final Response<String> response = await dio.get<String>(
      'https://news.ycombinator.com/item?id=1',
    );

    expect(response.data, '<html>from the VPS</html>');
    expect(primary.requests, hasLength(1));
    expect(backend.requests, hasLength(1));
  });

  test('tries the backend when the original rate-limit body stalls', () async {
    bool cancelled = false;
    final StreamController<Uint8List> body = StreamController<Uint8List>(
      onCancel: () => cancelled = true,
    );
    primary.respond = () => ResponseBody(body.stream, 503);
    addTearDown(body.close);

    final Response<String> response = await dio.get<String>(
      'https://news.ycombinator.com/item?id=1',
      options: Options(receiveTimeout: const Duration(milliseconds: 20)),
    );

    expect(response.data, '<html>from the VPS</html>');
    expect(cancelled, isTrue);
    expect(primary.requests, hasLength(1));
    expect(backend.requests, hasLength(1));
  });

  test(
    'retains original headers and stream error when both sources fail',
    () async {
      const SocketException error = SocketException('HN body truncated');
      final StackTrace stackTrace = StackTrace.current;
      primary.respond = () => ResponseBody(
        Stream<Uint8List>.error(error, stackTrace),
        429,
        headers: <String, List<String>>{
          'retry-after': <String>['30'],
        },
      );
      backend.respond = () => throw const SocketException('VPS unavailable');
      final RequestOptions options = RequestOptions(
        path: 'https://news.ycombinator.com/item?id=1',
      );

      final ResponseBody response = await dio.httpClientAdapter.fetch(
        options,
        null,
        null,
      );

      expect(response.statusCode, 429);
      expect(response.headers['retry-after'], <String>['30']);
      Object? actualError;
      StackTrace? actualStackTrace;
      try {
        await response.stream.drain<void>();
      } on Object catch (caughtError, caughtStackTrace) {
        actualError = caughtError;
        actualStackTrace = caughtStackTrace;
      }
      expect(actualError, same(error));
      expect(actualStackTrace, same(stackTrace));
      expect(backend.requests, hasLength(1));
    },
  );

  test('Dio retains the original stream error if the backend fails', () async {
    const SocketException error = SocketException('HN body truncated');
    primary.respond = () => ResponseBody(Stream<Uint8List>.error(error), 429);
    backend.respond = () => ResponseBody.fromString('VPS rate limited', 503);

    await expectLater(
      dio.get<String>('https://news.ycombinator.com/item?id=1'),
      throwsA(
        isA<DioException>()
            .having(
              (DioException e) => e.error,
              'original stream error',
              same(error),
            )
            .having(
              (DioException e) => e.requestOptions.uri.host,
              'original host',
              'news.ycombinator.com',
            ),
      ),
    );
    expect(backend.requests, hasLength(1));
  });

  test(
    'keeps the original error if the backend fails or is rate limited',
    () async {
      for (final int status in <int>[401, 429, 503]) {
        backend.respond = () =>
            ResponseBody.fromString('backend error', status);

        await expectLater(
          dio.get<String>('https://news.ycombinator.com/'),
          throwsA(
            isA<DioException>()
                .having(
                  (DioException e) => e.response?.statusCode,
                  'status',
                  429,
                )
                .having(
                  (DioException e) => e.response?.data,
                  'original body',
                  'rate limited',
                ),
          ),
        );
      }
      expect(primary.requests, hasLength(3));
      expect(backend.requests, hasLength(3));
    },
  );

  test('keeps the original error on backend connection failure', () async {
    backend.respond = () => throw const SocketException('unavailable');

    await expectLater(
      dio.get<String>('https://news.ycombinator.com/'),
      throwsA(
        isA<DioException>()
            .having((DioException e) => e.response?.statusCode, 'status', 429)
            .having(
              (DioException e) => e.requestOptions.uri.host,
              'host',
              'news.ycombinator.com',
            ),
      ),
    );
  });

  test(
    'keeps the original error if the backend response stream fails',
    () async {
      backend.respond = () => ResponseBody(
        Stream<Uint8List>.error(const SocketException('disconnected')),
        200,
      );

      await expectLater(
        dio.get<String>('https://news.ycombinator.com/'),
        throwsA(
          isA<DioException>()
              .having((DioException e) => e.response?.statusCode, 'status', 429)
              .having(
                (DioException e) => e.response?.data,
                'original body',
                'rate limited',
              ),
        ),
      );
    },
  );

  test('does not forward the API key along a redirect', () async {
    backend.respond = () => ResponseBody.fromString(
      '',
      302,
      headers: <String, List<String>>{
        'location': <String>['https://another.example/'],
      },
    );

    await expectLater(
      dio.get<String>('https://news.ycombinator.com/'),
      throwsA(isA<DioException>()),
    );

    expect(backend.requests.single.followRedirects, isFalse);
    expect(backend.requests, hasLength(1));
    expect(primary.requests, hasLength(1));
  });

  test(
    'does not intercept successful requests or unrelated failures',
    () async {
      for (final int status in <int>[200, 404, 500]) {
        primary.respond = () => ResponseBody.fromString('direct', status);
        final Response<String> response = await dio.get<String>(
          'https://news.ycombinator.com/',
          options: Options(validateStatus: (_) => true),
        );
        expect(response.data, 'direct');
      }
      expect(backend.requests, isEmpty);
    },
  );

  test(
    'does not proxy API, external, insecure, or nonstandard HN origins',
    () async {
      for (final String url in <String>[
        'https://hacker-news.firebaseio.com/v0/item/1.json',
        'https://hn.algolia.com/api/v1/search',
        'https://news.ycombinator.com.evil.example/',
        'http://news.ycombinator.com/',
        'https://news.ycombinator.com:444/',
      ]) {
        await expectLater(dio.get<String>(url), throwsA(isA<DioException>()));
      }
      expect(backend.requests, isEmpty);
    },
  );

  test('missing key or invalid backend config disables fallback', () async {
    for (final (String, String) config in <(String, String)>[
      ('', 'key'),
      ('https://proxy.example', ''),
      ('http://proxy.example', 'key'),
      ('https://user:password@proxy.example', 'key'),
      ('https://proxy.example?key=unsafe', 'key'),
      ('https://proxy.example#fragment', 'key'),
    ]) {
      dio.httpClientAdapter = HackerNewsFallbackAdapter(
        primary: primary,
        backend: backend,
        backendUrl: config.$1,
        apiKey: config.$2,
      );
      await expectLater(
        dio.get<String>('https://news.ycombinator.com/'),
        throwsA(isA<DioException>()),
      );
    }
    expect(backend.requests, isEmpty);
  });

  test('permits HTTP on loopback for local development', () async {
    dio.httpClientAdapter = HackerNewsFallbackAdapter(
      primary: primary,
      backend: backend,
      backendUrl: 'http://127.0.0.1:8080',
      apiKey: 'key',
    );

    await dio.get<String>('https://news.ycombinator.com/');

    expect(
      backend.requests.single.uri.toString(),
      'http://127.0.0.1:8080/v1/hn/',
    );
  });

  test('honors cancellation before starting a fallback', () async {
    final CancelToken token = CancelToken();
    primary.respond = () {
      token.cancel('stopped');
      return ResponseBody.fromString('limited', 429);
    };

    await expectLater(
      dio.get<String>('https://news.ycombinator.com/', cancelToken: token),
      throwsA(
        isA<DioException>().having(
          (DioException e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
    expect(backend.requests, isEmpty);
  });

  test('honors cancellation when the original response body fails', () async {
    final CancelToken token = CancelToken();
    primary.respond = () {
      token.cancel('stopped');
      return ResponseBody(
        Stream<Uint8List>.error(const SocketException('HN body truncated')),
        429,
      );
    };
    final RequestOptions options = RequestOptions(
      path: 'https://news.ycombinator.com/',
      cancelToken: token,
    );

    await expectLater(
      dio.httpClientAdapter.fetch(options, null, token.whenCancel),
      throwsA(
        isA<DioException>().having(
          (DioException e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
    expect(backend.requests, isEmpty);
  });

  test('closes both adapters', () {
    dio.close(force: true);
    expect(primary.closed, isTrue);
    expect(backend.closed, isTrue);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.respond);

  ResponseBody Function() respond;
  final List<RequestOptions> requests = <RequestOptions>[];
  final List<List<int>?> bodies = <List<int>?>[];
  bool closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final List<int>? bytes = requestStream == null ? null : <int>[];
    if (requestStream != null) {
      await for (final Uint8List chunk in requestStream) {
        bytes!.addAll(chunk);
      }
    }
    bodies.add(bytes);
    return respond();
  }

  @override
  void close({bool force = false}) => closed = true;
}
