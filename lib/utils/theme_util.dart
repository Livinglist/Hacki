import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/services.dart';
import 'package:hacki/styles/styles.dart';

abstract class ThemeUtil {
  static Future<void> updateStatusBarSetting(
    Brightness brightness,
    AdaptiveThemeMode? mode,
  ) async {
    if (Platform.isAndroid) {
      switch (mode) {
        case AdaptiveThemeMode.light:
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.dark,
              statusBarColor: Palette.transparent,
            ),
          );
        case AdaptiveThemeMode.dark:
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.light,
              statusBarColor: Palette.transparent,
            ),
          );
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
            case Brightness.dark:
              SystemChrome.setSystemUIOverlayStyle(
                const SystemUiOverlayStyle(
                  statusBarBrightness: Brightness.light,
                  statusBarIconBrightness: Brightness.light,
                  statusBarColor: Palette.transparent,
                ),
              );
          }
      }
    } else {
      switch (mode) {
        case AdaptiveThemeMode.light:
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.light,
              statusBarColor: Palette.transparent,
            ),
          );
        case AdaptiveThemeMode.dark:
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.dark,
              statusBarColor: Palette.transparent,
            ),
          );
        case AdaptiveThemeMode.system:
        case null:
          switch (brightness) {
            case Brightness.light:
              SystemChrome.setSystemUIOverlayStyle(
                const SystemUiOverlayStyle(
                  statusBarBrightness: Brightness.light,
                  statusBarIconBrightness: Brightness.light,
                  statusBarColor: Palette.transparent,
                ),
              );
            case Brightness.dark:
              SystemChrome.setSystemUIOverlayStyle(
                const SystemUiOverlayStyle(
                  statusBarBrightness: Brightness.dark,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarColor: Palette.transparent,
                ),
              );
          }
      }
    }
  }
}
