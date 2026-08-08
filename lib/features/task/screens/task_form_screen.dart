import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/task_enums.dart';
import 'package:manage_app/core/extensions/string_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/core/services/task_service.dart';
import 'package:manage_app/features/auth/providers/auth_provider.dart';
import 'package:manage_app/features/group/models/group_member_model.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/shared/widgets/app_body_column.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_date_picker.dart';
import 'package:manage_app/features/shared/widgets/app_dropdown_field.dart';
import 'package:manage_app/features/shared/widgets/app_time_picker.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_text_field.dart';
import 'package:manage_app/features/shared/widgets/member_dropdown_field.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:manage_app/features/task/models/task_model.dart';
import 'package:manage_app/features/task/providers/task_provider.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';
import 'package:provider/provider.dart';

/// Result of pushing [TaskFormScreen]: either the task was saved, or - when
/// editing - it was deleted instead. A plain nullable [TaskModel] can't carry
/// the delete case since there's no updated task to return.
sealed class TaskChangeResult {
  const TaskChangeResult();
}

class TaskChangeSaved extends TaskChangeResult {
  const TaskChangeSaved(this.task);

  final TaskModel task;
}

class TaskChangeDeleted extends TaskChangeResult {
  const TaskChangeDeleted(this.id);

  final String id;
}

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  /// When set, the screen edits this task instead of creating a new one.
  final TaskModel? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.task?.title);
  late final _descriptionController = TextEditingController(
    text: widget.task?.description,
  );

  bool get _isEditing => widget.task != null;

  late TaskPriority? _selectedPriority = widget.task?.priority;
  late DateTime? _dueDate = widget.task?.dueDate;
  late TimeOfDay? _dueTime = widget.task?.dueDate != null
      ? TimeOfDay.fromDateTime(widget.task!.dueDate!)
      : null;
  bool _isSubmitting = false;
  bool _isDeleting = false;
  GroupMemberModel? _selectedAssignee;

  bool get _isBusy => _isSubmitting || _isDeleting;

  // Assignment only happens at creation - the API doesn't support reassigning an
  // existing task, so an already-created task's assignee is display-only (see TaskDetailScreen).
  String? get _activeGroupId =>
      _isEditing ? null : context.read<GroupProvider>().activeGroupId;

  @override
  void initState() {
    super.initState();
    final groupId = _activeGroupId;
    if (groupId == null) return;
    final groupProvider = context.read<GroupProvider>();
    final existingMembers = groupProvider.membersFor(groupId);
    if (existingMembers.isNotEmpty) {
      _applyDefaultAssignee(existingMembers);
    } else {
      groupProvider.loadMembers(groupId).then((_) {
        if (!mounted) return;
        setState(
          () => _applyDefaultAssignee(groupProvider.membersFor(groupId)),
        );
      });
    }
  }

  void _applyDefaultAssignee(List<GroupMemberModel> members) {
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    for (final member in members) {
      if (member.userId == currentUserId) {
        _selectedAssignee = member;
        return;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    if (_selectedPriority == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.pleaseSelectPriority)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dueDate = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime!.hour,
        _dueTime!.minute,
      );
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final taskProvider = context.read<TaskProvider>();
      final task = _isEditing
          ? await taskProvider.updateTask(
              id: widget.task!.id!,
              title: title,
              description: description,
              priority: _selectedPriority!,
              dueDate: dueDate,
            )
          : await taskProvider.createTask(
              TaskModel(
                title: title,
                description: description,
                priority: _selectedPriority!,
                dueDate: dueDate,
                createdAt: null,
                groupId: _activeGroupId,
                assignedTo: _selectedAssignee?.userId,
              ),
            );
      if (!mounted) return;
      if (task == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.couldNotCreateTask)),
        );
        return;
      }
      navigationService.pop(context, TaskChangeSaved(task));
    } on TaskServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteTask),
        content: const Text(AppStrings.deleteTaskConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: LabelText.large(
              AppStrings.delete,
              color: Theme.of(dialogContext).colorScheme.error,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final id = widget.task!.id!;
      await context.read<TaskProvider>().deleteTask(id);
      if (!mounted) return;
      navigationService.pop(context, TaskChangeDeleted(id));
    } on TaskServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: ScreenAppBar(
        title: _isEditing ? AppStrings.editTaskTitle : AppStrings.createTask,
      ),
      scrollable: true,
      body: Form(
        key: _formKey,
        child: AppBodyColumn(
          spacing: 16,
          children: [
            AppTextField(
              label: AppStrings.taskNameLabel,
              controller: _titleController,
              enabled: !_isBusy,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? AppStrings.taskNameRequired
                  : null,
            ),
            AppTextField(
              label: AppStrings.descriptionLabel,
              controller: _descriptionController,
              enabled: !_isBusy,
              maxLines: 3,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? AppStrings.descriptionRequired
                  : null,
            ),
            AppDropdownField<TaskPriority>(
              hint: AppStrings.priorityLabel,
              value: _selectedPriority,
              items: TaskPriority.values,
              itemLabelBuilder: (item) => item.name.toTitleCase,
              enabled: !_isBusy,
              onChanged: (value) {
                _selectedPriority = value;
                setState(() {});
              },
            ),
            AppDatePicker(
              label: AppStrings.dueDateLabel,
              value: _dueDate,
              enabled: !_isBusy,
              // Editing a task whose due date is already in the past must not raise the
              // picker's date range below that existing value.
              firstDate: _dueDate != null && _dueDate!.isBefore(DateTime.now())
                  ? _dueDate
                  : DateTime.now(),
              validator: (value) =>
                  value == null ? AppStrings.dueDateRequired : null,
              onChanged: (value) => _dueDate = value,
            ),
            AppTimePicker(
              label: AppStrings.dueTimeLabel,
              value: _dueTime,
              enabled: !_isBusy,
              validator: (value) =>
                  value == null ? AppStrings.dueTimeRequired : null,
              onChanged: (value) => _dueTime = value,
            ),
            if (!_isEditing) _buildAssigneeField(),
            AppButton.primary(
              label: _isSubmitting
                  ? (_isEditing ? AppStrings.saving : AppStrings.creating)
                  : (_isEditing
                        ? AppStrings.saveChanges
                        : AppStrings.createTask),
              onPressed: (_isBusy || (!_isEditing && _activeGroupId == null))
                  ? null
                  : _submit,
            ),
            if (_isEditing)
              AppButton.destructive(
                label: _isDeleting
                    ? AppStrings.deleting
                    : AppStrings.deleteTask,
                onPressed: _isBusy ? null : _delete,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssigneeField() {
    final groupId = _activeGroupId;
    if (groupId == null) {
      return const BodyText.medium(AppStrings.noActiveGroupMessage);
    }

    final groupProvider = context.watch<GroupProvider>();
    if (groupProvider.isLoadingMembers(groupId)) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return MemberDropdownField(
      hint: AppStrings.assigneeLabel,
      members: groupProvider.membersFor(groupId),
      value: _selectedAssignee,
      currentUserId: context.watch<AuthProvider>().currentUser?.id,
      enabled: !_isBusy,
      onChanged: (member) => setState(() => _selectedAssignee = member),
    );
  }
}
