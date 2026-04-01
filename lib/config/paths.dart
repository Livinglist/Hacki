import 'package:hacki/screens/screens.dart';

abstract final class Paths {
  static const LogsPaths logs = LogsPaths._();
  static const HomePaths home = HomePaths._();
  static const ItemPaths item = ItemPaths._();
  static const SharePaths share = SharePaths._();
  static const QrCodePaths qrCode = QrCodePaths._();
  static const WebViewPaths webView = WebViewPaths._();
  static const SettingsPaths settings = SettingsPaths._();
}

class HomePaths with RootPaths {
  const HomePaths._();

  String get landing => rootPath('');
}

class ItemPaths with RootPaths {
  const ItemPaths._();

  String get landing => rootPath(ItemScreen.routeName);

  String get submit => rootPath(SubmitScreen.routeName);

  String get settings => '$landing$settingsSegment';

  static const String settingsSegment = '/${SettingsScreen.routeName}';
}

class SettingsPaths with RootPaths {
  const SettingsPaths._();

  String get landing => rootPath(SettingsScreen.routeName);
}

class SharePaths with RootPaths {
  const SharePaths._();

  String get landing => rootPath(ShareScreen.routeName);
}

class LogsPaths with RootPaths {
  const LogsPaths._();

  String get landing => rootPath(LogsScreen.routeName);
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
