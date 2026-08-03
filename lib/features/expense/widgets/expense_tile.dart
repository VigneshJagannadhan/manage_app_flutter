import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/expense_enums.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/extensions/currency_extension.dart';
import 'package:manage_app/core/extensions/date_time_extensions.dart';
import 'package:manage_app/core/extensions/string_extensions.dart';
import 'package:manage_app/core/themes/constants/app_spacing.dart';
import 'package:manage_app/features/expense/models/expense_model.dart';
import 'package:manage_app/features/shared/widgets/app_card.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, this.groupName, this.onTap, this.onEdit});

  final ExpenseModel expense;
  // Shown only in "all groups" mode, where expenses from multiple groups are mixed together.
  final String? groupName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  String get title => expense.title ?? '';
  ExpenseCategory? get category => expense.category;
  String get categoryName => category?.name.toTitleCase ?? '';
  String get formattedDateTime2 => expense.date?.formattedDateTime ?? '';
  String get displayAmount => expense.amount.toCurrencyString();
  static IconData iconFor(ExpenseCategory? category) => switch (category) {
    ExpenseCategory.food => Icons.restaurant,
    ExpenseCategory.transport => Icons.directions_car,
    ExpenseCategory.shopping => Icons.shopping_bag,
    ExpenseCategory.bills => Icons.receipt_long,
    ExpenseCategory.entertainment => Icons.movie,
    ExpenseCategory.health => Icons.local_hospital,
    ExpenseCategory.other => Icons.category,
    null => Icons.category,
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (category != null) ...[
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(((theme.appBorderRadius ?? 12) - AppSpacing.space4)),
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  child: Icon(iconFor(category), size: 50, color: Colors.white),
                ),
              ),
              SizedBox(width: theme.spacingMedium ?? 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (groupName != null) ...[
                    Text(groupName!, style: textTheme.labelSmall?.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.w700)),
                    SizedBox(height: theme.spacingXSmall ?? 4),
                  ],
                  Text(title, style: textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                  if (category != null) ...[
                    SizedBox(height: theme.spacingXSmall ?? 4),
                    Text(
                      categoryName,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: theme.spacingXSmall ?? 4),
                  if (expense.date != null)
                    Text(
                      formattedDateTime2,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    displayAmount,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
