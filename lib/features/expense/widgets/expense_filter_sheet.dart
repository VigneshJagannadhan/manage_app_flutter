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

class ExpenseFilterSheet {
  const ExpenseFilterSheet._();

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show<void>(
      context,
      title: AppStrings.filter,
      icon: Icons.filter_list,
      body: const _ExpenseFilterSheetBody(),
      footer: const _ExpenseFilterSheetFooter(),
    );
  }
}

class _ExpenseFilterSheetBody extends StatelessWidget {
  const _ExpenseFilterSheetBody();

  static String _categoryLabel(ExpenseCategory? category) => category == null ? AppStrings.all : category.name.toTitleCase;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
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
              selected: provider.categoryFilter == category,
              onSelected: (_) => provider.setCategoryFilter(category),
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
          child: AppButton.secondary(label: AppStrings.clearAll, onPressed: () => context.read<ExpenseProvider>().setCategoryFilter(null)),
        ),
        SizedBox(width: theme.spacingSmall),
        Expanded(
          child: AppButton.primary(label: AppStrings.apply, onPressed: () => navigationService.pop(context)),
        ),
      ],
    );
  }
}
