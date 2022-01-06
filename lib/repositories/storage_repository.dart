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

  /// The key of a boolean value deciding whether or not the story
  /// tile should display link preview. Defaults to true.
  static const String _displayModeKey = 'displayModeKey';

  /// The key of a boolean value deciding whether or not user should be
  /// navigated to web view first. Defaults to false.
  static const String _navigationModeKey = 'navigationModeKey';

  static const bool _displayModeDefaultValue = true;
  static const bool _navigationModeDefaultValue = true;

  final Future<SharedPreferences> _prefs;
  final FlutterSecureStorage _secureStorage;

  Future<bool> get loggedIn async => await username != null;

  Future<String?> get username async => _secureStorage.read(key: _usernameKey);

  Future<String?> get password async => _secureStorage.read(key: _passwordKey);

  Future<bool> get shouldShowComplexStoryTile async => _prefs.then(
      (prefs) => prefs.getBool(_displayModeKey) ?? _displayModeDefaultValue);

  Future<bool> get shouldShowWebFirst async => _prefs.then((prefs) =>
      prefs.getBool(_navigationModeKey) ?? _navigationModeDefaultValue);

  Future<List<int>> favList({required String of}) => _prefs.then((prefs) =>
      (prefs.getStringList(of) ?? <String>[]).map(int.parse).toList());

  Future<void> setAuth(
      {required String username, required String password}) async {
    await _secureStorage.write(key: _usernameKey, value: username);
    await _secureStorage.write(key: _passwordKey, value: password);
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

  Future<void> addFav({required String username, required int id}) async {
    final prefs = await _prefs;
    final favListInString = prefs.getStringList(username) ?? <String>[];
    final favList = favListInString.map(int.parse).toList()..add(id);
    await prefs.setStringList(
        username, favList.map((e) => e.toString()).toSet().toList());
  }

  Future<void> removeFav({required String username, required int id}) async {
    final prefs = await _prefs;
    final favListInString = prefs.getStringList(username) ?? <String>[];
    final favList = favListInString.map(int.parse).toList()..remove(id);
    await prefs.setStringList(
        username, favList.map((e) => e.toString()).toList());
  }

  Future<void> removeAuth() async {
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _passwordKey);
  }
}
