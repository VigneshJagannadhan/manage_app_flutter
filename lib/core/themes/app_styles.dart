import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 typography scale, built on [createStyle] so the font family
/// can be swapped in one place if needed.
class AppStyles {
  static TextStyle createStyle({required double fontSize, required FontWeight fontWeight, required Color color}) {
    return GoogleFonts.roboto(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }

  static TextStyle displayLarge({required Color color}) => createStyle(fontSize: 57, fontWeight: FontWeight.bold, color: color);
  static TextStyle displayMedium({required Color color}) => createStyle(fontSize: 45, fontWeight: FontWeight.bold, color: color);
  static TextStyle displaySmall({required Color color}) => createStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color);

  static TextStyle headlineLarge({required Color color}) => createStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color);
  static TextStyle headlineMedium({required Color color}) => createStyle(fontSize: 28, fontWeight: FontWeight.w600, color: color);
  static TextStyle headlineSmall({required Color color}) => createStyle(fontSize: 24, fontWeight: FontWeight.w600, color: color);

  static TextStyle titleLarge({required Color color}) => createStyle(fontSize: 22, fontWeight: FontWeight.w600, color: color);
  static TextStyle titleMedium({required Color color}) => createStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color);
  static TextStyle titleSmall({required Color color}) => createStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color);

  static TextStyle bodyLarge({required Color color}) => createStyle(fontSize: 16, fontWeight: FontWeight.normal, color: color);
  static TextStyle bodyMedium({required Color color}) => createStyle(fontSize: 14, fontWeight: FontWeight.normal, color: color);
  static TextStyle bodySmall({required Color color}) => createStyle(fontSize: 12, fontWeight: FontWeight.normal, color: color);

  static TextStyle labelLarge({required Color color}) => createStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color);
  static TextStyle labelMedium({required Color color}) => createStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color);
  static TextStyle labelSmall({required Color color}) => createStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color);
}
