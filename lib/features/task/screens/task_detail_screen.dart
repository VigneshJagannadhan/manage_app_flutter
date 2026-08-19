import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/task_enums.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/extensions/date_time_extensions.dart';
import 'package:manage_app/core/extensions/string_extensions.dart';
import 'package:manage_app/core/resources/app_assets.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/core/services/task_service.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/shared/widgets/app_body_column.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_svg_icon.dart';
import 'package:manage_app/features/shared/widgets/info_card.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:manage_app/features/task/models/task_model.dart';
import 'package:manage_app/features/task/providers/task_provider.dart';
import 'package:manage_app/features/task/screens/task_form_screen.dart';
import 'package:manage_app/features/task/widgets/task_priority_badge.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:manage_app/features/shared/widgets/text/headline_text.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';
import 'package:provider/provider.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task});

  final TaskModel task;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TaskModel _task = widget.task;
  TaskChangeResult? _pendingResult;
  bool _isClosing = false;

  bool get _isCompleted => _task.status == TaskStatus.completed;
  TaskPriority get priority => _task.priority ?? TaskPriority.medium;
  String get title => _task.title ?? AppStrings.untitledTask;
  String get description =>
      _task.description ?? AppStrings.noDescriptionProvided;
  String get createdAt =>
      _task.createdAt?.formattedDateTime ?? AppStrings.noCreationDate;
  String get dueDate => _task.dueDate != null
      ? _task.dueDate!.formattedDateTime
      : AppStrings.noDueDate;

  @override
  void initState() {
    super.initState();
    final groupId = _task.groupId;
    if (groupId == null) return;
    final groupProvider = context.read<GroupProvider>();
    if (groupProvider.membersFor(groupId).isEmpty) {
      groupProvider.loadMembers(groupId);
    }
  }

  String? _resolveAssigneeName(GroupProvider groupProvider) {
    final assignedTo = _task.assignedTo;
    final groupId = _task.groupId;
    if (assignedTo == null) return null;
    if (groupId != null) {
      for (final member in groupProvider.membersFor(groupId)) {
        if (member.userId == assignedTo) return member.name;
      }
    }
    return assignedTo;
  }

  Future<void> _editTask() async {
    final result = await navigationService.push<TaskChangeResult>(
      context,
      TaskFormScreen(task: _task),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case TaskChangeSaved(:final task):
        setState(() {
          _task = task;
          _pendingResult = result;
        });
      case TaskChangeDeleted():
        navigationService.pop(context, result);
    }
  }

  Future<void> _closeTask() async {
    setState(() => _isClosing = true);
    try {
      final updated = await context.read<TaskProvider>().updateTask(
        id: _task.id!,
        status: TaskStatus.completed,
      );
      if (!mounted) return;
      navigationService.pop(context, TaskChangeSaved(updated));
    } on TaskServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final assigneeName = _resolveAssigneeName(context.watch<GroupProvider>());
    final priorityColor = TaskPriorityBadge.colorFor(priority, colorScheme);

    return AppScaffold(
      appBar: ScreenAppBar(
        title: AppStrings.taskDetails,
        onBackPressed: () => navigationService.pop(context, _pendingResult),
      ),
      scrollable: true,
      body: AppBodyColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.spacingMedium ?? 16,
        children: [
          _PriorityCard(
            priority: priority,
            color: priorityColor,
            title: title,
            description: description,
            isCompleted: _isCompleted,
          ),
          if (_isCompleted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 18, color: colorScheme.primary),
                SizedBox(width: theme.spacingXSmall ?? 4),
                LabelText.large(
                  AppStrings.completed,
                  color: colorScheme.primary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          InfoCard(
            children: [
              if (assigneeName != null)
                InfoRow(
                  icon: const Icon(Icons.person),
                  label: AppStrings.assignedToLabel,
                  value: assigneeName,
                ),
              InfoRow(
                icon: AppSvgIcon(SvgIcons.calendar),
                label: AppStrings.due,
                value: dueDate,
                // Calls out the due date as the field most tied to priority/urgency.
                iconColor: priorityColor,
              ),
              InfoRow(
                icon: const Icon(Icons.access_time),
                label: AppStrings.created,
                value: createdAt,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(theme.horizontalMargin ?? 16),
        child: Row(
          spacing: theme.spacingMedium ?? 16,
          children: [
            Expanded(
              child: AppButton.secondary(
                label: AppStrings.edit,
                onPressed: _isClosing ? null : _editTask,
                color: priorityColor,
              ),
            ),
            Expanded(
              child: AppButton.primary(
                label: _isCompleted
                    ? AppStrings.completed
                    : (_isClosing ? AppStrings.closing : AppStrings.closeTask),
                onPressed: (_isCompleted || _isClosing) ? null : _closeTask,
                color: priorityColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width priority banner: a solid color strip + tinted background,
/// replacing the plain priority pill so priority is legible at a glance.
class _PriorityCard extends StatelessWidget {
  const _PriorityCard({
    required this.priority,
    required this.color,
    required this.title,
    required this.description,
    required this.isCompleted,
  });

  final TaskPriority priority;
  final Color color;
  final String title;
  final String description;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.appBorderRadius ?? 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Container(
                color: color.withValues(alpha: 0.1),
                padding: EdgeInsets.all(theme.horizontalMargin ?? 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: theme.spacingSmall ?? 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, size: 14, color: color),
                        SizedBox(width: theme.spacingXSmall ?? 4),
                        LabelText.small(
                          '${priority.name.toTitleCase} Priority'.toUpperCase(),
                          color: color,
                          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    HeadlineText.small(
                      title,
                      style: TextStyle(decoration: isCompleted ? TextDecoration.lineThrough : null),
                    ),
                    BodyText.medium(description, color: colorScheme.onSurfaceVariant),
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
