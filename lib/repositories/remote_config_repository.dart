import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RemoteConfigRepository {
  RemoteConfigRepository({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const String _path =
      'https://raw.githubusercontent.com/Livinglist/Hacki/master/assets/';

  Future<Map<String, dynamic>> fetchRemoteConfig() async {
    if (kReleaseMode) {
      const String fileName = 'remote-config.json';
      final Response<dynamic> response = await _dio.get(
        '$_path$fileName',
      );
      final String data = response.data as String? ?? '';
      final Map<String, dynamic> json =
          jsonDecode(data) as Map<String, dynamic>;
      return json;
    } else {
      const String fileName = 'remote-config-dev.json';
      final String data = await rootBundle.loadString('assets/$fileName');
      final Map<String, dynamic> json =
          jsonDecode(data) as Map<String, dynamic>;
      return json;
    }
  }
}
