import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';

/// Small translucent-white tag overlaid on a gradient tile surface (e.g.
/// [TaskTile], [ExpenseTile]) - used to call out a short classifier like
/// priority or category.
class AppTileBadge extends StatelessWidget {
  const AppTileBadge({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacingSmall,
        vertical: (theme.spacingXSmall) / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(theme.appBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            SizedBox(width: (theme.spacingXSmall) / 2),
          ],
          LabelText.small(
            label.toUpperCase(),
            color: Colors.white,
            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
