import 'dart:ui';

import 'package:flutter/material.dart';

/// Every field is always supplied by both [AppThemes.lightTheme] and
/// [AppThemes.darkTheme] - none are optional in practice, so the fields are
/// non-nullable. That way a token missing from a theme is a compile error
/// instead of silently falling back to a possibly-different literal at each
/// call site.
class AppTheme extends ThemeExtension<AppTheme> {
  final Color primaryColor;
  final Color secondaryColor;
  final Color outlineColor;
  final Color successColor;

  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;

  /// Standard corner radius used by cards, buttons, inputs, dialogs and
  /// every other rounded surface that isn't a pill or a bottom sheet.
  final double appBorderRadius;

  /// Fully-round corner radius for pill/capsule shapes (tile badges, the
  /// bottom sheet drag handle) - a deliberately distinct shape, not drift.
  final double radiusPill;

  /// Top-corner radius for bottom sheets - larger than [appBorderRadius]
  /// since sheets are a deliberately distinct surface from cards.
  final double radiusSheet;

  final double controlHeight;

  final double verticalMargin;
  final double horizontalMargin;

  final double spacingXSmall;
  final double spacingSmall;
  final double spacingMedium;
  final double spacingLarge;

  /// Vertical gap between consecutive cards/tiles in a list.
  final double listItemGap;

  final double elevationSmall;
  final double elevationMedium;
  final double elevationLarge;

  const AppTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.outlineColor,
    required this.successColor,
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
    required this.verticalMargin,
    required this.horizontalMargin,
    required this.spacingXSmall,
    required this.spacingSmall,
    required this.spacingMedium,
    required this.spacingLarge,
    required this.listItemGap,
    required this.appBorderRadius,
    required this.radiusPill,
    required this.radiusSheet,
    required this.controlHeight,
    required this.elevationSmall,
    required this.elevationMedium,
    required this.elevationLarge,
  });

  @override
  AppTheme copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? outlineColor,
    Color? successColor,
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? headlineLarge,
    TextStyle? headlineMedium,
    TextStyle? headlineSmall,
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? titleSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    TextStyle? labelMedium,
    TextStyle? labelSmall,
    double? verticalMargin,
    double? horizontalMargin,
    double? spacingXSmall,
    double? spacingSmall,
    double? spacingMedium,
    double? spacingLarge,
    double? listItemGap,
    double? appBorderRadius,
    double? radiusPill,
    double? radiusSheet,
    double? controlHeight,
    double? elevationSmall,
    double? elevationMedium,
    double? elevationLarge,
  }) {
    return AppTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      outlineColor: outlineColor ?? this.outlineColor,
      successColor: successColor ?? this.successColor,
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      headlineSmall: headlineSmall ?? this.headlineSmall,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
      verticalMargin: verticalMargin ?? this.verticalMargin,
      horizontalMargin: horizontalMargin ?? this.horizontalMargin,
      spacingXSmall: spacingXSmall ?? this.spacingXSmall,
      spacingSmall: spacingSmall ?? this.spacingSmall,
      spacingMedium: spacingMedium ?? this.spacingMedium,
      spacingLarge: spacingLarge ?? this.spacingLarge,
      listItemGap: listItemGap ?? this.listItemGap,
      appBorderRadius: appBorderRadius ?? this.appBorderRadius,
      radiusPill: radiusPill ?? this.radiusPill,
      radiusSheet: radiusSheet ?? this.radiusSheet,
      controlHeight: controlHeight ?? this.controlHeight,
      elevationSmall: elevationSmall ?? this.elevationSmall,
      elevationMedium: elevationMedium ?? this.elevationMedium,
      elevationLarge: elevationLarge ?? this.elevationLarge,
    );
  }

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) {
      return this;
    }
    return AppTheme(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
      outlineColor: Color.lerp(outlineColor, other.outlineColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t)!,
      displayMedium: TextStyle.lerp(displayMedium, other.displayMedium, t)!,
      displaySmall: TextStyle.lerp(displaySmall, other.displaySmall, t)!,
      headlineLarge: TextStyle.lerp(headlineLarge, other.headlineLarge, t)!,
      headlineMedium: TextStyle.lerp(headlineMedium, other.headlineMedium, t)!,
      headlineSmall: TextStyle.lerp(headlineSmall, other.headlineSmall, t)!,
      titleLarge: TextStyle.lerp(titleLarge, other.titleLarge, t)!,
      titleMedium: TextStyle.lerp(titleMedium, other.titleMedium, t)!,
      titleSmall: TextStyle.lerp(titleSmall, other.titleSmall, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      labelLarge: TextStyle.lerp(labelLarge, other.labelLarge, t)!,
      labelMedium: TextStyle.lerp(labelMedium, other.labelMedium, t)!,
      labelSmall: TextStyle.lerp(labelSmall, other.labelSmall, t)!,
      verticalMargin: lerpDouble(verticalMargin, other.verticalMargin, t)!,
      horizontalMargin: lerpDouble(horizontalMargin, other.horizontalMargin, t)!,
      spacingXSmall: lerpDouble(spacingXSmall, other.spacingXSmall, t)!,
      spacingSmall: lerpDouble(spacingSmall, other.spacingSmall, t)!,
      spacingMedium: lerpDouble(spacingMedium, other.spacingMedium, t)!,
      spacingLarge: lerpDouble(spacingLarge, other.spacingLarge, t)!,
      listItemGap: lerpDouble(listItemGap, other.listItemGap, t)!,
      appBorderRadius: lerpDouble(appBorderRadius, other.appBorderRadius, t)!,
      radiusPill: lerpDouble(radiusPill, other.radiusPill, t)!,
      radiusSheet: lerpDouble(radiusSheet, other.radiusSheet, t)!,
      controlHeight: lerpDouble(controlHeight, other.controlHeight, t)!,
      elevationSmall: lerpDouble(elevationSmall, other.elevationSmall, t)!,
      elevationMedium: lerpDouble(elevationMedium, other.elevationMedium, t)!,
      elevationLarge: lerpDouble(elevationLarge, other.elevationLarge, t)!,
    );
  }
}
