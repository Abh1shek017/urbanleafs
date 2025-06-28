import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  late SharedPreferences _prefs;

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ----------------------
  // Boolean Values
  // ----------------------
  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  // ----------------------
  // String Values
  // ----------------------
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String getString(String key, {String defaultValue = ''}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  // ----------------------
  // Integer Values
  // ----------------------
  Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  // ----------------------
  // Double Values
  // ----------------------
  Future<void> saveDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  // ----------------------
  // Delete Data
  // ----------------------
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // ----------------------
  // Helper Methods for Your App
  // ----------------------

  // Save user login status
  Future<void> saveUserLoggedIn(bool isLoggedIn) async {
    await saveBool('user_logged_in', isLoggedIn);
  }

  bool isUserLoggedIn() {
    return getBool('user_logged_in', defaultValue: false);
  }

  // Save current user ID
  Future<void> saveUserId(String userId) async {
    await saveString('user_id', userId);
  }

  String getUserId() {
    return getString('user_id');
  }

  // Save user role (admin / regular)
  Future<void> saveUserRole(String role) async {
    await saveString('user_role', role);
  }

  String getUserRole() {
    return getString('user_role', defaultValue: 'regular');
  }

  // Save selected theme
  Future<void> saveThemeMode(String themeMode) async {
    await saveString('theme_mode', themeMode);
  }

  String getThemeMode() {
    return getString('theme_mode', defaultValue: 'system');
  }

  // Save last login timestamp
  Future<void> saveLastLoginTime(DateTime time) async {
    await saveString('last_login_time', time.toIso8601String());
  }

  DateTime? getLastLoginTime() {
    final timeStr = getString('last_login_time');
    if (timeStr.isEmpty) return null;
    return DateTime.tryParse(timeStr);
  }
}