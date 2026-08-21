import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';

/// Fully-rounded translucent-white pill overlaid on a gradient tile surface
/// (e.g. [TaskTile], [ExpenseTile]) - used to call out a key fact like a due
/// date or amount.
class AppTilePill extends StatelessWidget {
  const AppTilePill({super.key, required this.label, this.icon});

  final String label;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacingSmall ?? 8,
        vertical: theme.spacingXSmall ?? 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, SizedBox(width: theme.spacingXSmall ?? 4)],
          BodyText.medium(label, color: Colors.white, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
