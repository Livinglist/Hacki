import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:hacki/styles/styles.dart';

abstract class ThemeUtil {
  static Future<void> updateAndroidStatusBarSetting(
    Brightness brightness,
    AdaptiveThemeMode? mode,
  ) async {
    if (Platform.isAndroid == false) return;

    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    final int sdk = androidInfo.version.sdkInt;

    /// Temp fix for this issue:
    /// https://github.com/flutter/flutter/issues/119465
    if (sdk > 28) return;
    switch (mode) {
      case AdaptiveThemeMode.light:
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: Palette.transparent,
          ),
        );
        break;
      case AdaptiveThemeMode.dark:
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Palette.transparent,
          ),
        );
        break;
      case AdaptiveThemeMode.system:
      case null:
        switch (brightness) {
          case Brightness.light:
            SystemChrome.setSystemUIOverlayStyle(
              const SystemUiOverlayStyle(
                statusBarBrightness: Brightness.dark,
                statusBarIconBrightness: Brightness.dark,
                statusBarColor: Palette.transparent,
              ),
            );
            break;
          case Brightness.dark:
            SystemChrome.setSystemUIOverlayStyle(
              const SystemUiOverlayStyle(
                statusBarBrightness: Brightness.light,
                statusBarIconBrightness: Brightness.light,
                statusBarColor: Palette.transparent,
              ),
            );
            break;
        }
        break;
    }
  }
}
