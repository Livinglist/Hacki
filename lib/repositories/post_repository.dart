import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/post_data.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/utils/utils.dart';

class PostRepository {
  PostRepository({Dio? dio, StorageRepository? storageRepository})
      : _dio = dio ?? Dio(),
        _storageRepository =
            storageRepository ?? locator.get<StorageRepository>();

  static const String authority = 'news.ycombinator.com';

  final Dio _dio;
  final StorageRepository _storageRepository;

  Future<bool> comment({
    required int parentId,
    required String text,
  }) async {
    final username = await _storageRepository.username;
    final password = await _storageRepository.password;
    final uri = Uri.https(authority, 'comment');

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
    final username = await _storageRepository.username;
    final password = await _storageRepository.password;

    if (username == null || password == null) {
      return false;
    }

    final formResponse = await _getFormResponse(
      username: username,
      password: password,
      path: 'submitlink',
    );
    final formValues = HtmlUtil.getHiddenFormValues(formResponse.data);

    if (formValues == null || formValues.isEmpty) {
      return false;
    }

    final cookie = formResponse.headers.value(HttpHeaders.setCookieHeader);

    final uri = Uri.https(authority, 'r');
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

  Future<Response<List<int>>> _getFormResponse({
    required String username,
    required String password,
    required String path,
    int? id,
  }) async {
    final uri = Uri.https(
      authority,
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
      final response = await _performPost<void>(
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
