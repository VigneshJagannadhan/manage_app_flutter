import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/task_enums.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/extensions/string_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/shared/widgets/app_bottom_sheet.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_date_picker.dart';
import 'package:manage_app/features/shared/widgets/app_dropdown_field.dart';
import 'package:manage_app/features/task/providers/task_provider.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';
import 'package:provider/provider.dart';

class TaskFilterSheet {
  const TaskFilterSheet._();

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show<void>(
      context,
      title: AppStrings.filterAndSort,
      icon: Icons.tune,
      body: const _TaskFilterSheetBody(),
      footer: const _TaskFilterSheetFooter(),
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

  static String _dateFilterLabel(TaskDateFilterOption option) => switch (option) {
    TaskDateFilterOption.all => AppStrings.all,
    TaskDateFilterOption.today => AppStrings.today,
    TaskDateFilterOption.tomorrow => AppStrings.tomorrow,
    TaskDateFilterOption.custom => AppStrings.customDate,
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = context.appTheme;
    final sectionGap = theme.spacingMedium;
    final fieldGap = theme.spacingSmall;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabelText.large(AppStrings.statusLabel),
          SizedBox(height: fieldGap),
          AppDropdownField<TaskStatus?>(
            items: const [null, TaskStatus.open, TaskStatus.completed],
            itemLabelBuilder: _statusLabel,
            value: provider.taskStatusFilter,
            onChanged: provider.setTaskStatusFilter,
          ),
          SizedBox(height: sectionGap),
          LabelText.large(AppStrings.priorityLabel),
          SizedBox(height: fieldGap),
          AppDropdownField<TaskPriority?>(
            items: const [null, TaskPriority.low, TaskPriority.medium, TaskPriority.high],
            itemLabelBuilder: _priorityLabel,
            value: provider.priorityFilter,
            onChanged: provider.setPriorityFilter,
          ),
          SizedBox(height: sectionGap),
          LabelText.large(AppStrings.sortByLabel),
          SizedBox(height: fieldGap),
          AppDropdownField<TaskSortOption>(
            items: TaskSortOption.values,
            itemLabelBuilder: _sortOptionLabel,
            value: provider.sortOption,
            onChanged: provider.setSortOption,
          ),
          SizedBox(height: sectionGap),
          LabelText.large(AppStrings.dateLabel),
          SizedBox(height: fieldGap),
          Wrap(
            spacing: fieldGap,
            runSpacing: fieldGap,
            children: TaskDateFilterOption.values.map((option) {
              return ChoiceChip(
                label: Text(_dateFilterLabel(option)),
                selected: provider.dateFilterOption == option,
                onSelected: (_) => provider.setDateFilter(option),
              );
            }).toList(),
          ),
          if (provider.dateFilterOption == TaskDateFilterOption.custom) ...[
            SizedBox(height: fieldGap),
            AppDatePicker(
              value: provider.customDate,
              hint: AppStrings.customDate,
              onChanged: (date) => provider.setDateFilter(TaskDateFilterOption.custom, customDate: date),
            ),
          ],
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
          child: AppButton.secondary(label: AppStrings.clearAll, onPressed: () => context.read<TaskProvider>().clearFilters()),
        ),
        SizedBox(width: theme.spacingSmall),
        Expanded(
          child: AppButton.primary(label: AppStrings.apply, onPressed: () => navigationService.pop(context)),
        ),
      ],
    );
  }
}
