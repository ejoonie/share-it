import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _tokenKey = 'token';
  static const String _hasLoggedInKey = 'has_logged_in_before';

  final SharedPreferences _prefs;

  TokenStorage(this._prefs);

  static Future<TokenStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TokenStorage(prefs);
  }

  String? getToken() => _prefs.getString(_tokenKey);

  Future<void> saveToken(String token) => _prefs.setString(_tokenKey, token);

  Future<void> clearToken() => _prefs.remove(_tokenKey);

  bool get hasLoggedInBefore => _prefs.getBool(_hasLoggedInKey) ?? false;

  Future<void> markLoggedIn() => _prefs.setBool(_hasLoggedInKey, true);
}
