import 'dart:convert';

import 'package:dio/dio.dart';

class RemoteConfigRepository {
  RemoteConfigRepository({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<Map<String, dynamic>> fetchRemoteConfig() async {
    final Response<dynamic> response = await _dio.get(
      'https://raw.githubusercontent.com/Livinglist/Hacki/master/assets/remote-config.json',
    );
    final String data = response.data as String? ?? '';
    final Map<String, dynamic> json = jsonDecode(data) as Map<String, dynamic>;
    return json;
  }
}
