import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/utils/service_exception.dart';

class AuthRepository {
  AuthRepository({
    Dio? dio,
    PreferenceRepository? storageRepository,
  })  : _dio = dio ?? Dio(),
        _preferenceRepository =
            storageRepository ?? locator.get<PreferenceRepository>();

  static const String _authority = 'news.ycombinator.com';

  final Dio _dio;
  final PreferenceRepository _preferenceRepository;

  Future<bool> get loggedIn async => _preferenceRepository.loggedIn;

  Future<String?> get username async => _preferenceRepository.username;

  Future<String?> get password async => _preferenceRepository.password;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final Uri uri = Uri.https(_authority, 'login');
    final PostDataMixin data = LoginPostData(
      acct: username,
      pw: password,
      goto: 'news',
    );

    final bool success = await _performDefaultPost(uri, data);

    if (success) {
      await _preferenceRepository.setAuth(
          username: username, password: password);
    }

    return success;
  }

  Future<bool> hasLoggedIn() => _preferenceRepository.loggedIn;

  Future<void> logout() async {
    await _preferenceRepository.removeAuth();
  }

  Future<bool> flag({
    required int id,
    required bool flag,
  }) async {
    final Uri uri = Uri.https(_authority, 'flag');
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;
    final PostDataMixin data = FlagPostData(
      acct: username!,
      pw: password!,
      id: id,
      un: flag ? null : 't',
    );

    return _performDefaultPost(uri, data);
  }

  Future<bool> favorite({
    required int id,
    required bool favorite,
  }) async {
    final Uri uri = Uri.https(_authority, 'fave');
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;
    final PostDataMixin data = FavoritePostData(
      acct: username!,
      pw: password!,
      id: id,
      un: favorite ? null : 't',
    );

    return _performDefaultPost(uri, data);
  }

  Future<bool> upvote({
    required int id,
    required bool upvote,
  }) async {
    final Uri uri = Uri.https(_authority, 'vote');
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;
    final PostDataMixin data = VotePostData(
      acct: username!,
      pw: password!,
      id: id,
      how: upvote ? 'up' : 'un',
    );

    return _performDefaultPost(uri, data);
  }

  Future<bool> downvote({
    required int id,
    required bool downvote,
  }) async {
    final Uri uri = Uri.https(_authority, 'vote');
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;
    final PostDataMixin data = VotePostData(
      acct: username!,
      pw: password!,
      id: id,
      how: downvote ? 'down' : 'un',
    );

    return _performDefaultPost(uri, data);
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
