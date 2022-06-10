import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synced_shared_preferences/synced_shared_preferences.dart';

class PreferenceRepository {
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
  static const String _pinnedStoriesIdsKey = 'pinnedStoriesIds';
  static const String _unreadCommentsIdsKey = 'unreadCommentsIds';
  static const String _lastReadStoryIdKey = 'lastReadStoryId';
  static const String _isFirstLaunchKey = 'isFirstLaunch';
  static const String _metadataModeKey = 'metadataMode';

  static const String _notificationModeKey = 'notificationMode';
  static const String _readerModeKey = 'readerMode';

  /// Exposing this val for main func.
  static const String trueDarkModeKey = 'trueDarkMode';

  /// The key of a boolean value deciding whether or not the story
  /// tile should display link preview. Defaults to true.
  static const String _displayModeKey = 'displayMode';

  /// The key of a boolean value deciding whether or not the internal
  /// webview browser should be used. Defaults to true.
  static const String _browserModeKey = 'browserMode';

  /// The key of a boolean value deciding whether or not user should be
  /// navigated to web view first. Defaults to false.
  static const String _navigationModeKey = 'navigationMode';
  static const String _eyeCandyModeKey = 'eyeCandyMode';
  static const String _markReadStoriesModeKey = 'markReadStoriesMode';

  static const bool _notificationModeDefaultValue = true;
  static const bool _displayModeDefaultValue = true;
  static const bool _browserModeDefaultValue = true;
  static const bool _navigationModeDefaultValue = true;
  static const bool _eyeCandyModeDefaultValue = false;
  static const bool _trueDarkModeDefaultValue = false;
  static const bool _readerModeDefaultValue = true;
  static const bool _markReadStoriesModeDefaultValue = true;
  static const bool _isFirstLaunchKeyDefaultValue = true;
  static const bool _metadataModeDefaultValue = true;

  final SyncedSharedPreferences _syncedPrefs;
  final Future<SharedPreferences> _prefs;
  final FlutterSecureStorage _secureStorage;

  Future<bool> get loggedIn async => await username != null;

  Future<String?> get username async => _secureStorage.read(key: _usernameKey);

  Future<String?> get password async => _secureStorage.read(key: _passwordKey);

  Future<bool> get isFirstLaunch async {
    final SharedPreferences prefs = await _prefs;
    final bool val =
        prefs.getBool(_isFirstLaunchKey) ?? _isFirstLaunchKeyDefaultValue;

    await prefs.setBool(_isFirstLaunchKey, false);

    return val;
  }

  Future<bool> get shouldShowNotification async => _prefs.then(
        (SharedPreferences prefs) =>
            prefs.getBool(_notificationModeKey) ??
            _notificationModeDefaultValue,
      );

  Future<bool> get shouldShowComplexStoryTile async => _prefs.then(
        (SharedPreferences prefs) =>
            prefs.getBool(_displayModeKey) ?? _displayModeDefaultValue,
      );

  Future<bool> get shouldUseInternalBrowser async => _prefs.then(
        (SharedPreferences prefs) =>
            prefs.getBool(_browserModeKey) ?? _browserModeDefaultValue,
      );

  Future<bool> get shouldShowWebFirst async => _prefs.then(
        (SharedPreferences prefs) =>
            prefs.getBool(_navigationModeKey) ?? _navigationModeDefaultValue,
      );

  Future<bool> get shouldShowEyeCandy async => _prefs.then(
        (SharedPreferences prefs) =>
            prefs.getBool(_eyeCandyModeKey) ?? _eyeCandyModeDefaultValue,
      );

  Future<bool> get shouldShowMetadata async => _prefs.then(
        (SharedPreferences prefs) =>
            prefs.getBool(_metadataModeKey) ?? _metadataModeDefaultValue,
      );

  Future<bool> get trueDarkMode async => _prefs.then(
        (SharedPreferences prefs) =>
            prefs.getBool(trueDarkModeKey) ?? _trueDarkModeDefaultValue,
      );

  Future<bool> get readerMode async => _prefs.then(
        (SharedPreferences prefs) =>
            prefs.getBool(_readerModeKey) ?? _readerModeDefaultValue,
      );

  Future<bool> get markReadStories async => _prefs.then(
        (SharedPreferences prefs) =>
            prefs.getBool(_markReadStoriesModeKey) ??
            _markReadStoriesModeDefaultValue,
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
    await _secureStorage.write(key: _usernameKey, value: username);
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  Future<void> removeAuth() async {
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _passwordKey);
  }

  Future<void> toggleNotificationMode() async {
    final SharedPreferences prefs = await _prefs;
    final bool currentMode =
        prefs.getBool(_notificationModeKey) ?? _notificationModeDefaultValue;
    await prefs.setBool(_notificationModeKey, !currentMode);
  }

  Future<void> toggleDisplayMode() async {
    final SharedPreferences prefs = await _prefs;
    final bool currentMode =
        prefs.getBool(_displayModeKey) ?? _displayModeDefaultValue;
    await prefs.setBool(_displayModeKey, !currentMode);
  }

  Future<void> toggleBrowserMode() async {
    final SharedPreferences prefs = await _prefs;
    final bool currentMode =
        prefs.getBool(_browserModeKey) ?? _browserModeDefaultValue;
    await prefs.setBool(_browserModeKey, !currentMode);
  }

  Future<void> toggleNavigationMode() async {
    final SharedPreferences prefs = await _prefs;
    final bool currentMode =
        prefs.getBool(_navigationModeKey) ?? _navigationModeDefaultValue;
    await prefs.setBool(_navigationModeKey, !currentMode);
  }

  Future<void> toggleEyeCandyMode() async {
    final SharedPreferences prefs = await _prefs;
    final bool currentMode =
        prefs.getBool(_eyeCandyModeKey) ?? _eyeCandyModeDefaultValue;
    await prefs.setBool(_eyeCandyModeKey, !currentMode);
  }

  Future<void> toggleTrueDarkMode() async {
    final SharedPreferences prefs = await _prefs;
    final bool currentMode =
        prefs.getBool(trueDarkModeKey) ?? _trueDarkModeDefaultValue;
    await prefs.setBool(trueDarkModeKey, !currentMode);
  }

  Future<void> toggleReaderMode() async {
    final SharedPreferences prefs = await _prefs;
    final bool currentMode =
        prefs.getBool(_readerModeKey) ?? _readerModeDefaultValue;
    await prefs.setBool(_readerModeKey, !currentMode);
  }

  Future<void> toggleMarkReadStoriesMode() async {
    final SharedPreferences prefs = await _prefs;
    final bool currentMode = prefs.getBool(_markReadStoriesModeKey) ??
        _markReadStoriesModeDefaultValue;
    await prefs.setBool(_markReadStoriesModeKey, !currentMode);
  }

  Future<void> toggleMetadataMode() async {
    final SharedPreferences prefs = await _prefs;
    final bool currentMode =
        prefs.getBool(_metadataModeKey) ?? _metadataModeDefaultValue;
    await prefs.setBool(_metadataModeKey, !currentMode);
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
              .toSet()
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
        val: favList.map((int e) => e.toString()).toSet().toList(),
      );
    } else {
      final SharedPreferences prefs = await _prefs;
      final List<String> favListInString =
          prefs.getStringList(key) ?? <String>[];
      final List<int> favList = favListInString.map(int.parse).toList()
        ..insert(0, id);

      await prefs.setStringList(
        key,
        favList.map((int e) => e.toString()).toSet().toList(),
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

  Future<void> updateHasRead(int storyId) async {
    final String key = _getHasReadKey(storyId);
    if (Platform.isIOS) {
      await _syncedPrefs.setBool(key: key, val: true);
    } else {
      final SharedPreferences prefs = await _prefs;

      await prefs.setBool(
        _getHasReadKey(storyId),
        true,
      );
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
}
