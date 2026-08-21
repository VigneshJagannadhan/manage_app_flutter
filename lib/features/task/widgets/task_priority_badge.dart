import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/task_enums.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';

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
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacingSmall ?? 8,
        vertical: (theme.spacingXSmall ?? 4) / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(theme.appBorderRadius ?? 8),
      ),
      child: LabelText.small(
        priority.name.toUpperCase(),
        color: Colors.white,
        style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }
}
