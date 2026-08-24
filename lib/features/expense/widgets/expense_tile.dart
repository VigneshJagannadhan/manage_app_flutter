import 'package:flutter/material.dart';
import 'package:huddle/core/enums/expense_enums.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/extensions/currency_extension.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/extensions/string_extensions.dart';
import 'package:huddle/features/expense/models/expense_model.dart';
import 'package:huddle/features/expense/widgets/expense_category_style.dart';
import 'package:huddle/features/shared/widgets/app_card.dart';
import 'package:huddle/features/shared/widgets/app_tile_badge.dart';
import 'package:huddle/features/shared/widgets/app_tile_pill.dart';
import 'package:huddle/features/shared/widgets/text/body_text.dart';
import 'package:huddle/features/shared/widgets/text/label_text.dart';
import 'package:huddle/features/shared/widgets/text/title_text.dart';

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

  String? get _dateLabel {
    final date = expense.date;
    if (date == null) return null;
    return date.isToday ? date.formattedTime : date.formattedShortDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final categoryColor = ExpenseCategoryStyle.colorFor(category);
    final dateLabel = _dateLabel;
    final margin = theme.horizontalMargin;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(margin),
      // Mirrors TaskTile's gradient-surface treatment so the two tile types
      // read as one design language rather than two unrelated styles.
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [categoryColor, Color.lerp(categoryColor, Colors.black, 0.75)!],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (categoryName.isNotEmpty)
                AppTileBadge(label: categoryName, icon: ExpenseCategoryStyle.iconFor(category)),
              if (groupName != null) ...[
                SizedBox(width: theme.spacingSmall),
                Expanded(
                  child: LabelText.small(
                    groupName!,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    color: Colors.white.withValues(alpha: 0.85),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: theme.spacingSmall),
          Row(
            children: [
              Expanded(
                child: TitleText.medium(
                  title,
                  color: Colors.white,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (expense.essential) ...[
                SizedBox(width: theme.spacingXSmall),
                const Icon(Icons.star, size: 18, color: Colors.white),
              ],
            ],
          ),
          if (dateLabel != null) ...[
            SizedBox(height: theme.spacingXSmall),
            BodyText.medium(dateLabel, color: Colors.white.withValues(alpha: 0.72)),
          ],
          SizedBox(height: theme.spacingSmall),
          AppTilePill(
            icon: const Icon(Icons.payments_outlined, size: 16, color: Colors.white),
            label: displayAmount,
          ),
        ],
      ),
    );
  }
}
