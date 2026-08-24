import 'package:flutter/material.dart';
import 'package:huddle/core/resources/app_fonts.dart';
import 'package:huddle/core/themes/app_styles.dart';
import 'package:huddle/core/themes/constants/app_colors.dart';
import 'package:huddle/core/themes/constants/app_elevation.dart';
import 'package:huddle/core/themes/constants/app_sizing.dart';
import 'package:huddle/core/themes/constants/app_spacing.dart';
import 'package:huddle/core/themes/theme_extensions/app_theme.dart';

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
  ///
  /// Same reasoning applies to primaryContainer/secondaryContainer: left
  /// unset, `secondaryContainer` falls back to `secondary` (the navy accent),
  /// which made SegmentedButton's selected pill render in a different blue
  /// than the avatar/FAB. Both containers are pinned to the primary blue so
  /// every "selected" chip in the app reads as the same accent color.
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: AppColors.primaryColor,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryColor,
    onPrimaryContainer: Colors.white,
    secondary: AppColors.secondaryColor,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.primaryColor,
    onSecondaryContainer: Colors.white,
    surface: AppColors.backgroundColor,
    onSurface: AppColors.textColor,
    outline: AppColors.outlineColor,
    error: AppColors.errorColor,
    onError: Colors.white,
    surfaceContainerLowest: AppColors.surfaceColor,
    surfaceContainerLow: AppColors.surfaceColor,
    surfaceContainer: AppColors.surfaceColor,
    surfaceContainerHigh: AppColors.surfaceColor,
    surfaceContainerHighest: AppColors.surfaceColor,
  );

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: AppColors.primaryColorDark,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryColorDark,
    onPrimaryContainer: Colors.white,
    secondary: AppColors.secondaryColorDark,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.primaryColorDark,
    onSecondaryContainer: Colors.white,
    surface: AppColors.backgroundColorDark,
    onSurface: AppColors.textColorDark,
    outline: AppColors.outlineColorDark,
    error: AppColors.errorColorDark,
    onError: Colors.white,
    surfaceContainerLowest: AppColors.surfaceColorDark,
    surfaceContainerLow: AppColors.surfaceColorDark,
    surfaceContainer: AppColors.surfaceColorDark,
    surfaceContainerHigh: AppColors.surfaceColorDark,
    surfaceContainerHighest: AppColors.surfaceColorDark,
  );

  static const appBorderRadius = AppSizing.size12;
  static const radiusPill = 999.0;
  static const radiusSheet = AppSizing.size20;
  static const listItemGap = AppSpacing.space6;

  /// Backs every default Material widget that doesn't set an explicit style
  /// (SegmentedButton, ChoiceChip, etc.) with [AppStyles] instead of the
  /// Material default typeface, so typography stays consistent without
  /// having to patch each such widget individually.
  static TextTheme _textTheme(Color color, AppFontOption font) => TextTheme(
    displayLarge: AppStyles.displayLarge(color: color, font: font),
    displayMedium: AppStyles.displayMedium(color: color, font: font),
    displaySmall: AppStyles.displaySmall(color: color, font: font),
    headlineLarge: AppStyles.headlineLarge(color: color, font: font),
    headlineMedium: AppStyles.headlineMedium(color: color, font: font),
    headlineSmall: AppStyles.headlineSmall(color: color, font: font),
    titleLarge: AppStyles.titleLarge(color: color, font: font),
    titleMedium: AppStyles.titleMedium(color: color, font: font),
    titleSmall: AppStyles.titleSmall(color: color, font: font),
    bodyLarge: AppStyles.bodyLarge(color: color, font: font),
    bodyMedium: AppStyles.bodyMedium(color: color, font: font),
    bodySmall: AppStyles.bodySmall(color: color, font: font),
    labelLarge: AppStyles.labelLarge(color: color, font: font),
    labelMedium: AppStyles.labelMedium(color: color, font: font),
    labelSmall: AppStyles.labelSmall(color: color, font: font),
  );

  /// Light Theme
  static ThemeData lightTheme({required AppFontOption font}) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: AppColors.backgroundColor,
    textTheme: _textTheme(AppColors.textColor, font),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: AppColors.primaryColor)),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(color: states.contains(WidgetState.selected) ? AppColors.primaryColor : AppColors.outlineColor),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppStyles.labelMedium(
          color: states.contains(WidgetState.selected) ? AppColors.primaryColor : AppColors.outlineColor,
          font: font,
        ),
      ),
    ),
    extensions: [
      AppTheme(
        primaryColor: AppColors.primaryColor,
        secondaryColor: AppColors.secondaryColor,
        outlineColor: AppColors.outlineColor,
        successColor: AppColors.successColor,
        displayLarge: AppStyles.displayLarge(color: AppColors.textColor, font: font),
        displayMedium: AppStyles.displayMedium(color: AppColors.textColor, font: font),
        displaySmall: AppStyles.displaySmall(color: AppColors.textColor, font: font),
        headlineLarge: AppStyles.headlineLarge(color: AppColors.textColor, font: font),
        headlineMedium: AppStyles.headlineMedium(color: AppColors.textColor, font: font),
        headlineSmall: AppStyles.headlineSmall(color: AppColors.textColor, font: font),
        titleLarge: AppStyles.titleLarge(color: AppColors.textColor, font: font),
        titleMedium: AppStyles.titleMedium(color: AppColors.textColor, font: font),
        titleSmall: AppStyles.titleSmall(color: AppColors.textColor, font: font),
        bodyLarge: AppStyles.bodyLarge(color: AppColors.textColor, font: font),
        bodyMedium: AppStyles.bodyMedium(color: AppColors.textColor, font: font),
        bodySmall: AppStyles.bodySmall(color: AppColors.textColor, font: font),
        labelLarge: AppStyles.labelLarge(color: AppColors.textColor, font: font),
        labelMedium: AppStyles.labelMedium(color: AppColors.textColor, font: font),
        labelSmall: AppStyles.labelSmall(color: AppColors.textColor, font: font),
        appBorderRadius: appBorderRadius,
        radiusPill: radiusPill,
        radiusSheet: radiusSheet,
        controlHeight: AppSizing.size24,
        verticalMargin: AppSpacing.space8,
        horizontalMargin: AppSpacing.space8,
        spacingXSmall: AppSpacing.xSmall,
        spacingSmall: AppSpacing.small,
        spacingMedium: AppSpacing.medium,
        spacingLarge: AppSpacing.large,
        listItemGap: listItemGap,
        elevationSmall: AppElevation.small,
        elevationMedium: AppElevation.medium,
        elevationLarge: AppElevation.large,
      ),
    ],
  );

  /// Dark Theme
  static ThemeData darkTheme({required AppFontOption font}) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: AppColors.backgroundColorDark,
    textTheme: _textTheme(AppColors.textColorDark, font),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: AppColors.primaryColorDark)),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(color: states.contains(WidgetState.selected) ? AppColors.primaryColorDark : AppColors.outlineColorDark),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppStyles.labelMedium(
          color: states.contains(WidgetState.selected) ? AppColors.primaryColorDark : AppColors.outlineColorDark,
          font: font,
        ),
      ),
    ),
    extensions: [
      AppTheme(
        primaryColor: AppColors.primaryColorDark,
        secondaryColor: AppColors.secondaryColorDark,
        outlineColor: AppColors.outlineColorDark,
        successColor: AppColors.successColorDark,
        displayLarge: AppStyles.displayLarge(color: AppColors.textColorDark, font: font),
        displayMedium: AppStyles.displayMedium(color: AppColors.textColorDark, font: font),
        displaySmall: AppStyles.displaySmall(color: AppColors.textColorDark, font: font),
        headlineLarge: AppStyles.headlineLarge(color: AppColors.textColorDark, font: font),
        headlineMedium: AppStyles.headlineMedium(color: AppColors.textColorDark, font: font),
        headlineSmall: AppStyles.headlineSmall(color: AppColors.textColorDark, font: font),
        titleLarge: AppStyles.titleLarge(color: AppColors.textColorDark, font: font),
        titleMedium: AppStyles.titleMedium(color: AppColors.textColorDark, font: font),
        titleSmall: AppStyles.titleSmall(color: AppColors.textColorDark, font: font),
        bodyLarge: AppStyles.bodyLarge(color: AppColors.textColorDark, font: font),
        bodyMedium: AppStyles.bodyMedium(color: AppColors.textColorDark, font: font),
        bodySmall: AppStyles.bodySmall(color: AppColors.textColorDark, font: font),
        labelLarge: AppStyles.labelLarge(color: AppColors.textColorDark, font: font),
        labelMedium: AppStyles.labelMedium(color: AppColors.textColorDark, font: font),
        labelSmall: AppStyles.labelSmall(color: AppColors.textColorDark, font: font),
        appBorderRadius: appBorderRadius,
        radiusPill: radiusPill,
        radiusSheet: radiusSheet,
        controlHeight: AppSizing.size24,
        verticalMargin: AppSpacing.space8,
        horizontalMargin: AppSpacing.space8,
        spacingXSmall: AppSpacing.xSmall,
        spacingSmall: AppSpacing.small,
        spacingMedium: AppSpacing.medium,
        spacingLarge: AppSpacing.large,
        listItemGap: listItemGap,
        elevationSmall: AppElevation.small,
        elevationMedium: AppElevation.medium,
        elevationLarge: AppElevation.large,
      ),
    ],
  );
}
