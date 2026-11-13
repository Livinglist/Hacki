import 'package:equatable/equatable.dart';

/// The HTTP proxy the user wants every connection of the app to go through.
class NetworkProxy extends Equatable {
  const NetworkProxy({
    required this.isEnabled,
    required this.host,
    required this.port,
  });

  const NetworkProxy.none() : isEnabled = false, host = '', port = null;

  static const int maxPort = 65535;

  static final RegExp _hostNameRegExp = RegExp(
    r'^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$',
  );

  /// Whether the user has turned the proxy on. The proxy is only used when
  /// it [isActive], which also needs a valid [host] and [port].
  final bool isEnabled;

  /// A host name or an IP address, without scheme and brackets.
  final String host;

  final int? port;

  /// Trims [input] and removes the brackets around an IPv6 address.
  static String normalizeHost(String input) {
    final String host = input.trim();
    if (host.length > 2 && host.startsWith('[') && host.endsWith(']')) {
      return host.substring(1, host.length - 1);
    }
    return host;
  }

  static bool isValidHost(String host) {
    if (host.contains(':')) {
      try {
        Uri.parseIPv6Address(host);
        return true;
      } on FormatException {
        return false;
      }
    }
    return _hostNameRegExp.hasMatch(host);
  }

  static bool isValidPort(int? port) =>
      port != null && port > 0 && port <= maxPort;

  bool get isValid => isValidHost(host) && isValidPort(port);

  /// Whether connections should go through this proxy.
  bool get isActive => isEnabled && isValid;

  /// The host and port, with an IPv6 address in brackets.
  String get address => host.contains(':') ? '[$host]:$port' : '$host:$port';

  String get url => 'http://$address';

  @override
  List<Object?> get props => <Object?>[isEnabled, host, port];
}
