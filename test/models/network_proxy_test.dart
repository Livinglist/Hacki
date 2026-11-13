import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/models/models.dart';

void main() {
  group('NetworkProxy', () {
    test('accepts host names and IP addresses', () {
      for (final String host in <String>[
        '127.0.0.1',
        'localhost',
        'proxy.example.com',
        'my-proxy',
        '::1',
        'fe80::1',
      ]) {
        expect(NetworkProxy.isValidHost(host), isTrue, reason: host);
      }
    });

    test('rejects hosts that are not a bare host name or address', () {
      for (final String host in <String>[
        '',
        ' ',
        'http://proxy.example.com',
        'proxy.example.com/path',
        'user@proxy.example.com',
        'proxy.example.com:8080',
        'proxy example',
        '-proxy',
        'proxy.',
      ]) {
        expect(NetworkProxy.isValidHost(host), isFalse, reason: host);
      }
    });

    test('accepts ports from 1 to 65535 only', () {
      expect(NetworkProxy.isValidPort(1), isTrue);
      expect(NetworkProxy.isValidPort(65535), isTrue);
      expect(NetworkProxy.isValidPort(0), isFalse);
      expect(NetworkProxy.isValidPort(65536), isFalse);
      expect(NetworkProxy.isValidPort(-1), isFalse);
      expect(NetworkProxy.isValidPort(null), isFalse);
    });

    test('normalizes what the user typed as host', () {
      expect(NetworkProxy.normalizeHost('  10.0.0.2 '), '10.0.0.2');
      expect(NetworkProxy.normalizeHost('[::1]'), '::1');
    });

    test('is active only when enabled with a valid address', () {
      expect(
        const NetworkProxy(
          isEnabled: true,
          host: '10.0.0.2',
          port: 8080,
        ).isActive,
        isTrue,
      );
      expect(
        const NetworkProxy(
          isEnabled: false,
          host: '10.0.0.2',
          port: 8080,
        ).isActive,
        isFalse,
      );
      expect(
        const NetworkProxy(
          isEnabled: true,
          host: '10.0.0.2',
          port: null,
        ).isActive,
        isFalse,
      );
      expect(
        const NetworkProxy(isEnabled: true, host: '', port: 8080).isActive,
        isFalse,
      );
      expect(const NetworkProxy.none().isActive, isFalse);
    });

    test('formats the address and the URL', () {
      const NetworkProxy ipv4 = NetworkProxy(
        isEnabled: true,
        host: '10.0.0.2',
        port: 8080,
      );
      const NetworkProxy ipv6 = NetworkProxy(
        isEnabled: true,
        host: '::1',
        port: 3128,
      );

      expect(ipv4.address, '10.0.0.2:8080');
      expect(ipv4.url, 'http://10.0.0.2:8080');
      expect(ipv6.address, '[::1]:3128');
      expect(ipv6.url, 'http://[::1]:3128');
    });
  });
}
