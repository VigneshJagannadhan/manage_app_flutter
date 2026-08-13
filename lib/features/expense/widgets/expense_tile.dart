import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/expense_enums.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/extensions/currency_extension.dart';
import 'package:manage_app/core/extensions/date_time_extensions.dart';
import 'package:manage_app/core/extensions/string_extensions.dart';
import 'package:manage_app/features/expense/models/expense_model.dart';
import 'package:manage_app/features/expense/widgets/expense_category_style.dart';
import 'package:manage_app/features/shared/widgets/app_card.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';
import 'package:manage_app/features/shared/widgets/text/title_text.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, this.groupName, this.onTap});

  final ExpenseModel expense;
  // Shown only in "all groups" mode, where expenses from multiple groups are mixed together.
  final String? groupName;
  final VoidCallback? onTap;

  String get title => expense.title ?? '';
  ExpenseCategory? get category => expense.category;
  String get categoryName => category?.name.toTitleCase ?? '';
  String get displayAmount => expense.amount.toCurrencyString();

  String? get _subtitle {
    final date = expense.date;
    final dateLabel = date == null ? null : (date.isToday ? date.formattedTime : date.formattedShortDate);
    return switch ((categoryName.isEmpty, dateLabel)) {
      (true, null) => null,
      (true, final d?) => d,
      (false, null) => categoryName,
      (false, final d?) => '$categoryName · $d',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = ExpenseCategoryStyle.colorFor(category);
    final subtitle = _subtitle;

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(theme.spacingSmall ?? 8), color: categoryColor.withValues(alpha: 0.16)),
            child: Icon(ExpenseCategoryStyle.iconFor(category), size: 22, color: categoryColor),
          ),
          SizedBox(width: theme.spacingMedium ?? 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (groupName != null) ...[
                  LabelText.small(groupName!, color: colorScheme.secondary, style: const TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: theme.spacingXSmall ?? 4),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TitleText.small(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    if (expense.essential) ...[
                      SizedBox(width: (theme.spacingXSmall ?? 4) / 2),
                      Icon(Icons.star, size: 16, color: colorScheme.primary),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  SizedBox(height: (theme.spacingXSmall ?? 4) / 2),
                  BodyText.small(subtitle, color: colorScheme.outline, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          SizedBox(width: theme.spacingSmall ?? 8),
          TitleText.small(displayAmount, color: colorScheme.primary, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
