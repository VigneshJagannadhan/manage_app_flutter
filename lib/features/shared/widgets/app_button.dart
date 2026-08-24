import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';

enum _AppButtonVariant { primary, secondary, destructive }

class AppButton extends StatelessWidget {
  // `color` overrides the variant's default accent - e.g. tinting a button to match a
  // priority/category color instead of the theme's primary color.
  const AppButton.primary({super.key, required this.label, required this.onPressed, this.color}) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({super.key, required this.label, required this.onPressed, this.color}) : _variant = _AppButtonVariant.secondary;

  const AppButton.destructive({super.key, required this.label, required this.onPressed})
    : _variant = _AppButtonVariant.destructive,
      color = null;

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final _AppButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final outlineColor = theme.outlineColor;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.appBorderRadius));

    final child = Text(label);
    final button = switch (_variant) {
      _AppButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: shape,
          backgroundColor: color,
          foregroundColor: color != null ? _onColorFor(color!) : null,
        ),
        child: child,
      ),
      _AppButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(shape: shape, foregroundColor: color, side: BorderSide(color: color ?? outlineColor)),
        child: child,
      ),
      _AppButtonVariant.destructive => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(shape: shape, backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
        child: child,
      ),
    };

    return Semantics(
      button: true,
      label: label,
      child: SizedBox(width: double.infinity, height: theme.controlHeight, child: button),
    );
  }

  Color _onColorFor(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark ? Colors.white : Colors.black;
}
