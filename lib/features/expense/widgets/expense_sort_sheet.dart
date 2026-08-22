import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/expense_enums.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/expense/providers/expense_provider.dart';
import 'package:manage_app/features/shared/widgets/app_bottom_sheet.dart';
import 'package:provider/provider.dart';

class ExpenseSortSheet {
  const ExpenseSortSheet._();

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show<void>(context, title: AppStrings.sortByLabel, icon: Icons.sort, body: const _ExpenseSortSheetBody());
  }
}

class _ExpenseSortSheetBody extends StatelessWidget {
  const _ExpenseSortSheetBody();

  static String _sortOptionLabel(ExpenseSortOption option) => switch (option) {
    ExpenseSortOption.newest => AppStrings.sortNewest,
    ExpenseSortOption.oldest => AppStrings.sortOldest,
    ExpenseSortOption.amountHigh => AppStrings.sortAmountHigh,
    ExpenseSortOption.amountLow => AppStrings.sortAmountLow,
  };

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
          for (final option in ExpenseSortOption.values)
            ChoiceChip(
              label: Text(_sortOptionLabel(option)),
              selected: provider.sortOption == option,
              onSelected: (_) {
                provider.setSortOption(option);
                navigationService.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
