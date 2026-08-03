import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/task_enums.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/extensions/string_extensions.dart';

/// Priority pill shared by the task list tile and the task detail screen.
class TaskPriorityBadge extends StatelessWidget {
  const TaskPriorityBadge({super.key, required this.priority, this.large = false});

  final TaskPriority priority;
  final bool large;

  static Color colorFor(TaskPriority priority, ColorScheme colorScheme) => switch (priority) {
    TaskPriority.high => colorScheme.error,
    TaskPriority.medium => colorScheme.tertiary,
    TaskPriority.low => colorScheme.outline,
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = colorFor(priority, colorScheme);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? (theme.spacingMedium ?? 16) : (theme.spacingSmall ?? 8),
        vertical: large ? (theme.spacingSmall ?? 8) : (theme.spacingXSmall ?? 4) / 2,
      ),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(theme.appBorderRadius ?? 8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: large ? 20 : 14, color: color),
          SizedBox(width: (theme.spacingXSmall ?? 4) / 2),
          Text(
            priority.name.toTitleCase,
            style: (large ? textTheme.titleMedium : textTheme.labelSmall)?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
