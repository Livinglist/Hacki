import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageRepository {
  StorageRepository({
    Future<SharedPreferences>? prefs,
    FlutterSecureStorage? secureStorage,
  })  : _prefs = prefs ?? SharedPreferences.getInstance(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _blocklistKey = 'blocklist';
  static const String _pinnedStoriesIdsKey = 'pinnedStoriesIds';
  static const String _notificationModeKey = 'notificationMode';
  static const String _trueDarkModeKey = 'trueDarkMode';
  static const String _readerModeKey = 'readerMode';
  static const String _imageModeKey = 'imageMode';

  /// The key of a boolean value deciding whether or not the story
  /// tile should display link preview. Defaults to true.
  static const String _displayModeKey = 'displayMode';

  /// The key of a boolean value deciding whether or not user should be
  /// navigated to web view first. Defaults to false.
  static const String _navigationModeKey = 'navigationMode';

  static const String _commentBorderModeKey = 'commentBorderMode';
  static const String _eyeCandyModeKey = 'eyeCandyMode';
  static const String _unreadCommentsIdsKey = 'unreadCommentsIds';

  static const bool _notificationModeDefaultValue = true;
  static const bool _displayModeDefaultValue = true;
  static const bool _navigationModeDefaultValue = true;
  static const bool _commentBorderModeDefaultValue = true;
  static const bool _eyeCandyModeDefaultValue = false;
  static const bool _trueDarkModeDefaultValue = false;
  static const bool _readerModeKeyDefaultValue = true;
  static const bool _imageModeKeyDefaultValue = true;

  final Future<SharedPreferences> _prefs;
  final FlutterSecureStorage _secureStorage;

  Future<bool> get loggedIn async => await username != null;

  Future<String?> get username async => _secureStorage.read(key: _usernameKey);

  Future<String?> get password async => _secureStorage.read(key: _passwordKey);

  Future<List<String>> get blocklist async =>
      _prefs.then((prefs) => prefs.getStringList(_blocklistKey) ?? []);

  Future<List<int>> get pinnedStoriesIds async => _prefs.then((prefs) =>
      prefs.getStringList(_pinnedStoriesIdsKey)?.map(int.parse).toList() ?? []);

  Future<bool> get shouldShowNotification async => _prefs.then((prefs) =>
      prefs.getBool(_notificationModeKey) ?? _notificationModeDefaultValue);

  Future<bool> get shouldShowComplexStoryTile async => _prefs.then(
      (prefs) => prefs.getBool(_displayModeKey) ?? _displayModeDefaultValue);

  Future<bool> get shouldShowWebFirst async => _prefs.then((prefs) =>
      prefs.getBool(_navigationModeKey) ?? _navigationModeDefaultValue);

  Future<bool> get shouldCommentBorder async => _prefs.then((prefs) =>
      prefs.getBool(_commentBorderModeKey) ?? _commentBorderModeDefaultValue);

  Future<bool> get shouldShowEyeCandy async => _prefs.then(
      (prefs) => prefs.getBool(_eyeCandyModeKey) ?? _eyeCandyModeDefaultValue);

  Future<bool> get trueDarkMode async => _prefs.then(
      (prefs) => prefs.getBool(_trueDarkModeKey) ?? _trueDarkModeDefaultValue);

  Future<bool> get readerMode async => _prefs.then(
      (prefs) => prefs.getBool(_readerModeKey) ?? _readerModeKeyDefaultValue);

  Future<bool> get imageMode async => _prefs.then(
      (prefs) => prefs.getBool(_imageModeKey) ?? _imageModeKeyDefaultValue);

  Future<List<int>> get unreadCommentsIds async => _prefs.then((prefs) =>
      prefs.getStringList(_unreadCommentsIdsKey)?.map(int.parse).toList() ??
      []);

  Future<List<int>> favList({required String of}) => _prefs.then((prefs) =>
      ((prefs.getStringList(_getFavKey('')) ?? <String>[])
            ..addAll(prefs.getStringList(_getFavKey(of)) ?? <String>[]))
          .map(int.parse)
          .toSet()
          .toList()
          .reversed
          .toList());

  Future<bool?> vote({required int submittedTo, required String from}) async {
    final prefs = await _prefs;
    final key = _getVoteKey(from, submittedTo);
    final vote = prefs.getBool(key);
    return vote;
  }

  Future<void> setAuth(
      {required String username, required String password}) async {
    await _secureStorage.write(key: _usernameKey, value: username);
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  Future<void> removeAuth() async {
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _passwordKey);
  }

  Future<void> toggleNotificationMode() async {
    final prefs = await _prefs;
    final currentMode =
        prefs.getBool(_notificationModeKey) ?? _notificationModeDefaultValue;
    await prefs.setBool(_notificationModeKey, !currentMode);
  }

  Future<void> toggleDisplayMode() async {
    final prefs = await _prefs;
    final currentMode =
        prefs.getBool(_displayModeKey) ?? _displayModeDefaultValue;
    await prefs.setBool(_displayModeKey, !currentMode);
  }

  Future<void> toggleNavigationMode() async {
    final prefs = await _prefs;
    final currentMode =
        prefs.getBool(_navigationModeKey) ?? _navigationModeDefaultValue;
    await prefs.setBool(_navigationModeKey, !currentMode);
  }

  Future<void> toggleCommentBorderMode() async {
    final prefs = await _prefs;
    final currentMode =
        prefs.getBool(_commentBorderModeKey) ?? _commentBorderModeDefaultValue;
    await prefs.setBool(_commentBorderModeKey, !currentMode);
  }

  Future<void> toggleEyeCandyMode() async {
    final prefs = await _prefs;
    final currentMode =
        prefs.getBool(_eyeCandyModeKey) ?? _eyeCandyModeDefaultValue;
    await prefs.setBool(_eyeCandyModeKey, !currentMode);
  }

  Future<void> toggleTrueDarkMode() async {
    final prefs = await _prefs;
    final currentMode =
        prefs.getBool(_trueDarkModeKey) ?? _trueDarkModeDefaultValue;
    await prefs.setBool(_trueDarkModeKey, !currentMode);
  }

  Future<void> toggleReaderMode() async {
    final prefs = await _prefs;
    final currentMode =
        prefs.getBool(_readerModeKey) ?? _readerModeKeyDefaultValue;
    await prefs.setBool(_readerModeKey, !currentMode);
  }

  Future<void> toggleImageMode() async {
    final prefs = await _prefs;
    final currentMode =
        prefs.getBool(_imageModeKey) ?? _imageModeKeyDefaultValue;
    await prefs.setBool(_imageModeKey, !currentMode);
  }

  Future<void> addFav({required String username, required int id}) async {
    final prefs = await _prefs;
    final key = _getFavKey(username);
    final favListInString = prefs.getStringList(key) ?? <String>[];
    final favList = favListInString.map(int.parse).toList()..add(id);
    await prefs.setStringList(
        key, favList.map((e) => e.toString()).toSet().toList());
  }

  Future<void> removeFav({required String username, required int id}) async {
    final prefs = await _prefs;
    final key = _getFavKey(username);
    final favListInString = prefs.getStringList(key) ?? <String>[];
    final favList = favListInString.map(int.parse).toList()..remove(id);
    await prefs.setStringList(key, favList.map((e) => e.toString()).toList());
  }

  Future<void> addVote({
    required String username,
    required int id,
    required bool vote,
  }) async {
    final prefs = await _prefs;
    final key = _getVoteKey(username, id);
    await prefs.setBool(key, vote);
  }

  Future<void> removeVote({
    required String username,
    required int id,
  }) async {
    final prefs = await _prefs;
    final key = _getVoteKey(username, id);
    await prefs.remove(key);
  }

  Future<void> updateBlocklist(List<String> usernames) async {
    final prefs = await _prefs;
    await prefs.setStringList(_blocklistKey, usernames);
  }

  Future<void> updatePinnedStoriesIds(List<int> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      _pinnedStoriesIdsKey,
      ids.map((e) => e.toString()).toList(),
    );
  }

  Future<void> updateUnreadCommentsIds(List<int> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      _unreadCommentsIdsKey,
      ids.map((e) => e.toString()).toList(),
    );
  }

  String _getFavKey(String username) => 'fav_$username';

  String _getVoteKey(String username, int id) => 'vote_$username-$id';
}
