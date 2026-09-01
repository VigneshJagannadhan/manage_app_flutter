import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/core/services/navigation_service.dart';
import 'package:huddle/features/expense/providers/expense_provider.dart';
import 'package:huddle/features/group/providers/group_provider.dart';
import 'package:huddle/features/shared/widgets/app_bottom_sheet.dart';
import 'package:huddle/features/shared/widgets/app_button.dart';
import 'package:huddle/features/shared/widgets/app_dropdown_field.dart';
import 'package:huddle/features/shared/widgets/text/body_text.dart';
import 'package:huddle/features/shared/widgets/text/label_text.dart';
import 'package:provider/provider.dart';

/// Staged copy of the dashboard's group/month scope, edited locally by the dropdown and
/// stepper and only pushed into [ExpenseProvider] (and [GroupProvider], for the group
/// switch) when Apply is pressed - picking an option must not affect the dashboard until then.
class _ExpenseFilterDraft extends ChangeNotifier {
  _ExpenseFilterDraft.from(ExpenseProvider provider, GroupProvider groupProvider)
    : selectedGroupId = groupProvider.showAllGroups ? null : groupProvider.activeGroupId,
      selectedMonth = provider.selectedMonth;

  /// `null` means "All Groups"; otherwise the id of the group to switch to on Apply.
  String? selectedGroupId;
  DateTime selectedMonth;

  void setSelectedGroupId(String? value) {
    selectedGroupId = value;
    notifyListeners();
  }

  void setSelectedMonth(DateTime value) {
    selectedMonth = value;
    notifyListeners();
  }

  void resetToDefaults() {
    selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    notifyListeners();
  }
}

class ExpenseFilterSheet {
  const ExpenseFilterSheet._();

  static Future<void> show(BuildContext context) {
    final draft = _ExpenseFilterDraft.from(context.read<ExpenseProvider>(), context.read<GroupProvider>());
    return AppBottomSheet.show<void>(
      context,
      title: AppStrings.filterAndSort,
      icon: Icons.tune,
      body: ChangeNotifierProvider<_ExpenseFilterDraft>.value(value: draft, child: const _ExpenseFilterSheetBody()),
      footer: ChangeNotifierProvider<_ExpenseFilterDraft>.value(value: draft, child: const _ExpenseFilterSheetFooter()),
    );
  }
}

class _ExpenseFilterSheetBody extends StatelessWidget {
  const _ExpenseFilterSheetBody();

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<_ExpenseFilterDraft>();
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
          LabelText.large(AppStrings.monthLabel),
          SizedBox(height: fieldGap),
          _MonthStepper(
            month: draft.selectedMonth,
            earliestMonth: context.read<ExpenseProvider>().earliestSelectableMonth,
            onChanged: draft.setSelectedMonth,
          ),
        ],
      ),
    );
  }
}

/// Steps [month] one calendar month at a time - capped at the current month since
/// expenses can't be logged for a month that hasn't happened yet, and can't go earlier
/// than [earliestMonth] (the account's creation month).
class _MonthStepper extends StatelessWidget {
  const _MonthStepper({required this.month, required this.earliestMonth, required this.onChanged});

  final DateTime month;
  final DateTime earliestMonth;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final canGoToPreviousMonth = month.isAfter(earliestMonth);
    final canGoToNextMonth = month.isBefore(DateTime(now.year, now.month));

    return Container(
      height: theme.controlHeight,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(theme.appBorderRadius), border: Border.all(color: theme.outlineColor)),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: colorScheme.onSurfaceVariant,
            tooltip: AppStrings.previousMonthTooltip,
            onPressed: canGoToPreviousMonth ? () => onChanged(DateTime(month.year, month.month - 1)) : null,
          ),
          Expanded(child: Center(child: BodyText.large(month.monthYearLabel))),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: colorScheme.onSurfaceVariant,
            tooltip: AppStrings.nextMonthTooltip,
            onPressed: canGoToNextMonth ? () => onChanged(DateTime(month.year, month.month + 1)) : null,
          ),
        ],
      ),
    );
  }
}

class _ExpenseFilterSheetFooter extends StatelessWidget {
  const _ExpenseFilterSheetFooter();

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Row(
      children: [
        Expanded(
          child: AppButton.secondary(label: AppStrings.clearAll, onPressed: () => context.read<_ExpenseFilterDraft>().resetToDefaults()),
        ),
        SizedBox(width: theme.spacingSmall),
        Expanded(
          child: AppButton.primary(
            label: AppStrings.apply,
            onPressed: () async {
              final draft = context.read<_ExpenseFilterDraft>();
              final groupProvider = context.read<GroupProvider>();
              final expenseProvider = context.read<ExpenseProvider>();
              final showAllGroups = draft.selectedGroupId == null;
              final groupScopeChanged =
                  showAllGroups != groupProvider.showAllGroups || (!showAllGroups && draft.selectedGroupId != groupProvider.activeGroupId);
              await groupProvider.setGroupScope(showAllGroups: showAllGroups, groupId: draft.selectedGroupId);
              expenseProvider.applyDashboardFilters(groupScopeChanged: groupScopeChanged, selectedMonth: draft.selectedMonth);
              if (context.mounted) navigationService.pop(context);
            },
          ),
        ),
      ],
    );
  }
}
