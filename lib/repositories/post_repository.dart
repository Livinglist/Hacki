import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/post_data.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/utils/utils.dart';

class PostRepository {
  PostRepository({Dio? dio, PreferenceRepository? storageRepository})
      : _dio = dio ?? Dio(),
        _preferenceRepository =
            storageRepository ?? locator.get<PreferenceRepository>();

  static const String _authority = 'news.ycombinator.com';

  final Dio _dio;
  final PreferenceRepository _preferenceRepository;

  Future<bool> comment({
    required int parentId,
    required String text,
  }) async {
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;
    final Uri uri = Uri.https(_authority, 'comment');

    if (username == null || password == null) {
      return false;
    }

    final PostDataMixin data = CommentPostData(
      acct: username,
      pw: password,
      parent: parentId,
      text: text,
    );

    return _performDefaultPost(
      uri,
      data,
      validateLocation: (String? location) => location == '/',
    );
  }

  Future<bool> submit({
    required String title,
    String? url,
    String? text,
  }) async {
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;

    if (username == null || password == null) {
      return false;
    }

    final Response<List<int>> formResponse = await _getFormResponse(
      username: username,
      password: password,
      path: 'submitlink',
    );
    final Map<String, String>? formValues =
        HtmlUtil.getHiddenFormValues(formResponse.data);

    if (formValues == null || formValues.isEmpty) {
      return false;
    }

    final String? cookie =
        formResponse.headers.value(HttpHeaders.setCookieHeader);

    final Uri uri = Uri.https(_authority, 'r');
    final PostDataMixin data = SubmitPostData(
      fnid: formValues['fnid']!,
      fnop: formValues['fnop']!,
      title: title,
      url: url,
      text: text,
    );

    return _performDefaultPost(
      uri,
      data,
      cookie: cookie,
      validateLocation: (String? location) => location == '/newest',
    );
  }

  Future<bool> edit({
    required int id,
    String? text,
  }) async {
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;

    if (username == null || password == null) {
      return false;
    }

    final Response<List<int>> formResponse = await _getFormResponse(
      username: username,
      password: password,
      id: id,
      path: 'edit',
    );
    final Map<String, String>? formValues =
        HtmlUtil.getHiddenFormValues(formResponse.data);

    if (formValues == null || formValues.isEmpty) {
      return false;
    }

    final String? cookie =
        formResponse.headers.value(HttpHeaders.setCookieHeader);

    final Uri uri = Uri.https(_authority, 'xedit');
    final PostDataMixin data = EditPostData(
      hmac: formValues['hmac']!,
      id: id,
      text: text,
    );

    return _performDefaultPost(
      uri,
      data,
      cookie: cookie,
    );
  }

  Future<Response<List<int>>> _getFormResponse({
    required String username,
    required String password,
    required String path,
    int? id,
  }) async {
    final Uri uri = Uri.https(
      _authority,
      path,
      <String, dynamic>{if (id != null) 'id': id.toString()},
    );
    final PostDataMixin data = FormPostData(
      acct: username,
      pw: password,
      id: id,
    );
    return _performPost(
      uri,
      data,
      responseType: ResponseType.bytes,
      validateStatus: (int? status) => status == HttpStatus.ok,
    );
  }

  Future<bool> _performDefaultPost(
    Uri uri,
    PostDataMixin data, {
    String? cookie,
    bool Function(String?)? validateLocation,
  }) async {
    try {
      final Response<void> response = await _performPost<void>(
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

  Future<Response<T>> _performPost<T>(
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
