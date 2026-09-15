import 'package:flutter/material.dart';
import 'package:huddle/core/enums/task_enums.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/resources/app_assets.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/features/shared/widgets/app_card.dart';
import 'package:huddle/features/shared/widgets/app_svg_icon.dart';
import 'package:huddle/features/shared/widgets/app_tile_pill.dart';
import 'package:huddle/features/task/models/task_model.dart';
import 'package:huddle/features/task/providers/task_provider.dart';
import 'package:huddle/features/task/widgets/task_priority_badge.dart';
import 'package:huddle/features/shared/widgets/text/body_text.dart';
import 'package:huddle/features/shared/widgets/text/label_text.dart';
import 'package:huddle/features/shared/widgets/text/title_text.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.groupName,
    this.onTap,
    this.onEdit,
    this.syncState = TaskSyncState.synced,
    this.onTapFailedSync,
  });

  final TaskModel task;
  // Shown only in "all groups" mode, where tasks from multiple groups are mixed together.
  final String? groupName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  // Offline write-queue status for this task - see TaskProvider.syncStateFor.
  final TaskSyncState syncState;
  // Opens the retry/discard action sheet - only meaningful when syncState is `failed`.
  final VoidCallback? onTapFailedSync;

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
    final margin = theme.horizontalMargin;

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
          Row(
            children: [
              TaskPriorityBadge(priority: priority),
              const Spacer(),
              if (groupName != null) ...[
                Flexible(
                  child: LabelText.small(
                    groupName!,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    color: Colors.white.withValues(alpha: 0.85),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(width: theme.spacingSmall),
              ],
              if (syncState != TaskSyncState.synced) _TaskSyncBadge(state: syncState, onTapFailed: onTapFailedSync),
            ],
          ),
          SizedBox(height: theme.spacingSmall),
          TitleText.medium(
            title,
            color: Colors.white,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: theme.spacingXSmall),
          BodyText.medium(description, color: Colors.white.withValues(alpha: 0.72)),
          if (task.status == TaskStatus.completed) ...[
            SizedBox(height: theme.spacingSmall),
            AppTilePill(
              icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
              label: AppStrings.closed,
              color: theme.successColor,
            ),
          ] else if (task.dueDate != null) ...[
            SizedBox(height: theme.spacingSmall),
            AppTilePill(
              icon: const AppSvgIcon(SvgIcons.calendar, size: 16, color: Colors.white),
              label: '${AppStrings.due}: ${task.dueDate!.formattedDateTime}',
            ),
          ],
        ],
      ),
    );
  }
}

/// A small spinner while a queued write is still in flight, or a tappable warning icon
/// (opens a retry/discard action sheet via [onTapFailed]) once it's permanently failed.
class _TaskSyncBadge extends StatelessWidget {
  const _TaskSyncBadge({required this.state, this.onTapFailed});

  final TaskSyncState state;
  final VoidCallback? onTapFailed;

  @override
  Widget build(BuildContext context) {
    if (state == TaskSyncState.pending) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTapFailed,
      child: const Padding(
        padding: EdgeInsets.all(2),
        child: Icon(Icons.error_outline, size: 18, color: Colors.white),
      ),
    );
  }
}
