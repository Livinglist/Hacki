import 'dart:async';

import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/postable_repository.dart';
import 'package:hacki/repositories/preference_repository.dart';
import 'package:logger/logger.dart';

class AuthRepository extends PostableRepository {
  AuthRepository({
    super.dio,
    PreferenceRepository? preferenceRepository,
    Logger? logger,
  })  : _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        _logger = logger ?? locator.get<Logger>();

  final PreferenceRepository _preferenceRepository;
  final Logger _logger;

  Future<bool> get loggedIn async => _preferenceRepository.loggedIn;

  Future<String?> get username async => _preferenceRepository.username;

  Future<String?> get password async => _preferenceRepository.password;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final Uri uri = Uri.https(authority, 'login');
    final PostDataMixin data = LoginPostData(
      acct: username,
      pw: password,
      goto: 'news',
    );

    final bool success = await performDefaultPost(uri, data);

    if (success) {
      try {
        await _preferenceRepository.setAuth(
          username: username,
          password: password,
        );
      } catch (_) {
        _logger.e(_);
        return false;
      }
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
    final Uri uri = Uri.https(authority, 'flag');
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;
    final PostDataMixin data = FlagPostData(
      acct: username!,
      pw: password!,
      id: id,
      un: flag ? null : 't',
    );

    return performDefaultPost(uri, data);
  }

  Future<bool> favorite({
    required int id,
    required bool favorite,
  }) async {
    final Uri uri = Uri.https(authority, 'fave');
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;
    final PostDataMixin data = FavoritePostData(
      acct: username!,
      pw: password!,
      id: id,
      un: favorite ? null : 't',
    );

    return performDefaultPost(uri, data);
  }

  Future<bool> upvote({
    required int id,
    required bool upvote,
  }) async {
    final Uri uri = Uri.https(authority, 'vote');
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;
    final PostDataMixin data = VotePostData(
      acct: username!,
      pw: password!,
      id: id,
      how: upvote ? 'up' : 'un',
    );

    return performDefaultPost(uri, data);
  }

  Future<bool> downvote({
    required int id,
    required bool downvote,
  }) async {
    final Uri uri = Uri.https(authority, 'vote');
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;
    final PostDataMixin data = VotePostData(
      acct: username!,
      pw: password!,
      id: id,
      how: downvote ? 'down' : 'un',
    );

    return performDefaultPost(uri, data);
  }
}
