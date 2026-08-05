import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/task_enums.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/extensions/date_time_extensions.dart';
import 'package:manage_app/core/resources/app_assets.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/core/services/task_service.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/shared/widgets/app_body_column.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_svg_icon.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:manage_app/features/task/models/task_model.dart';
import 'package:manage_app/features/task/providers/task_provider.dart';
import 'package:manage_app/features/task/screens/task_form_screen.dart';
import 'package:manage_app/features/task/widgets/task_priority_badge.dart';
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
  String get description => _task.description ?? AppStrings.noDescriptionProvided;
  String get createdAt => _task.createdAt?.formattedDateTime ?? AppStrings.noCreationDate;
  String get dueDate => _task.dueDate != null ? _task.dueDate!.formattedDateTime : AppStrings.noDueDate;

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
    final result = await navigationService.push<TaskChangeResult>(context, TaskFormScreen(task: _task));
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
      final updated = await context.read<TaskProvider>().updateTask(id: _task.id!, status: TaskStatus.completed);
      if (!mounted) return;
      navigationService.pop(context, TaskChangeSaved(updated));
    } on TaskServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final assigneeName = _resolveAssigneeName(context.watch<GroupProvider>());

    return AppScaffold(
      appBar: ScreenAppBar(title: AppStrings.taskDetails, onBackPressed: () => navigationService.pop(context, _pendingResult)),
      body: SingleChildScrollView(
        child: AppBodyColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: theme.spacingMedium ?? 16,
          children: [
            TaskPriorityBadge(priority: priority, large: true),
            Text(title, style: theme.headlineSmall?.copyWith(decoration: _isCompleted ? TextDecoration.lineThrough : null)),
            if (_isCompleted)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 18, color: colorScheme.primary),
                  SizedBox(width: theme.spacingXSmall ?? 4),
                  Text(
                    AppStrings.completed,
                    style: theme.labelLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            Text(description, style: theme.bodyLarge),
            Divider(color: colorScheme.outlineVariant),
            if (assigneeName != null)
              _DetailRow(
                icon: Icon(Icons.person, size: 18, color: colorScheme.outline),
                label: AppStrings.assignedToLabel,
                value: assigneeName,
              ),
            _DetailRow(
              icon: AppSvgIcon(SvgIcons.calendar, size: 18, color: colorScheme.outline),
              label: AppStrings.due,
              value: dueDate,
            ),
            _DetailRow(
              icon: Icon(Icons.access_time, size: 18, color: colorScheme.outline),
              label: AppStrings.created,
              value: createdAt,
            ),
            SizedBox(height: theme.spacingLarge ?? 24),
            Row(
              spacing: theme.spacingMedium ?? 16,
              children: [
                Expanded(
                  child: AppButton.secondary(label: AppStrings.edit, onPressed: _isClosing ? null : _editTask),
                ),
                Expanded(
                  child: AppButton.primary(
                    label: _isCompleted ? AppStrings.completed : (_isClosing ? AppStrings.closing : AppStrings.closeTask),
                    onPressed: (_isCompleted || _isClosing) ? null : _closeTask,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        icon,
        SizedBox(width: theme.spacingSmall ?? 8),
        Text('$label: ', style: theme.bodyMedium?.copyWith(color: colorScheme.outline)),
        Text(value, style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
