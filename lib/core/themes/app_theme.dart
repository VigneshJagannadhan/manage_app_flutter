import 'package:flutter/material.dart';
import 'package:manage_app/core/themes/app_styles.dart';
import 'package:manage_app/core/themes/constants/app_colors.dart';
import 'package:manage_app/core/themes/constants/app_elevation.dart';
import 'package:manage_app/core/themes/constants/app_sizing.dart';
import 'package:manage_app/core/themes/constants/app_spacing.dart';
import 'package:manage_app/core/themes/theme_extensions/app_theme.dart';

class AppThemes {
  /// Explicit color schemes built from [AppColors] instead of
  /// [ColorScheme.fromSeed]. `fromSeed` derives every surface/container tone
  /// algorithmically from the seed's hue, which is what produced the purple
  /// cast on cards and the bottom nav bar regardless of how blue
  /// [AppColors.primaryColor] is. The surfaceContainer* tones below are what
  /// Card and NavigationBar actually read for their background, so they're
  /// pinned to [AppColors.surfaceColor] instead of falling back to
  /// [ColorScheme.surface] (which is the scaffold background and would make
  /// cards/nav invisible against it).
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: AppColors.primaryColor,
    onPrimary: Colors.white,
    secondary: AppColors.secondaryColor,
    onSecondary: Colors.white,
    surface: AppColors.backgroundColor,
    onSurface: AppColors.textColor,
    outline: AppColors.outlineColor,
    surfaceContainerLowest: AppColors.surfaceColor,
    surfaceContainerLow: AppColors.surfaceColor,
    surfaceContainer: AppColors.surfaceColor,
    surfaceContainerHigh: AppColors.surfaceColor,
    surfaceContainerHighest: AppColors.surfaceColor,
  );

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: AppColors.primaryColorDark,
    onPrimary: Colors.white,
    secondary: AppColors.secondaryColorDark,
    onSecondary: Colors.white,
    surface: AppColors.backgroundColorDark,
    onSurface: AppColors.textColorDark,
    outline: AppColors.outlineColorDark,
    surfaceContainerLowest: AppColors.surfaceColorDark,
    surfaceContainerLow: AppColors.surfaceColorDark,
    surfaceContainer: AppColors.surfaceColorDark,
    surfaceContainerHigh: AppColors.surfaceColorDark,
    surfaceContainerHighest: AppColors.surfaceColorDark,
  );

  static const appBorderRadius = AppSizing.size12;

  /// Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: AppColors.backgroundColor,
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: AppColors.primaryColor)),
    extensions: [
      AppTheme(
        primaryColor: AppColors.primaryColor,
        secondaryColor: AppColors.secondaryColor,
        outlineColor: AppColors.outlineColor,
        displayLarge: AppStyles.displayLarge(color: AppColors.textColor),
        displayMedium: AppStyles.displayMedium(color: AppColors.textColor),
        displaySmall: AppStyles.displaySmall(color: AppColors.textColor),
        headlineLarge: AppStyles.headlineLarge(color: AppColors.textColor),
        headlineMedium: AppStyles.headlineMedium(color: AppColors.textColor),
        headlineSmall: AppStyles.headlineSmall(color: AppColors.textColor),
        titleLarge: AppStyles.titleLarge(color: AppColors.textColor),
        titleMedium: AppStyles.titleMedium(color: AppColors.textColor),
        titleSmall: AppStyles.titleSmall(color: AppColors.textColor),
        bodyLarge: AppStyles.bodyLarge(color: AppColors.textColor),
        bodyMedium: AppStyles.bodyMedium(color: AppColors.textColor),
        bodySmall: AppStyles.bodySmall(color: AppColors.textColor),
        labelLarge: AppStyles.labelLarge(color: AppColors.textColor),
        labelMedium: AppStyles.labelMedium(color: AppColors.textColor),
        labelSmall: AppStyles.labelSmall(color: AppColors.textColor),
        appBorderRadius: appBorderRadius,
        controlHeight: AppSizing.size24,
        verticalMargin: AppSpacing.space8,
        horizontalMargin: AppSpacing.space8,
        spacingXSmall: AppSpacing.xSmall,
        spacingSmall: AppSpacing.small,
        spacingMedium: AppSpacing.medium,
        spacingLarge: AppSpacing.large,
        elevationSmall: AppElevation.small,
        elevationMedium: AppElevation.medium,
        elevationLarge: AppElevation.large,
      ),
    ],
  );

  /// Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: AppColors.backgroundColorDark,
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: AppColors.primaryColorDark)),
    extensions: [
      AppTheme(
        primaryColor: AppColors.primaryColorDark,
        secondaryColor: AppColors.secondaryColorDark,
        outlineColor: AppColors.outlineColorDark,
        displayLarge: AppStyles.displayLarge(color: AppColors.textColorDark),
        displayMedium: AppStyles.displayMedium(color: AppColors.textColorDark),
        displaySmall: AppStyles.displaySmall(color: AppColors.textColorDark),
        headlineLarge: AppStyles.headlineLarge(color: AppColors.textColorDark),
        headlineMedium: AppStyles.headlineMedium(color: AppColors.textColorDark),
        headlineSmall: AppStyles.headlineSmall(color: AppColors.textColorDark),
        titleLarge: AppStyles.titleLarge(color: AppColors.textColorDark),
        titleMedium: AppStyles.titleMedium(color: AppColors.textColorDark),
        titleSmall: AppStyles.titleSmall(color: AppColors.textColorDark),
        bodyLarge: AppStyles.bodyLarge(color: AppColors.textColorDark),
        bodyMedium: AppStyles.bodyMedium(color: AppColors.textColorDark),
        bodySmall: AppStyles.bodySmall(color: AppColors.textColorDark),
        labelLarge: AppStyles.labelLarge(color: AppColors.textColorDark),
        labelMedium: AppStyles.labelMedium(color: AppColors.textColorDark),
        labelSmall: AppStyles.labelSmall(color: AppColors.textColorDark),
        appBorderRadius: appBorderRadius,
        controlHeight: AppSizing.size24,
        verticalMargin: AppSpacing.space8,
        horizontalMargin: AppSpacing.space8,
        spacingXSmall: AppSpacing.xSmall,
        spacingSmall: AppSpacing.small,
        spacingMedium: AppSpacing.medium,
        spacingLarge: AppSpacing.large,
        elevationSmall: AppElevation.small,
        elevationMedium: AppElevation.medium,
        elevationLarge: AppElevation.large,
      ),
    ],
  );
}
