import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/utils/service_exception.dart';

class PostableRepository {
  PostableRepository({
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final Dio _dio;

  @protected
  Future<bool> performDefaultPost(
    Uri uri,
    PostDataMixin data, {
    String? cookie,
    bool Function(String?)? validateLocation,
  }) async {
    try {
      final Response<void> response = await performPost<void>(
        uri,
        data,
        cookie: cookie,
        validateStatus: (int? status) => status == HttpStatus.found,
      );

      if (validateLocation != null) {
        return validateLocation(response.headers.value('location'));
      }

      return true;
    } on ServiceException {
      return false;
    }
  }

  @protected
  Future<Response<T>> performPost<T>(
    Uri uri,
    PostDataMixin data, {
    String? cookie,
    ResponseType? responseType,
    bool Function(int?)? validateStatus,
  }) async {
    try {
      return await _dio.postUri<T>(
        uri,
        data: data.toJson(),
        options: Options(
          headers: <String, dynamic>{if (cookie != null) 'cookie': cookie},
          responseType: responseType,
          contentType: 'application/x-www-form-urlencoded',
          validateStatus: validateStatus,
        ),
      );
    } on DioError catch (e) {
      throw ServiceException(e.message);
    }
  }
}
