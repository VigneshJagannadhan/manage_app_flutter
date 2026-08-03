import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';

enum _AppButtonVariant { primary, secondary, destructive }

class AppButton extends StatelessWidget {
  const AppButton.primary({super.key, required this.label, required this.onPressed}) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({super.key, required this.label, required this.onPressed}) : _variant = _AppButtonVariant.secondary;

  const AppButton.destructive({super.key, required this.label, required this.onPressed}) : _variant = _AppButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final _AppButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final outlineColor = theme.outlineColor ?? colorScheme.outline;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.appBorderRadius ?? 8));

    final child = Text(label);
    final button = switch (_variant) {
      _AppButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(shape: shape),
        child: child,
      ),
      _AppButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(shape: shape, side: BorderSide(color: outlineColor)),
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
      child: SizedBox(width: double.infinity, height: theme.controlHeight ?? 48, child: button),
    );
  }
}
