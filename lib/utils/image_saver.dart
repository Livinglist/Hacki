import 'package:flutter/services.dart';

class ImageSaver {
  static const MethodChannel _channel = MethodChannel('image_saver');

  static Future<bool> saveImage(
    Uint8List bytes, {
    String name = 'image',
  }) async {
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('saveImage', <String, Object>{
        'bytes': bytes,
        'name': name,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
