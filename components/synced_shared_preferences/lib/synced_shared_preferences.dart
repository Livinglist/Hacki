import 'dart:async';

import 'package:flutter/services.dart';

class SyncedSharedPreferences {
  SyncedSharedPreferences._(
    MethodChannel methodChannel,
  ) : _channel = methodChannel;

  final MethodChannel _channel;

  static const String channel = 'synced_shared_preferences';

  static SyncedSharedPreferences instance = SyncedSharedPreferences._(
    const MethodChannel(channel),
  );

  Future<bool?> setBool({
    required String key,
    required bool val,
  }) async {
    return _channel.invokeMethod('setBool', <String, dynamic>{
      'key': key,
      'val': val,
    });
  }

  Future<bool?> getBool({
    required String key,
  }) async {
    return _channel.invokeMethod('getBool', <String, dynamic>{
      'key': key,
    });
  }

  Future<void> clearAll() async {
    return _channel.invokeMethod('clearAll', <String, dynamic>{});
  }
}
