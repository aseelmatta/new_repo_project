import 'package:shared_preferences.dart';

class AuthService {
  static const String _userRoleKey = 'user_role';
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<String?> getUserRole() async {
    return _prefs?.getString(_userRoleKey);
  }

  static Future<void> setUserRole(String role) async {
    await _prefs?.setString(_userRoleKey, role);
  }

  static Future<void> clearUserRole() async {
    await _prefs?.remove(_userRoleKey);
  }
}
