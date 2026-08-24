import 'package:flutter/material.dart';
import 'package:huddle/core/themes/theme_extensions/app_theme.dart';

extension BuildContextThemeExtensions on BuildContext {
  AppTheme get appTheme => Theme.of(this).extension<AppTheme>()!;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
