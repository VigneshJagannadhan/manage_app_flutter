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
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';
import 'package:manage_app/features/shared/widgets/text/title_text.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.groupName,
    this.onTap,
    this.onEdit,
  });

  final TaskModel task;
  // Shown only in "all groups" mode, where tasks from multiple groups are mixed together.
  final String? groupName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  String get description =>
      task.description ?? AppStrings.noDescriptionProvided;
  String get title => task.title ?? AppStrings.untitledTask;
  TaskPriority get priority => task.priority ?? TaskPriority.medium;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final priorityColor = TaskPriorityBadge.colorFor(
      task.priority ?? TaskPriority.medium,
      colorScheme,
    );

    final margin = theme.horizontalMargin ?? 16;
    const stripeWidth = 10.0;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Solid priority stripe - more noticeable at a glance than the pill alone.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: stripeWidth,
            child: Container(color: priorityColor),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              stripeWidth + margin,
              margin,
              margin,
              margin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (groupName != null) ...[
                  LabelText.small(
                    groupName!,
                    color: colorScheme.secondary,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: theme.spacingXSmall ?? 4),
                ],
                TitleText.medium(title),
                SizedBox(height: theme.spacingXSmall ?? 4),
                BodyText.medium(
                  description,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: theme.spacingSmall ?? 8),
                if (task.dueDate != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSvgIcon(
                        SvgIcons.calendar,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      SizedBox(width: theme.spacingXSmall ?? 4),
                      BodyText.medium(
                        '${AppStrings.due}: ${task.dueDate!.formattedDateTime}',
                        color: colorScheme.primary,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  SizedBox(height: theme.spacingXSmall ?? 4),
                ],
                BodyText.small(
                  '${AppStrings.created}: ${task.createdAt?.formattedDateTime}',
                  color: colorScheme.outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
