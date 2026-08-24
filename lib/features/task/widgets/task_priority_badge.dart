import 'package:flutter/material.dart';
import 'package:huddle/core/enums/task_enums.dart';
import 'package:huddle/features/shared/widgets/app_tile_badge.dart';

/// Priority pill shown on the task list tile, overlaid on that tile's
/// priority-colored gradient background.
class TaskPriorityBadge extends StatelessWidget {
  const TaskPriorityBadge({super.key, required this.priority});

  final TaskPriority priority;

  // `tertiary` isn't set explicitly in the app's ColorScheme (see AppThemes),
  // so it falls back to Material's default muted purple instead of a color
  // that reads as "medium" - `primary` is this app's blue and fits that intent.
  static Color colorFor(TaskPriority priority, ColorScheme colorScheme) => switch (priority) {
    TaskPriority.high => colorScheme.error,
    TaskPriority.medium => colorScheme.primary,
    TaskPriority.low => colorScheme.outline,
  };

  @override
  Widget build(BuildContext context) => AppTileBadge(label: priority.name);
}
