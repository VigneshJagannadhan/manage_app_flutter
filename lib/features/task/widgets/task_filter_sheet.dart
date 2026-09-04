import 'package:flutter/material.dart';
import 'package:huddle/core/enums/task_enums.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/extensions/string_extensions.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/core/services/navigation_service.dart';
import 'package:huddle/features/group/providers/group_provider.dart';
import 'package:huddle/features/shared/widgets/app_bottom_sheet.dart';
import 'package:huddle/features/shared/widgets/app_button.dart';
import 'package:huddle/features/shared/widgets/app_dropdown_field.dart';
import 'package:huddle/features/task/providers/task_provider.dart';
import 'package:huddle/features/shared/widgets/text/label_text.dart';
import 'package:provider/provider.dart';

/// Staged copy of the task filters shown in [TaskFilterSheet], edited locally by
/// the pills/dropdowns and only pushed into [TaskProvider] when Apply is pressed -
/// selecting an option must not filter the underlying list until then.
class _TaskFilterDraft extends ChangeNotifier {
  _TaskFilterDraft.from(TaskProvider provider, GroupProvider groupProvider)
    : status = provider.taskStatusFilter,
      priority = provider.priorityFilter,
      sortOption = provider.sortOption,
      selectedGroupId = groupProvider.showAllGroups ? null : groupProvider.activeGroupId;

  TaskStatus? status;
  TaskPriority? priority;
  TaskSortOption sortOption;

  /// `null` means "All Groups"; otherwise the id of the group to switch to on Apply.
  String? selectedGroupId;

  void setStatus(TaskStatus? value) {
    status = value;
    notifyListeners();
  }

  void setPriority(TaskPriority? value) {
    priority = value;
    notifyListeners();
  }

  void setSortOption(TaskSortOption value) {
    sortOption = value;
    notifyListeners();
  }

  void setSelectedGroupId(String? value) {
    selectedGroupId = value;
    notifyListeners();
  }

  void resetToDefaults() {
    status = null;
    priority = null;
    sortOption = TaskSortOption.dueDate;
    notifyListeners();
  }
}

class TaskFilterSheet {
  const TaskFilterSheet._();

  static Future<void> show(BuildContext context) {
    final draft = _TaskFilterDraft.from(context.read<TaskProvider>(), context.read<GroupProvider>());
    return AppBottomSheet.show<void>(
      context,
      title: AppStrings.filterAndSort,
      icon: Icons.tune,
      body: ChangeNotifierProvider<_TaskFilterDraft>.value(value: draft, child: const _TaskFilterSheetBody()),
      footer: ChangeNotifierProvider<_TaskFilterDraft>.value(value: draft, child: const _TaskFilterSheetFooter()),
    );
  }
}

class _TaskFilterSheetBody extends StatelessWidget {
  const _TaskFilterSheetBody();

  static String _statusLabel(TaskStatus? status) => status == null ? AppStrings.all : status.name.toTitleCase;

  static String _priorityLabel(TaskPriority? priority) => priority == null ? AppStrings.all : priority.name.toTitleCase;

  static String _sortOptionLabel(TaskSortOption option) => switch (option) {
    TaskSortOption.dueDate => AppStrings.dueDateLabel,
    TaskSortOption.priority => AppStrings.priorityLabel,
  };

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<_TaskFilterDraft>();
    final groupProvider = context.watch<GroupProvider>();
    final theme = context.appTheme;
    final sectionGap = theme.spacingMedium;
    final fieldGap = theme.spacingSmall;
    final groupLabelById = {for (final group in groupProvider.groups) group.id: group.name};

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabelText.large(AppStrings.groupLabel),
          SizedBox(height: fieldGap),
          AppDropdownField<String?>(
            items: [null, ...groupLabelById.keys],
            itemLabelBuilder: (id) => id == null ? AppStrings.allGroups : groupLabelById[id]!,
            value: draft.selectedGroupId,
            onChanged: draft.setSelectedGroupId,
          ),
          SizedBox(height: sectionGap),
          LabelText.large(AppStrings.statusLabel),
          SizedBox(height: fieldGap),
          AppDropdownField<TaskStatus?>(
            items: const [null, TaskStatus.open, TaskStatus.completed],
            itemLabelBuilder: _statusLabel,
            value: draft.status,
            onChanged: draft.setStatus,
          ),
          SizedBox(height: sectionGap),
          LabelText.large(AppStrings.priorityLabel),
          SizedBox(height: fieldGap),
          AppDropdownField<TaskPriority?>(
            items: const [null, TaskPriority.low, TaskPriority.medium, TaskPriority.high],
            itemLabelBuilder: _priorityLabel,
            value: draft.priority,
            onChanged: draft.setPriority,
          ),
          SizedBox(height: sectionGap),
          LabelText.large(AppStrings.sortByLabel),
          SizedBox(height: fieldGap),
          AppDropdownField<TaskSortOption>(
            items: TaskSortOption.values,
            itemLabelBuilder: _sortOptionLabel,
            value: draft.sortOption,
            onChanged: draft.setSortOption,
          ),
        ],
      ),
    );
  }
}

class _TaskFilterSheetFooter extends StatelessWidget {
  const _TaskFilterSheetFooter();

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Row(
      children: [
        Expanded(
          child: AppButton.secondary(label: AppStrings.clearAll, onPressed: () => context.read<_TaskFilterDraft>().resetToDefaults()),
        ),
        SizedBox(width: theme.spacingSmall),
        Expanded(
          child: AppButton.primary(
            label: AppStrings.apply,
            onPressed: () async {
              final draft = context.read<_TaskFilterDraft>();
              final groupProvider = context.read<GroupProvider>();
              final taskProvider = context.read<TaskProvider>();
              final showAllGroups = draft.selectedGroupId == null;
              final groupScopeChanged =
                  showAllGroups != groupProvider.showAllGroups || (!showAllGroups && draft.selectedGroupId != groupProvider.activeGroupId);
              await groupProvider.setGroupScope(showAllGroups: showAllGroups, groupId: draft.selectedGroupId);
              taskProvider.applyFilters(
                status: draft.status,
                priority: draft.priority,
                sortOption: draft.sortOption,
                groupScopeChanged: groupScopeChanged,
              );
              if (context.mounted) navigationService.pop(context);
            },
          ),
        ),
      ],
    );
  }
}
