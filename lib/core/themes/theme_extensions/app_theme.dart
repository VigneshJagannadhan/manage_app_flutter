import 'dart:ui';
import 'package:flutter/material.dart';

class AppTheme extends ThemeExtension<AppTheme> {
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? outlineColor;

  final TextStyle? displayLarge;
  final TextStyle? displayMedium;
  final TextStyle? displaySmall;
  final TextStyle? headlineLarge;
  final TextStyle? headlineMedium;
  final TextStyle? headlineSmall;
  final TextStyle? titleLarge;
  final TextStyle? titleMedium;
  final TextStyle? titleSmall;
  final TextStyle? bodyLarge;
  final TextStyle? bodyMedium;
  final TextStyle? bodySmall;
  final TextStyle? labelLarge;
  final TextStyle? labelMedium;
  final TextStyle? labelSmall;

  final double? appBorderRadius;
  final double? controlHeight;

  final double? verticalMargin;
  final double? horizontalMargin;

  final double? spacingXSmall;
  final double? spacingSmall;
  final double? spacingMedium;
  final double? spacingLarge;

  final double? elevationSmall;
  final double? elevationMedium;
  final double? elevationLarge;

  const AppTheme({
    this.primaryColor,
    this.secondaryColor,
    this.outlineColor,
    this.displayLarge,
    this.displayMedium,
    this.displaySmall,
    this.headlineLarge,
    this.headlineMedium,
    this.headlineSmall,
    this.titleLarge,
    this.titleMedium,
    this.titleSmall,
    this.bodyLarge,
    this.bodyMedium,
    this.bodySmall,
    this.labelLarge,
    this.labelMedium,
    this.labelSmall,
    this.verticalMargin,
    this.horizontalMargin,
    this.spacingXSmall,
    this.spacingSmall,
    this.spacingMedium,
    this.spacingLarge,
    this.appBorderRadius,
    this.controlHeight,
    this.elevationSmall,
    this.elevationMedium,
    this.elevationLarge,
  });

  @override
  AppTheme copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? outlineColor,
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
    double? appBorderRadius,
    double? controlHeight,
    double? elevationSmall,
    double? elevationMedium,
    double? elevationLarge,
  }) {
    return AppTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      outlineColor: outlineColor ?? this.outlineColor,
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
      appBorderRadius: appBorderRadius ?? this.appBorderRadius,
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
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t),
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t),
      outlineColor: Color.lerp(outlineColor, other.outlineColor, t),
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t),
      displayMedium: TextStyle.lerp(displayMedium, other.displayMedium, t),
      displaySmall: TextStyle.lerp(displaySmall, other.displaySmall, t),
      headlineLarge: TextStyle.lerp(headlineLarge, other.headlineLarge, t),
      headlineMedium: TextStyle.lerp(headlineMedium, other.headlineMedium, t),
      headlineSmall: TextStyle.lerp(headlineSmall, other.headlineSmall, t),
      titleLarge: TextStyle.lerp(titleLarge, other.titleLarge, t),
      titleMedium: TextStyle.lerp(titleMedium, other.titleMedium, t),
      titleSmall: TextStyle.lerp(titleSmall, other.titleSmall, t),
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t),
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t),
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t),
      labelLarge: TextStyle.lerp(labelLarge, other.labelLarge, t),
      labelMedium: TextStyle.lerp(labelMedium, other.labelMedium, t),
      labelSmall: TextStyle.lerp(labelSmall, other.labelSmall, t),
      verticalMargin: lerpDouble(verticalMargin, other.verticalMargin, t),
      horizontalMargin: lerpDouble(horizontalMargin, other.horizontalMargin, t),
      spacingXSmall: lerpDouble(spacingXSmall, other.spacingXSmall, t),
      spacingSmall: lerpDouble(spacingSmall, other.spacingSmall, t),
      spacingMedium: lerpDouble(spacingMedium, other.spacingMedium, t),
      spacingLarge: lerpDouble(spacingLarge, other.spacingLarge, t),
      appBorderRadius: lerpDouble(appBorderRadius, other.appBorderRadius, t),
      controlHeight: lerpDouble(controlHeight, other.controlHeight, t),
      elevationSmall: lerpDouble(elevationSmall, other.elevationSmall, t),
      elevationMedium: lerpDouble(elevationMedium, other.elevationMedium, t),
      elevationLarge: lerpDouble(elevationLarge, other.elevationLarge, t),
    );
  }
}
