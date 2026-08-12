import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/expense_enums.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/extensions/string_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/features/expense/widgets/expense_category_style.dart';
import 'package:manage_app/features/expense/widgets/expense_donut_chart.dart';
import 'package:manage_app/features/shared/widgets/app_card.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';

/// Donut chart + legend showing each category's share of this month's spend.
class ExpenseCategoryBreakdown extends StatelessWidget {
  const ExpenseCategoryBreakdown({super.key, required this.breakdown});

  final Map<ExpenseCategory, double> breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      cardTap: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExpenseDonutChart(breakdown: breakdown),
          SizedBox(width: theme.spacingLarge ?? 24),
          Expanded(
            child: breakdown.isEmpty
                ? BodyText.medium(AppStrings.noExpensesThisMonth, color: colorScheme.outline)
                : Wrap(
                    spacing: theme.spacingMedium ?? 16,
                    runSpacing: theme.spacingSmall ?? 8,
                    children: [
                      for (final entry in breakdown.entries) _LegendItem(category: entry.key, share: entry.value),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.category, required this.share});

  final ExpenseCategory category;
  final double share;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 120,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: ExpenseCategoryStyle.colorFor(category), shape: BoxShape.circle),
          ),
          SizedBox(width: theme.spacingXSmall ?? 4),
          Expanded(child: LabelText.small(category.name.toTitleCase, color: colorScheme.outline, overflow: TextOverflow.ellipsis)),
          SizedBox(width: theme.spacingXSmall ?? 4),
          LabelText.small('${(share * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
