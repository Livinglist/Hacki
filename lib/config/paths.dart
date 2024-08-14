import 'package:hacki/screens/screens.dart';

abstract class Paths {
  static const LogPaths log = LogPaths._();
  static const HomePaths home = HomePaths._();
  static const ItemPaths item = ItemPaths._();
  static const QrCodePaths qrCode = QrCodePaths._();
  static const WebViewPaths webView = WebViewPaths._();
}

class HomePaths with RootPaths {
  const HomePaths._();

  String get landing => rootPath('');
}

class ItemPaths with RootPaths {
  const ItemPaths._();

  String get landing => rootPath(ItemScreen.routeName);

  String get submit => rootPath(SubmitScreen.routeName);
}

class LogPaths with RootPaths {
  const LogPaths._();

  String get landing => rootPath(LogScreen.routeName);
}

class QrCodePaths with RootPaths {
  const QrCodePaths._();

  String get scanner => rootPath(QrCodeScannerScreen.routeName);

  String get viewer => rootPath(QrCodeViewScreen.routeName);
}

class WebViewPaths with RootPaths {
  const WebViewPaths._();

  String get landing => rootPath(WebViewScreen.routeName);
}

mixin RootPaths {
  String rootPath(String path) => '/$path';
}
