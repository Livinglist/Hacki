import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/utils/debouncer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synced_shared_preferences/synced_shared_preferences.dart';

/// [PreferenceRepository] is for storing user preferences.
class PreferenceRepository with Loggable {
  PreferenceRepository({
    SyncedSharedPreferences? syncedPrefs,
    Future<SharedPreferences>? prefs,
    FlutterSecureStorage? secureStorage,
  })  : _syncedPrefs = syncedPrefs ?? SyncedSharedPreferences.instance,
        _prefs = prefs ?? SharedPreferences.getInstance(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _blocklistKey = 'blocklist';
  static const String _filterKeywordsKey = 'filterKeywords';
  static const String _pinnedStoriesIdsKey = 'pinnedStoriesIds';
  static const String _unreadCommentsIdsKey = 'unreadCommentsIds';
  static const String _lastReadStoryIdKey = 'lastReadStoryId';

  final SyncedSharedPreferences _syncedPrefs;
  final Future<SharedPreferences> _prefs;
  final FlutterSecureStorage _secureStorage;

  Future<bool> get loggedIn async => await username != null;

  Future<String?> get username async => _secureStorage.read(key: _usernameKey);

  Future<String?> get password async => _secureStorage.read(key: _passwordKey);

  Future<bool?> getBool(String key) => _prefs.then(
        (SharedPreferences prefs) => prefs.getBool(key),
      );

  Future<int?> getInt(String key) => _prefs.then(
        (SharedPreferences prefs) => prefs.getInt(key),
      );

  Future<double?> getDouble(String key) => _prefs.then(
        (SharedPreferences prefs) => prefs.getDouble(key),
      );

  //ignore: avoid_positional_boolean_parameters
  void setBool(String key, bool val) => _prefs.then(
        (SharedPreferences prefs) => prefs.setBool(key, val),
      );

  void setInt(String key, int val) => _prefs.then(
        (SharedPreferences prefs) => prefs.setInt(key, val),
      );

  void setDouble(String key, double val) => _prefs.then(
        (SharedPreferences prefs) => prefs.setDouble(key, val),
      );

  Future<bool> hasPushed(int commentId) async =>
      _prefs.then((SharedPreferences prefs) {
        final bool? val = prefs.getBool(_getPushNotificationKey(commentId));

        if (val == null) return false;

        return true;
      });

  Future<bool> hasRead(int storyId) async {
    final String key = _getHasReadKey(storyId);
    if (Platform.isIOS) {
      final bool? val = await _syncedPrefs.getBool(key: key);
      return val ?? false;
    } else {
      return _prefs.then((SharedPreferences prefs) {
        final bool? val = prefs.getBool(key);

        if (val == null) return false;

        return true;
      });
    }
  }

  Future<void> setAuth({
    required String username,
    required String password,
  }) async {
    const AndroidOptions androidOptions = AndroidOptions(resetOnError: true);
    try {
      await _secureStorage.write(
        key: _usernameKey,
        value: username,
        aOptions: androidOptions,
      );
      await _secureStorage.write(
        key: _passwordKey,
        value: password,
        aOptions: androidOptions,
      );
    } catch (_) {
      try {
        await _secureStorage.deleteAll(
          aOptions: androidOptions,
        );
      } catch (e) {
        logError(e);
      }

      rethrow;
    }
  }

  Future<void> removeAuth() async {
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _passwordKey);
  }

  //#region fav

  Future<List<int>> favList({required String of}) async {
    final SharedPreferences prefs = await _prefs;
    if (Platform.isIOS) {
      final List<String> previousList =
          ((prefs.getStringList(_getFavKey('')) ?? <String>[])
                ..addAll(prefs.getStringList(_getFavKey(of)) ?? <String>[]))
              .toList();

      /// Since v0.2.5, fav list will be stored in [NSUbiquitousKeyValueStore]
      /// instead of [UserDefaults] on iOS.
      if (previousList.isNotEmpty) {
        for (final String fav in previousList) {
          await addFav(username: of, id: int.parse(fav));
        }

        await prefs.remove(_getFavKey(''));
        await prefs.remove(_getFavKey(of));
      }

      final List<String>? initialList =
          await _syncedPrefs.getStringList(key: _getFavKey(''));
      final List<String>? userList =
          await _syncedPrefs.getStringList(key: _getFavKey(of));

      return <String>{
        ...?initialList,
        ...?userList,
      }.map(int.parse).toList();
    } else {
      final List<int> favList =
          ((prefs.getStringList(_getFavKey('')) ?? <String>[])
                ..addAll(prefs.getStringList(_getFavKey(of)) ?? <String>[]))
              .map(int.parse)
              .toList();

      return favList;
    }
  }

  Future<void> addFav({required String username, required int id}) async {
    final String key = _getFavKey(username);

    if (Platform.isIOS) {
      final List<String> favListInString =
          (await _syncedPrefs.getStringList(key: key)) ?? <String>[];
      final List<int> favList = favListInString.map(int.parse).toList()
        ..insert(0, id);

      await _syncedPrefs.setStringList(
        key: key,
        val: favList.map((int e) => e.toString()).toList(),
      );
    } else {
      final SharedPreferences prefs = await _prefs;
      final List<String> favListInString =
          prefs.getStringList(key) ?? <String>[];
      final List<int> favList = favListInString.map(int.parse).toList()
        ..insert(0, id);

      await prefs.setStringList(
        key,
        favList.map((int e) => e.toString()).toList(),
      );
    }
  }

  Future<void> overwriteFav({
    required String username,
    required Iterable<int> ids,
  }) async {
    final String key = _getFavKey(username);
    final List<String> favList =
        ids.map((int e) => e.toString()).toList(growable: false);

    if (Platform.isIOS) {
      await _syncedPrefs.setStringList(
        key: key,
        val: favList,
      );
    } else {
      final SharedPreferences prefs = await _prefs;

      await prefs.setStringList(
        key,
        favList,
      );
    }
  }

  Future<void> removeFav({required String username, required int id}) async {
    final String key = _getFavKey(username);

    if (Platform.isIOS) {
      final List<String> favListInString =
          (await _syncedPrefs.getStringList(key: key)) ?? <String>[];
      final List<int> favList = favListInString.map(int.parse).toList()
        ..remove(id);
      await _syncedPrefs.setStringList(
        key: key,
        val: favList.map((int e) => e.toString()).toList(),
      );
    } else {
      final SharedPreferences prefs = await _prefs;
      final List<String> favListInString =
          prefs.getStringList(key) ?? <String>[];
      final List<int> favList = favListInString.map(int.parse).toList()
        ..remove(id);
      await prefs.setStringList(
        key,
        favList.map((int e) => e.toString()).toList(),
      );
    }
  }

  Future<void> clearAllFavs({required String username}) async {
    final String key = _getFavKey(username);

    if (Platform.isIOS) {
      await _syncedPrefs.setStringList(
        key: key,
        val: <String>[],
      );
    } else {
      final SharedPreferences prefs = await _prefs;
      await prefs.setStringList(
        key,
        <String>[],
      );
    }
  }

  static String _getFavKey(String username) => 'fav_$username';

  //#endregion

  //#region vote

  Future<bool?> vote({required int submittedTo, required String from}) async {
    final SharedPreferences prefs = await _prefs;
    final String key = _getVoteKey(from, submittedTo);
    final bool? vote = prefs.getBool(key);
    return vote;
  }

  Future<void> addVote({
    required String username,
    required int id,
    required bool vote,
  }) async {
    final SharedPreferences prefs = await _prefs;
    final String key = _getVoteKey(username, id);
    await prefs.setBool(key, vote);
  }

  Future<void> removeVote({
    required String username,
    required int id,
  }) async {
    final SharedPreferences prefs = await _prefs;
    final String key = _getVoteKey(username, id);
    await prefs.remove(key);
  }

  String _getVoteKey(String username, int id) => 'vote_$username-$id';

  //#endregion

  //#region blocklist

  Future<List<String>> get blocklist async => _prefs.then(
        (SharedPreferences prefs) =>
            prefs.getStringList(_blocklistKey) ?? <String>[],
      );

  Future<void> updateBlocklist(List<String> usernames) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setStringList(_blocklistKey, usernames);
  }

  //#endregion

  //#region filter

  Future<List<String>> get filterKeywords async => _prefs.then(
        (SharedPreferences prefs) =>
            prefs.getStringList(_filterKeywordsKey) ?? <String>[],
      );

  Future<void> updateFilterKeywords(List<String> keywords) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setStringList(_filterKeywordsKey, keywords);
  }

  //#endregion

  //#region pins

  Future<List<int>> get pinnedStoriesIds async {
    if (Platform.isIOS) {
      final List<String>? favList = await _syncedPrefs.getStringList(
        key: _pinnedStoriesIdsKey,
      );
      return favList?.map(int.parse).toList() ?? <int>[];
    } else {
      return _prefs.then(
        (SharedPreferences prefs) =>
            prefs
                .getStringList(_pinnedStoriesIdsKey)
                ?.map(int.parse)
                .toList() ??
            <int>[],
      );
    }
  }

  Future<void> updatePinnedStoriesIds(List<int> ids) async {
    if (Platform.isIOS) {
      await _syncedPrefs.setStringList(
        key: _pinnedStoriesIdsKey,
        val: ids.map((int e) => e.toString()).toList(),
      );
    } else {
      final SharedPreferences prefs = await _prefs;
      await prefs.setStringList(
        _pinnedStoriesIdsKey,
        ids.map((int e) => e.toString()).toList(),
      );
    }
  }

  //#endregion

  //#region unread comment ids

  Future<List<int>> get unreadCommentsIds async => _prefs.then(
        (SharedPreferences prefs) =>
            prefs
                .getStringList(_unreadCommentsIdsKey)
                ?.map(int.parse)
                .toList() ??
            <int>[],
      );

  Future<void> updateUnreadCommentsIds(List<int> ids) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setStringList(
      _unreadCommentsIdsKey,
      ids.map((int e) => e.toString()).toList(),
    );
  }

  //#endregion

  //#region reminder

  Future<int?> get lastReadStoryId async =>
      _prefs.then((SharedPreferences prefs) {
        final String? val = prefs.getString(_lastReadStoryIdKey);

        if (val == null) return null;

        return int.tryParse(val);
      });

  Future<void> updateLastReadStoryId(int? id) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(
      _lastReadStoryIdKey,
      id.toString(),
    );
  }

  //#endregion

  Future<void> updateHasPushed(int commentId) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setBool(
      _getPushNotificationKey(commentId),
      true,
    );
  }

  final List<String> _storiesIdQueue = <String>[];
  final Debouncer _debouncer = Debouncer(delay: AppDurations.tenSeconds);

  Future<void> addHasRead(int storyId) async {
    final String key = _getHasReadKey(storyId);

    if (Platform.isIOS) {
      _storiesIdQueue.add(key);
      _debouncer.run(() {
        for (final String key in _storiesIdQueue) {
          _syncedPrefs.setBool(key: key, val: true);
        }
        _storiesIdQueue.clear();
      });
    } else {
      final SharedPreferences prefs = await _prefs;

      await prefs.setBool(
        _getHasReadKey(storyId),
        true,
      );
    }
  }

  Future<void> removeHasRead(int storyId) async {
    final String key = _getHasReadKey(storyId);
    if (Platform.isIOS) {
      await _syncedPrefs.remove(key: key);
    } else {
      final SharedPreferences prefs = await _prefs;

      await prefs.remove(_getHasReadKey(storyId));
    }
  }

  Future<void> clearAllReadStories() async {
    if (Platform.isIOS) {
      await _syncedPrefs.clearAll();
    } else {
      final SharedPreferences prefs = await _prefs;

      final Iterable<String> allKeys =
          prefs.getKeys().where((String e) => e.contains('hasRead'));
      for (final String key in allKeys) {
        await prefs.remove(key);
      }
    }
  }

  static String _getPushNotificationKey(int commentId) => 'pushed_$commentId';

  static String _getHasReadKey(int storyId) => 'hasRead_$storyId';

  @override
  String get logIdentifier => '[PreferenceRepository]';
}
