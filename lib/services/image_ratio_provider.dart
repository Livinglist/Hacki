import 'dart:async';

import 'package:flutter/material.dart';

abstract class ImageRatioProvider {
  static final Map<String, double> _cache = <String, double>{};

  static Future<double> getImageRatio(String imageUrl) async {
    final double? cachedValue = _cache[imageUrl];
    if (cachedValue != null) return cachedValue;
    final ImageProvider provider = NetworkImage(imageUrl);
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);

    final Completer<double> completer = Completer<double>();

    ImageStreamListener? listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      final double width = info.image.width.toDouble();
      final double height = info.image.height.toDouble();
      final double ratio = width / height;

      completer.complete(ratio);
      stream.removeListener(listener!);
    });

    stream.addListener(listener);
    final double result = await completer.future;
    _cache[imageUrl] = result;
    return result;
  }
}
