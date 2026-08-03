import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/task_enums.dart';
import 'package:manage_app/core/extensions/date_time_extensions.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_assets.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/features/shared/widgets/app_card.dart';
import 'package:manage_app/features/shared/widgets/app_svg_icon.dart';
import 'package:manage_app/features/task/models/task_model.dart';
import 'package:manage_app/features/task/widgets/task_priority_badge.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, this.groupName, this.onTap, this.onEdit});

  final TaskModel task;
  // Shown only in "all groups" mode, where tasks from multiple groups are mixed together.
  final String? groupName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  String get description => task.description ?? AppStrings.noDescriptionProvided;
  String get title => task.title ?? AppStrings.untitledTask;
  TaskPriority get priority => task.priority ?? TaskPriority.medium;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final priorityColor = TaskPriorityBadge.colorFor(task.priority ?? TaskPriority.medium, colorScheme);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Solid priority stripe - more noticeable at a glance than the pill alone.
            Container(width: 10, color: priorityColor),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(theme.horizontalMargin ?? 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (groupName != null) ...[
                      Text(groupName!, style: textTheme.labelSmall?.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.w700)),
                      SizedBox(height: theme.spacingXSmall ?? 4),
                    ],
                    Text(title, style: textTheme.titleMedium),
                    SizedBox(height: theme.spacingXSmall ?? 4),
                    Text(description, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    SizedBox(height: theme.spacingSmall ?? 8),
                    if (task.dueDate != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppSvgIcon(SvgIcons.calendar, size: 16, color: colorScheme.primary),
                          SizedBox(width: theme.spacingXSmall ?? 4),
                          Text(
                            '${AppStrings.due}: ${task.dueDate!.formattedDateTime}',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      SizedBox(height: theme.spacingXSmall ?? 4),
                    ],
                    Text(
                      '${AppStrings.created}: ${task.createdAt?.formattedDateTime}',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
