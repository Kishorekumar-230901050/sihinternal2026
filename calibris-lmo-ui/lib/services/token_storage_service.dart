import 'package:shared_preferences/shared_preferences.dart';

class TokenStorageService {
  static const String _keyToken = 'calibris_auth_token';
  static const String _keyRole = 'calibris_user_role';
  static const String _keyUserJson = 'calibris_user_json';

  Future<void> saveSession({required String token, required String role, String? userJson}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRole, role);
    if (userJson != null) {
      await prefs.setString(_keyUserJson, userJson);
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  Future<String?> getUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserJson);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyUserJson);
  }
}
