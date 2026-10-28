import 'package:shared_preferences/shared_preferences.dart';

/// The only place that knows where the JWT is stored. Passwords are never saved.
class TokenStore {
  static const _key = 'auth_token';

  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
