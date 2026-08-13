import 'package:flutter/material.dart';
import 'package:manage_app/core/resources/app_fonts.dart';

/// Material 3 typography scale, built on [createStyle] so the font family
/// can be swapped in one place if needed.
class AppStyles {
  static TextStyle createStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    required AppFontOption font,
  }) {
    return font.textStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }

  static TextStyle displayLarge({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 57, fontWeight: FontWeight.bold, color: color, font: font);
  static TextStyle displayMedium({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 45, fontWeight: FontWeight.bold, color: color, font: font);
  static TextStyle displaySmall({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color, font: font);

  static TextStyle headlineLarge({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color, font: font);
  static TextStyle headlineMedium({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 28, fontWeight: FontWeight.w600, color: color, font: font);
  static TextStyle headlineSmall({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 24, fontWeight: FontWeight.w600, color: color, font: font);

  static TextStyle titleLarge({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 22, fontWeight: FontWeight.w600, color: color, font: font);
  static TextStyle titleMedium({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color, font: font);
  static TextStyle titleSmall({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color, font: font);

  static TextStyle bodyLarge({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 16, fontWeight: FontWeight.normal, color: color, font: font);
  static TextStyle bodyMedium({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 14, fontWeight: FontWeight.normal, color: color, font: font);
  static TextStyle bodySmall({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 12, fontWeight: FontWeight.normal, color: color, font: font);

  static TextStyle labelLarge({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color, font: font);
  static TextStyle labelMedium({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color, font: font);
  static TextStyle labelSmall({required Color color, required AppFontOption font}) =>
      createStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color, font: font);
}
