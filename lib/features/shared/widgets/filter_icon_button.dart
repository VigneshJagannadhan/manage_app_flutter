import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';

/// Circular icon button that opens a filter/sort bottom sheet - shared by every
/// list screen that has one (tasks, expenses).
class FilterIconButton extends StatelessWidget {
  const FilterIconButton({super.key, required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final size = theme.controlHeight;

    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: colorScheme.primaryContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(Icons.filter_list_rounded, color: colorScheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}
