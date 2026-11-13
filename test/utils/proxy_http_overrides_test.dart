import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/utils/utils.dart';
import 'package:http/http.dart' as http;

/// Asks the HTTP stack of whichever isolate runs it which proxy it would
/// use for [url].
/// use for [url]. Proxies from environment variables of the machine running
/// the test are left out.
String _proxyFor(String url) => HttpClient.findProxyFromEnvironment(
  Uri.parse(url),
  environment: const <String, String>{},
);

void main() {
  group('ProxyHttpOverrides', () {
    late HttpServer proxyServer;
    late List<String> proxiedRequests;
    late NetworkProxy proxy;
    HttpOverrides? previousOverrides;

    setUp(() async {
      previousOverrides = HttpOverrides.current;
      HttpOverrides.global = ProxyHttpOverrides();

      // A minimal proxy: it records what it is asked to fetch and answers
      // on behalf of the destination.
      proxiedRequests = <String>[];
      proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
        ..listen((HttpRequest request) {
          proxiedRequests.add('${request.method} ${request.requestedUri}');
          request.response
            ..statusCode = request.method == 'CONNECT'
                ? HttpStatus.forbidden
                : HttpStatus.ok
            ..write('via proxy')
            ..close();
        });

      proxy = NetworkProxy(
        isEnabled: true,
        host: proxyServer.address.address,
        port: proxyServer.port,
      );
      ProxyHttpOverrides.proxy = proxy;
    });

    tearDown(() async {
      ProxyHttpOverrides.proxy = const NetworkProxy.none();
      HttpOverrides.global = previousOverrides;
      await proxyServer.close(force: true);
    });

    test('sends a dart:io request through the proxy', () async {
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(
        Uri.parse('http://news.ycombinator.invalid/item?id=1'),
      );
      final HttpClientResponse response = await request.close();
      final String body = await response.transform(utf8.decoder).join();
      client.close();

      expect(body, 'via proxy');
      expect(proxiedRequests, <String>[
        'GET http://news.ycombinator.invalid/item?id=1',
      ]);
    });

    test('sends a request of the http package through the proxy', () async {
      final http.Response response = await http.get(
        Uri.parse('http://hacker-news.invalid/v0/item/1.json'),
      );

      expect(response.body, 'via proxy');
      expect(proxiedRequests, <String>[
        'GET http://hacker-news.invalid/v0/item/1.json',
      ]);
    });

    test('sends a Dio request through the proxy', () async {
      final Response<String> response = await Dio().get<String>(
        'http://hn.algolia.invalid/api/v1/search',
      );

      expect(response.data, 'via proxy');
      expect(proxiedRequests, <String>[
        'GET http://hn.algolia.invalid/api/v1/search',
      ]);
    });

    test('tunnels an HTTPS request through the proxy', () async {
      final HttpClient client = HttpClient();

      // The fake proxy refuses the tunnel, what matters is that the client
      // asked it for one instead of connecting to the host itself.
      await expectLater(
        client.getUrl(Uri.parse('https://news.ycombinator.invalid/news')),
        throwsA(isA<HttpException>()),
      );
      client.close();

      expect(proxiedRequests, hasLength(1));
      expect(proxiedRequests.single, startsWith('CONNECT '));
      expect(proxiedRequests.single, contains('news.ycombinator.invalid'));
    });

    test('a client created before the proxy was set uses it too', () async {
      ProxyHttpOverrides.proxy = const NetworkProxy.none();
      final HttpClient client = HttpClient();
      ProxyHttpOverrides.proxy = proxy;

      final HttpClientRequest request = await client.getUrl(
        Uri.parse('http://news.ycombinator.invalid/'),
      );
      await (await request.close()).drain<void>();
      client.close();

      expect(proxiedRequests, <String>['GET http://news.ycombinator.invalid/']);
    });

    test(
      'fails instead of connecting directly when the proxy is down',
      () async {
        // A real destination that would answer if it were reached directly.
        final HttpServer destination = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        int directRequests = 0;
        destination.listen((HttpRequest request) {
          directRequests++;
          request.response.close();
        });
        addTearDown(() => destination.close(force: true));

        await proxyServer.close(force: true);

        final HttpClient client = HttpClient();
        await expectLater(
          client.getUrl(
            Uri.parse(
              'http://${destination.address.address}:${destination.port}',
            ),
          ),
          throwsA(isA<SocketException>()),
        );
        client.close();

        expect(directRequests, 0);
      },
    );

    test('connects directly once the proxy is turned off', () {
      ProxyHttpOverrides.proxy = NetworkProxy(
        isEnabled: false,
        host: proxy.host,
        port: proxy.port,
      );

      expect(_proxyFor('https://news.ycombinator.com'), 'DIRECT');
    });

    test('ignores an enabled proxy without a usable address', () {
      ProxyHttpOverrides.proxy = const NetworkProxy(
        isEnabled: true,
        host: '',
        port: null,
      );

      expect(_proxyFor('https://news.ycombinator.com'), 'DIRECT');
    });

    test('puts an IPv6 proxy host in brackets', () {
      ProxyHttpOverrides.proxy = const NetworkProxy(
        isEnabled: true,
        host: '::1',
        port: 8080,
      );

      expect(_proxyFor('https://news.ycombinator.com'), 'PROXY [::1]:8080');
    });

    group('computeWithProxy', () {
      test('a plain new isolate does not know about the proxy', () async {
        expect(
          await Isolate.run(() => _proxyFor('https://example.com')),
          'DIRECT',
        );
      });

      test('carries the proxy over to the new isolate', () async {
        expect(
          await computeWithProxy(_proxyFor, 'https://example.com'),
          'PROXY ${proxy.address}',
        );
      });

      test('carries over that the proxy is off', () async {
        ProxyHttpOverrides.proxy = const NetworkProxy.none();

        expect(
          await computeWithProxy(_proxyFor, 'https://example.com'),
          'DIRECT',
        );
      });
    });
  });
}
