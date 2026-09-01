import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';

/// A day number in a circle, with a pending-task dot beneath it - shared by
/// [TaskDateCarousel]'s week row and [TaskCalendarDrawer]'s month grid so both
/// pick their day the same way.
class TaskDateIndicator extends StatelessWidget {
  const TaskDateIndicator({
    super.key,
    required this.date,
    required this.selected,
    required this.hasPendingTask,
    required this.circleSize,
    this.enabled = true,
  });

  final DateTime date;
  final bool selected;
  final bool hasPendingTask;
  final double circleSize;

  /// Whether this date can be interacted with - `false` dims it (e.g. a date
  /// before the account was created).
  final bool enabled;

  static const _dotSize = 6.0;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = date.isToday;
    final textColor = !enabled
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : selected
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? colorScheme.primary : Colors.transparent,
            // Today keeps its border even when selected - it needs to contrast against
            // the primary fill then, rather than reuse the same primary border color
            // used when unselected (which would be invisible against that fill).
            border: isToday ? Border.all(color: selected ? colorScheme.onPrimary : colorScheme.primary, width: 1.5) : null,
          ),
          child: Text(
            '${date.day}',
            style: theme.labelLarge.copyWith(color: textColor, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
        SizedBox(height: theme.spacingXSmall),
        Container(
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(shape: BoxShape.circle, color: hasPendingTask ? colorScheme.error : Colors.transparent),
        ),
      ],
    );
  }
}
