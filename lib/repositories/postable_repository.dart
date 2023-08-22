import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/auth_repository.dart';
import 'package:hacki/repositories/post_repository.dart';
import 'package:hacki/utils/service_exception.dart';

/// [PostableRepository] is solely for hosting functionalities shared between
/// [AuthRepository] and [PostRepository].
class PostableRepository {
  PostableRepository({
    Dio? dio,
    this.authority = 'news.ycombinator.com',
  }) : _dio = dio ?? Dio();

  final Dio _dio;

  @protected
  final String authority;

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
    } on DioException catch (e) {
      throw ServiceException(e.message);
    }
  }

  @protected
  Future<Response<List<int>>> getFormResponse({
    required String username,
    required String password,
    required String path,
    int? id,
  }) async {
    final Uri uri = Uri.https(
      authority,
      path,
      <String, dynamic>{if (id != null) 'id': id.toString()},
    );
    final PostDataMixin data = FormPostData(
      acct: username,
      pw: password,
      id: id,
    );
    return performPost(
      uri,
      data,
      responseType: ResponseType.bytes,
      validateStatus: (int? status) => status == HttpStatus.ok,
    );
  }
}
