import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hacki/config/locator.dart';
import 'package:logger/logger.dart';

abstract final class WidgetUtils {
  static double? _cachedPreferredCacheExtent;

  static Logger get _logger => locator.get<Logger>();

  static double calculateCacheExtent(BuildContext context) {
    if (_cachedPreferredCacheExtent != null) {
      return _cachedPreferredCacheExtent!;
    }
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double screenHeight = mediaQuery.size.height;
    final double devicePixelRatio = mediaQuery.devicePixelRatio;

    double cacheExtent = screenHeight * 2;

    if (Platform.isAndroid) {
      cacheExtent *= _ramMultiplier();
    }

    if (devicePixelRatio >= 3.0) {
      cacheExtent *= 0.75;
    } else if (devicePixelRatio >= 2.0) {
      cacheExtent *= 0.9;
    }

    final double result = cacheExtent.clamp(400, 2000);
    _cachedPreferredCacheExtent = result;
    _logger.i('[WidgetUtils]: preferred cache extent: $result');
    return result;
  }

  static double _ramMultiplier() {
    try {
      final File memFile = File('/proc/meminfo');
      if (!memFile.existsSync()) return 1;

      final List<String> lines = memFile.readAsLinesSync();
      final String totalLine = lines.firstWhere(
        (String l) => l.startsWith('MemTotal'),
        orElse: () => '',
      );
      if (totalLine.isEmpty) return 1;

      final int kb = int.tryParse(
            totalLine.replaceAll(RegExp('[^0-9]'), ''),
          ) ??
          0;
      final double gb = kb / (1024 * 1024);

      if (gb >= 8) return 1.3;
      if (gb >= 6) return 1.15;
      if (gb >= 4) return 1;
      return 0.75;
    } catch (_) {
      return 1;
    }
  }
}
