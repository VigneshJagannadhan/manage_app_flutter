import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';

/// Two-way toggle between the active group and "All Groups", with a sliding
/// selection indicator instead of the instant-swap look of [SegmentedButton].
class GroupScopeToggle extends StatelessWidget {
  const GroupScopeToggle({super.key, required this.activeGroupLabel, required this.showAllGroups, required this.onChanged});

  final String activeGroupLabel;
  final bool showAllGroups;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final outerRadius = BorderRadius.circular((theme.appBorderRadius ?? 12) * 0.9);
    final trackPadding = theme.spacingXSmall ?? 4;
    final innerRadius = BorderRadius.circular(((theme.appBorderRadius ?? 12) * 0.9) - trackPadding);

    return Container(
      height: theme.controlHeight ?? 48,
      padding: EdgeInsets.all(trackPadding),
      decoration: BoxDecoration(color: colorScheme.surfaceContainer, borderRadius: outerRadius, border: Border.all(color: theme.outlineColor ?? colorScheme.outline)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            alignment: showAllGroups ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: colorScheme.primary, borderRadius: innerRadius)),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Segment(label: activeGroupLabel, selected: !showAllGroups, borderRadius: innerRadius, onTap: () => onChanged(false)),
              ),
              Expanded(
                child: _Segment(label: AppStrings.allGroups, selected: showAllGroups, borderRadius: innerRadius, onTap: () => onChanged(true)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.borderRadius, required this.onTap});

  final String label;
  final bool selected;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              style:
                  Theme.of(context).textTheme.labelLarge?.copyWith(color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant, fontWeight: selected ? FontWeight.w700 : FontWeight.w500) ??
                  const TextStyle(),
              child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          ),
        ),
      ),
    );
  }
}
