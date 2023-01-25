import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/post_data.dart';
import 'package:hacki/repositories/postable_repository.dart';
import 'package:hacki/repositories/preference_repository.dart';
import 'package:hacki/utils/utils.dart';

class PostRepository extends PostableRepository {
  PostRepository({super.dio, PreferenceRepository? storageRepository})
      : _preferenceRepository =
            storageRepository ?? locator.get<PreferenceRepository>();

  final PreferenceRepository _preferenceRepository;

  static const String _authority = 'news.ycombinator.com';

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

    return performDefaultPost(
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

    return performDefaultPost(
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

    return performDefaultPost(
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
    return performPost(
      uri,
      data,
      responseType: ResponseType.bytes,
      validateStatus: (int? status) => status == HttpStatus.ok,
    );
  }
}
