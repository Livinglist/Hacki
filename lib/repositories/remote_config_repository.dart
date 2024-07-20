import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigRepository {
  RemoteConfigRepository({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const String _path =
      'https://raw.githubusercontent.com/Livinglist/Hacki/master/assets/';

  Future<Map<String, dynamic>> fetchRemoteConfig() async {
    const String fileName =
        kReleaseMode ? 'remote-config.json' : 'remote-config-dev.json';
    final Response<dynamic> response = await _dio.get(
      '$_path$fileName',
    );
    final String data = response.data as String? ?? '';
    final Map<String, dynamic> json = jsonDecode(data) as Map<String, dynamic>;
    return json;
  }
}
