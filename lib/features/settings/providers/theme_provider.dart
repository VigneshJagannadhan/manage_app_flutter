import 'package:flutter/material.dart';
import 'package:huddle/core/services/theme_preference_service.dart';
import 'package:huddle/features/shared/providers/base_provider.dart';

class ThemeProvider extends BaseProvider {
  ThemeProvider({required this.themePreferenceService});

  final ThemePreferenceService themePreferenceService;

  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    themePreferenceService.readIsDarkMode().then((isDarkMode) {
      _isDarkMode = isDarkMode;
      notifyListeners();
    });
  }

  @override
  void onDispose() {}

  Future<void> setDarkMode(bool isDarkMode) async {
    _isDarkMode = isDarkMode;
    notifyListeners();
    await themePreferenceService.saveIsDarkMode(isDarkMode);
  }
}
