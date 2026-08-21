import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';

/// A bordered "grouped info card" - visually separates related [InfoRow]s,
/// with a thin divider between each child.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(theme.spacingMedium),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
        borderRadius: BorderRadius.circular(theme.appBorderRadius),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(color: colorScheme.outlineVariant, thickness: 0.5),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A single row within an [InfoCard]: an icon in a tinted box, an uppercase
/// label, and the value beneath it. [iconColor] defaults to a neutral
/// outline tone - pass a semantic color (e.g. a priority color) to call out
/// a specific row.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value, this.iconColor});

  final Widget icon;
  final String label;
  final String value;
  final Color? iconColor;

  static const double _iconBoxSize = 36;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedIconColor = iconColor ?? colorScheme.outline;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _iconBoxSize,
          height: _iconBoxSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: resolvedIconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(theme.appBorderRadius),
          ),
          child: IconTheme.merge(data: IconThemeData(color: resolvedIconColor, size: 18), child: icon),
        ),
        SizedBox(width: theme.spacingSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabelText.small(label.toUpperCase(), color: colorScheme.outline, style: const TextStyle(letterSpacing: 0.5)),
              BodyText.medium(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
