import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/features/shared/widgets/text/body_text.dart';

/// Fully-rounded translucent-white pill overlaid on a gradient tile surface
/// (e.g. [TaskTile], [ExpenseTile]) - used to call out a key fact like a due
/// date or amount.
class AppTilePill extends StatelessWidget {
  const AppTilePill({super.key, required this.label, this.icon, this.color});

  final String label;
  final Widget? icon;

  /// Background color override - defaults to the translucent-white fill used
  /// for neutral facts like a due date. Pass a solid color (e.g. a success
  /// green) to call out a distinct state like a closed/completed task.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacingSmall,
        vertical: theme.spacingXSmall,
      ),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(theme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, SizedBox(width: theme.spacingXSmall)],
          BodyText.medium(label, color: Colors.white, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
