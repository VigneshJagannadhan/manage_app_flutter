import 'package:flutter/material.dart';
import 'package:huddle/core/enums/expense_enums.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/extensions/string_extensions.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/core/services/navigation_service.dart';
import 'package:huddle/features/expense/providers/expense_provider.dart';
import 'package:huddle/features/shared/widgets/app_bottom_sheet.dart';
import 'package:huddle/features/shared/widgets/app_button.dart';
import 'package:provider/provider.dart';

/// Staged copy of the category filter shown in [ExpenseFilterSheet], edited locally by
/// the pills and only pushed into [ExpenseProvider] when Apply is pressed - selecting a
/// pill must not filter the underlying list until then.
class _ExpenseFilterDraft extends ChangeNotifier {
  _ExpenseFilterDraft.from(ExpenseProvider provider) : category = provider.categoryFilter;

  ExpenseCategory? category;

  void setCategory(ExpenseCategory? value) {
    category = value;
    notifyListeners();
  }

  void resetToDefaults() {
    category = null;
    notifyListeners();
  }
}

class ExpenseFilterSheet {
  const ExpenseFilterSheet._();

  static Future<void> show(BuildContext context) {
    final draft = _ExpenseFilterDraft.from(context.read<ExpenseProvider>());
    return AppBottomSheet.show<void>(
      context,
      title: AppStrings.filter,
      icon: Icons.filter_list,
      body: ChangeNotifierProvider<_ExpenseFilterDraft>.value(value: draft, child: const _ExpenseFilterSheetBody()),
      footer: ChangeNotifierProvider<_ExpenseFilterDraft>.value(value: draft, child: const _ExpenseFilterSheetFooter()),
    );
  }
}

class _ExpenseFilterSheetBody extends StatelessWidget {
  const _ExpenseFilterSheetBody();

  static String _categoryLabel(ExpenseCategory? category) => category == null ? AppStrings.all : category.name.toTitleCase;

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<_ExpenseFilterDraft>();
    final theme = context.appTheme;
    final spacing = theme.spacingSmall;

    return SingleChildScrollView(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final category in [null, ...ExpenseCategory.values])
            ChoiceChip(
              label: Text(_categoryLabel(category)),
              selected: draft.category == category,
              onSelected: (_) => draft.setCategory(category),
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
            onPressed: () {
              context.read<ExpenseProvider>().setCategoryFilter(context.read<_ExpenseFilterDraft>().category);
              navigationService.pop(context);
            },
          ),
        ),
      ],
    );
  }
}
