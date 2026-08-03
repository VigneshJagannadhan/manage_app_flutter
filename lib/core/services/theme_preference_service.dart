import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's chosen theme (light/dark) across app restarts.
class ThemePreferenceService {
  static const _isDarkModeKey = 'settings_is_dark_mode';

  Future<bool> readIsDarkMode({bool defaultValue = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isDarkModeKey) ?? defaultValue;
  }

  Future<void> saveIsDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, isDarkMode);
  }
}

final themePreferenceService = ThemePreferenceService();
