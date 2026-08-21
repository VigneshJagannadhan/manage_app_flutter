import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/expense_enums.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/extensions/string_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/features/expense/widgets/expense_category_style.dart';
import 'package:manage_app/features/expense/widgets/expense_donut_chart.dart';
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

    return Padding(
      padding: EdgeInsets.all(theme.horizontalMargin),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chartSize = constraints.maxWidth.clamp(0.0, 200.0);
                  return ExpenseDonutChart(breakdown: breakdown, size: chartSize, strokeWidth: chartSize * 0.13);
                },
              ),
            ),
          ),
          SizedBox(width: theme.spacingLarge),
          SizedBox(
            width: 120,
            child: breakdown.isEmpty
                ? BodyText.medium(AppStrings.noExpensesThisMonth, color: colorScheme.outline)
                : Wrap(
                    spacing: theme.spacingMedium,
                    runSpacing: theme.spacingSmall,
                    children: [for (final entry in breakdown.entries) _LegendItem(category: entry.key, share: '${(entry.value * 100).round()}%')],
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
  final String share;

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
          SizedBox(width: theme.spacingXSmall),
          Expanded(
            child: LabelText.medium(category.name.toTitleCase, color: colorScheme.outline, overflow: TextOverflow.ellipsis),
          ),
          SizedBox(width: theme.spacingXSmall),
          LabelText.small(share, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
