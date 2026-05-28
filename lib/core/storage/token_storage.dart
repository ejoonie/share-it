import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _authTokenKey = 'auth_token';
  static const String _guestTokenKey = 'guest_token';

  final SharedPreferences _prefs;

  TokenStorage(this._prefs);

  static Future<TokenStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TokenStorage(prefs);
  }

  String? getAuthToken() => _prefs.getString(_authTokenKey);

  Future<void> saveAuthToken(String token) =>
      _prefs.setString(_authTokenKey, token);

  String? getGuestToken() => _prefs.getString(_guestTokenKey);

  Future<void> saveGuestToken(String token) =>
      _prefs.setString(_guestTokenKey, token);

  Future<void> clear() async {
    await _prefs.remove(_authTokenKey);
    await _prefs.remove(_guestTokenKey);
  }
}
