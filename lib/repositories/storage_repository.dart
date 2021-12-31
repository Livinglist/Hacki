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

  final Future<SharedPreferences> _prefs;
  final FlutterSecureStorage _secureStorage;

  Future<bool> get loggedIn async => await username != null;

  Future<String?> get username async => _secureStorage.read(key: _usernameKey);

  Future<String?> get password async => _secureStorage.read(key: _passwordKey);

  Future<List<int>> favList({required String of}) => _prefs.then((prefs) =>
      (prefs.getStringList(of) ?? <String>[]).map(int.parse).toList());

  Future<void> setAuth(
      {required String username, required String password}) async {
    await _secureStorage.write(key: _usernameKey, value: username);
    await _secureStorage.write(key: _passwordKey, value: password);
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
