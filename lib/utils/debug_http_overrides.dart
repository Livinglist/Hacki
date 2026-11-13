import 'dart:io';

import 'package:hacki/utils/proxy_http_overrides.dart';

class DebugHttpOverrides extends ProxyHttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
