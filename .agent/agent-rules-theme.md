# Agent Rules: Flutter Theme Management

**Version:** 1.0  
**Status:** Active  
**Purpose:** Guidelines for all agents working with Flutter theme extensions and context usage

---

## Core Philosophy

**Keep theme extensions lean and focused on design tokens only.**

A theme should contain:
- ✅ Core brand colors
- ✅ Typography scales (not individual screen text styles)
- ✅ Spacing/sizing scales (small, medium, large)
- ✅ Reusable border radius values
- ✅ Global shadows/elevations

A theme should NOT contain:
- ❌ Screen-specific variables (e.g., `homeScreenBackgroundColor`)
- ❌ Component-specific properties (e.g., `buttonPrimaryColor`)
- ❌ One-off design decisions
- ❌ View model data in theme
- ❌ Animation durations

---

## Naming Conventions

### Color Naming

**Format:** `<semantic><qualifier>`

```dart
// ✅ CORRECT - Semantic naming
final Color primary;              // Brand primary
final Color secondary;            // Brand secondary
final Color success;              // Success/positive action
final Color warning;              // Warning/caution
final Color error;                // Error/destructive action
final Color info;                 // Info/neutral action
final Color surfacePrimary;       // Main surface
final Color surfaceSecondary;     // Secondary surface
final Color outline;              // Borders/dividers

// ❌ WRONG - Color-based naming
final Color red;                  // What's it for?
final Color blue;                 // What's it for?
final Color buttonColor;          // Too specific
final Color homeScreenBackground; // Screen-specific
final Color darkGreen;            // Ambiguous
```

### Spacing/Size Naming

**Format:** `<property><scale>`

```dart
// ✅ CORRECT - Scale-based
final double spacingXSmall;       // 4px
final double spacingSmall;        // 8px
final double spacingMedium;       // 16px
final double spacingLarge;        // 24px
final double spacingXLarge;       // 32px

final double radiusSmall;         // 4px
final double radiusMedium;        // 8px
final double radiusLarge;         // 12px
final double radiusXLarge;        // 20px

// ❌ WRONG - Arbitrary naming
final double padding8;            // Magic number
final double cornerRadius;        // Singular, ambiguous
final double buttonPadding;       // Component-specific
final double spacing;             // Which size?
```

### Typography Naming

**Format:** Follow Material Design 3 scale**

```dart
// ✅ CORRECT - Material Design 3
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

// ❌ WRONG - Ambiguous naming
final TextStyle heading;          // Which size?
final TextStyle screenTitle;      // Screen-specific
final TextStyle buttonText;       // Component-specific
final TextStyle large;            // Too generic
final TextStyle text16;           // Magic number
```

### Boolean/Condition Naming

**Format:** `is<Condition>`

```dart
// ✅ CORRECT
bool get isDarkMode { /* ... */ }
bool get isHighContrast { /* ... */ }

// ❌ WRONG
bool get darkMode { /* ... */ }
bool get dark { /* ... */ }
bool get shouldUseDarkTheme { /* ... */ }
```

---

## Minimal Theme Structure

### Recommended Theme Properties

```dart
class AppTheme extends ThemeExtension<AppTheme> {
  // COLORS (15-20 max)
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color outline;
  final Color outlineVariant;
  
  // TYPOGRAPHY (15 max - Material 3)
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
  
  // SPACING (5-8 max)
  final double spacingXSmall;    // 4px
  final double spacingSmall;     // 8px
  final double spacingMedium;    // 16px
  final double spacingLarge;     // 24px
  final double spacingXLarge;    // 32px
  
  // RADIUS (4-5 max)
  final double radiusSmall;      // 4px
  final double radiusMedium;     // 8px
  final double radiusLarge;      // 12px
  final double radiusXLarge;     // 20px
  
  // ELEVATION (optional - 3-5)
  final double elevationSmall;   // 2dp
  final double elevationMedium;  // 6dp
  final double elevationLarge;   // 12dp
  
  // That's it! 40-50 properties max
  
  const AppTheme({
    // ... required parameters
  });
  
  @override
  AppTheme copyWith({ /* ... */ }) { /* ... */ }
  
  @override
  AppTheme lerp(AppTheme? other, double t) { /* ... */ }
}
```

### What NOT to Include

```dart
// ❌ NEVER add these to theme
final Color homeScreenBackgroundColor;     // Screen-specific
final Color loginButtonBackgroundColor;    // Component-specific
final double cardPaddingLarge;             // Component-specific
final TextStyle homeScreenTitleStyle;      // Screen-specific
final EdgeInsets homeScreenMargins;        // View-specific
final int animationDurationMs;             // Animation config
final VoidCallback onThemeChange;          // Callbacks
final List<String> supportedLanguages;     // App config
```

---

## Usage Patterns

### Pattern 1: Use Theme Directly in Widgets

```dart
// ✅ CORRECT - Let component decide how to use theme tokens
class SuccessButton extends StatelessWidget {
  const SuccessButton({required this.label});
  
  final String label;
  
  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.success,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacingLarge,
          vertical: theme.spacingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radiusMedium),
        ),
      ),
      onPressed: () {},
      child: Text(label, style: theme.labelLarge),
    );
  }
}

// ❌ WRONG - Creating screen/component-specific theme properties
class SuccessButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.buttonSuccessBackgroundColor,  // ❌ Too specific
        padding: EdgeInsets.symmetric(
          horizontal: theme.buttonPaddingHorizontal,         // ❌ Too specific
          vertical: theme.buttonPaddingVertical,             // ❌ Too specific
        ),
      ),
      child: Text(label, style: theme.buttonTextStyle),      // ❌ Too specific
    );
  }
}
```

### Pattern 2: Compose from Tokens

```dart
// ✅ CORRECT - Reuse tokens in multiple contexts
class CardWidget extends StatelessWidget {
  const CardWidget({required this.child});
  
  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    
    return Container(
      padding: EdgeInsets.all(theme.spacingMedium),
      decoration: BoxDecoration(
        color: theme.surfaceSecondary,
        borderRadius: BorderRadius.circular(theme.radiusLarge),
        border: Border.all(color: theme.outline),
      ),
      child: child,
    );
  }
}

// This same card can be used anywhere without modification
// Theme tokens are reused but context defines purpose
```

### Pattern 3: Extend in Components

```dart
// ✅ CORRECT - Create reusable component styles from theme
class ComponentStyles {
  static BoxDecoration cardDecoration(BuildContext context) {
    final theme = context.appTheme;
    return BoxDecoration(
      color: theme.surfaceSecondary,
      borderRadius: BorderRadius.circular(theme.radiusLarge),
      border: Border.all(color: theme.outline),
    );
  }
  
  static ButtonStyle successButtonStyle(BuildContext context) {
    final theme = context.appTheme;
    return ElevatedButton.styleFrom(
      backgroundColor: theme.success,
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacingLarge,
        vertical: theme.spacingMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.radiusMedium),
      ),
    );
  }
}

// Usage
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ComponentStyles.successButtonStyle(context),
      onPressed: () {},
      child: const Text('Click me'),
    );
  }
}
```

---

## Context Extension Rules

### Rule 1: Only One Theme Extension

```dart
extension AppThemeContextExtension on BuildContext {
  /// Access the app theme
  AppTheme get appTheme {
    return Theme.of(this).extension<AppTheme>()!;
  }
  
  /// Safe access to theme (rarely needed)
  AppTheme? get appThemeSafe {
    return Theme.of(this).extension<AppTheme>();
  }
  
  /// Check if dark mode
  bool get isDarkMode {
    return Theme.of(this).brightness == Brightness.dark;
  }
}
```

**That's it. Don't create separate extensions for colors, spacing, etc.**

### Rule 2: Use Consistently

```dart
// ✅ ALWAYS use extension
final theme = context.appTheme;

// ❌ NEVER use direct access
final theme = Theme.of(context).extension<AppTheme>()!;
```

### Rule 3: New Widgets in `lib/features/shared/widgets` Must Source Theme Values

Every new widget added to this folder must pull its design-token values (colors,
spacing, radius, elevation, typography) from `context.appTheme` instead of
hardcoding literals - run each value through the Decision Framework below
before hardcoding it.

Constructor defaults can't call `context.appTheme` (they must be compile-time
constants), so make the parameter nullable and resolve the fallback in `build()`:

```dart
// ✅ CORRECT
class SomeCard extends StatelessWidget {
  const SomeCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Padding(padding: padding ?? EdgeInsets.all(theme.horizontalMargin ?? 16), child: child);
  }
}

// ❌ WRONG - can't reference context in a const default, so don't fall back to a bare literal instead
class SomeCard extends StatelessWidget {
  const SomeCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  // ...
}
```

Genuinely one-off/component-specific values (per the Decision Framework) are
still fine to leave as literals - flag them during review rather than forcing
a theme token that doesn't fit.

---

## File Structure

```
lib/
├── theme/
│   ├── app_theme.dart           # AppTheme class only
│   └── app_themes.dart          # Light & dark instances
├── extensions/
│   └── app_theme_context.dart   # Context extension only
├── components/
│   └── component_styles.dart    # Optional: reusable component decorations
└── pages/
    └── (your screens)
```

**Keep it minimal. Three files max for theme.**

---

## Do's and Don'ts

### DO ✅

- ✅ Create theme for design tokens only (colors, typography, spacing)
- ✅ Use consistent semantic naming
- ✅ Follow Material Design 3 scale
- ✅ Keep properties count under 50
- ✅ Compose component styles from tokens
- ✅ Cache theme reference: `final theme = context.appTheme;`
- ✅ Create both light and dark variants
- ✅ Use proper color contrast
- ✅ Keep texture and elevation simple

### DON'T ❌

- ❌ Add screen-specific variables
- ❌ Add component-specific variables
- ❌ Name by color value (use semantic names)
- ❌ Create 100+ properties
- ❌ Add animation config to theme
- ❌ Add callbacks to theme
- ❌ Store view model data in theme
- ❌ Use abbreviations in names
- ❌ Create separate extensions for each concern
- ❌ Add properties you think "might be useful later"

---

## Minimal Example

### Step 1: Define Theme

**lib/theme/app_theme.dart**
```dart
import 'package:flutter/material.dart';

class AppTheme extends ThemeExtension<AppTheme> {
  // Colors
  final Color primary;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color outline;
  
  // Typography
  final TextStyle headlineLarge;
  final TextStyle headlineSmall;
  final TextStyle bodyLarge;
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  
  // Spacing
  final double spacingSmall;
  final double spacingMedium;
  final double spacingLarge;
  
  // Radius
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;
  
  const AppTheme({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.outline,
    required this.headlineLarge,
    required this.headlineSmall,
    required this.bodyLarge,
    required this.bodySmall,
    required this.labelLarge,
    required this.spacingSmall,
    required this.spacingMedium,
    required this.spacingLarge,
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
  });
  
  @override
  AppTheme copyWith({
    Color? primary,
    Color? secondary,
    Color? success,
    Color? warning,
    Color? error,
    Color? surfacePrimary,
    Color? surfaceSecondary,
    Color? outline,
    TextStyle? headlineLarge,
    TextStyle? headlineSmall,
    TextStyle? bodyLarge,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    double? spacingSmall,
    double? spacingMedium,
    double? spacingLarge,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
  }) {
    return AppTheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      outline: outline ?? this.outline,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineSmall: headlineSmall ?? this.headlineSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      spacingSmall: spacingSmall ?? this.spacingSmall,
      spacingMedium: spacingMedium ?? this.spacingMedium,
      spacingLarge: spacingLarge ?? this.spacingLarge,
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radiusMedium: radiusMedium ?? this.radiusMedium,
      radiusLarge: radiusLarge ?? this.radiusLarge,
    );
  }
  
  @override
  AppTheme lerp(AppTheme? other, double t) {
    if (other is! AppTheme) return this;
    return AppTheme(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      error: Color.lerp(error, other.error, t) ?? error,
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t) ?? surfacePrimary,
      surfaceSecondary: Color.lerp(surfaceSecondary, other.surfaceSecondary, t) ?? surfaceSecondary,
      outline: Color.lerp(outline, other.outline, t) ?? outline,
      headlineLarge: TextStyle.lerp(headlineLarge, other.headlineLarge, t) ?? headlineLarge,
      headlineSmall: TextStyle.lerp(headlineSmall, other.headlineSmall, t) ?? headlineSmall,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t) ?? bodyLarge,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t) ?? bodySmall,
      labelLarge: TextStyle.lerp(labelLarge, other.labelLarge, t) ?? labelLarge,
      spacingSmall: lerpDouble(spacingSmall, other.spacingSmall, t) ?? spacingSmall,
      spacingMedium: lerpDouble(spacingMedium, other.spacingMedium, t) ?? spacingMedium,
      spacingLarge: lerpDouble(spacingLarge, other.spacingLarge, t) ?? spacingLarge,
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t) ?? radiusSmall,
      radiusMedium: lerpDouble(radiusMedium, other.radiusMedium, t) ?? radiusMedium,
      radiusLarge: lerpDouble(radiusLarge, other.radiusLarge, t) ?? radiusLarge,
    );
  }
}
```

### Step 2: Create Instances

**lib/theme/app_themes.dart**
```dart
import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6200EA),
      brightness: Brightness.light,
    ),
    extensions: [
      AppTheme(
        primary: const Color(0xFF6200EA),
        secondary: const Color(0xFF03DAC6),
        success: const Color(0xFF4CAF50),
        warning: const Color(0xFFFFC107),
        error: const Color(0xFFB00020),
        surfacePrimary: const Color(0xFFFAFAFA),
        surfaceSecondary: const Color(0xFFF5F5F5),
        outline: const Color(0xFFE0E0E0),
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F1F1F),
        ),
        headlineSmall: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F1F1F),
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFF424242),
        ),
        bodySmall: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF757575),
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F1F1F),
        ),
        spacingSmall: 8,
        spacingMedium: 16,
        spacingLarge: 24,
        radiusSmall: 4,
        radiusMedium: 8,
        radiusLarge: 12,
      ),
    ],
  );
  
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFBB86FC),
      brightness: Brightness.dark,
    ),
    extensions: [
      AppTheme(
        primary: const Color(0xFFBB86FC),
        secondary: const Color(0xFF03DAC6),
        success: const Color(0xFF81C784),
        warning: const Color(0xFFFFD54F),
        error: const Color(0xFFCF6679),
        surfacePrimary: const Color(0xFF121212),
        surfaceSecondary: const Color(0xFF1E1E1E),
        outline: const Color(0xFF404040),
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFFEFEFEF),
        ),
        headlineSmall: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFEFEFEF),
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFFBDBDBD),
        ),
        bodySmall: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF9E9E9E),
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFFEFEFEF),
        ),
        spacingSmall: 8,
        spacingMedium: 16,
        spacingLarge: 24,
        radiusSmall: 4,
        radiusMedium: 8,
        radiusLarge: 12,
      ),
    ],
  );
}
```

### Step 3: Context Extension

**lib/extensions/app_theme_context.dart**
```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

extension AppThemeContextExtension on BuildContext {
  AppTheme get appTheme {
    return Theme.of(this).extension<AppTheme>()!;
  }
  
  bool get isDarkMode {
    return Theme.of(this).brightness == Brightness.dark;
  }
}
```

### Step 4: Use in Widgets

**lib/pages/home_page.dart**
```dart
import 'package:flutter/material.dart';
import '../extensions/app_theme_context.dart';

class HomePage extends StatelessWidget {
  const HomePage();
  
  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(theme.spacingLarge),
          decoration: BoxDecoration(
            color: theme.surfaceSecondary,
            borderRadius: BorderRadius.circular(theme.radiusLarge),
            border: Border.all(color: theme.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Welcome', style: theme.headlineLarge),
              SizedBox(height: theme.spacingMedium),
              Text(
                'This is a sample app',
                style: theme.bodyLarge,
              ),
              SizedBox(height: theme.spacingLarge),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.success,
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacingLarge,
                    vertical: theme.spacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(theme.radiusMedium),
                  ),
                ),
                onPressed: () {},
                child: Text('Get Started', style: theme.labelLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Decision Framework

When deciding if something belongs in theme:

1. **Is it a design token?** (color, size, typography)
   - ✅ YES → Add to theme
   
2. **Will it be reused across 3+ screens?**
   - ✅ YES → Add to theme
   - ❌ NO → Keep in component
   
3. **Is it specific to one screen/component?**
   - ✅ YES → Keep out of theme
   
4. **Does it change based on app state/user preference?**
   - ✅ YES (theme mode) → Add to theme
   - ❌ NO (user data) → Keep out of theme

---

## Quick Checklist

Before committing theme changes:

- [ ] Naming is semantic, not color-based
- [ ] Properties are under 50 total
- [ ] No screen-specific variables
- [ ] No component-specific variables
- [ ] Light and dark themes have identical properties
- [ ] All values are design tokens
- [ ] No callbacks or functions
- [ ] No app configuration
- [ ] Only one context extension
- [ ] copyWith() implemented
- [ ] lerp() implemented

---

## Summary

**Keep your theme minimal. Add only what is needed.**

- 🎨 Colors: 8-12
- 📝 Typography: 12-15 (Material 3 scale)
- 📏 Spacing: 5
- 🔄 Radius: 4
- **Total: ~35-40 properties**

Everything else is composition in your widgets.
