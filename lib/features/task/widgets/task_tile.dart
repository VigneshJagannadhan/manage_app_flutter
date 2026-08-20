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

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(margin),
      // Bold, fully-saturated priority color fading to near-black. The tile
      // is now a colored surface in its own right rather than a tinted
      // neutral card, so text on it below uses fixed light colors instead of
      // theme-derived ones - those wouldn't contrast reliably against this
      // background in light mode.
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [priorityColor, Color.lerp(priorityColor, Colors.black, 0.75)!],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (groupName != null) ...[
            LabelText.small(
              groupName!,
              color: Colors.white.withValues(alpha: 0.85),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: theme.spacingXSmall ?? 4),
          ],
          TaskPriorityBadge(priority: priority),
          SizedBox(height: theme.spacingSmall ?? 8),
          TitleText.medium(
            title,
            color: Colors.white,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: theme.spacingXSmall ?? 4),
          BodyText.medium(description, color: Colors.white.withValues(alpha: 0.72)),
          if (task.dueDate != null) ...[
            SizedBox(height: theme.spacingSmall ?? 8),
            Container(
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
                  const AppSvgIcon(SvgIcons.calendar, size: 16, color: Colors.white),
                  SizedBox(width: theme.spacingXSmall ?? 4),
                  BodyText.medium(
                    '${AppStrings.due}: ${task.dueDate!.formattedDateTime}',
                    color: Colors.white,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
