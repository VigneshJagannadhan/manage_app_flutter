import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/extensions/currency_extension.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/features/shared/widgets/text/body_text.dart';
import 'package:huddle/features/shared/widgets/text/headline_text.dart';
import 'package:huddle/features/shared/widgets/text/label_text.dart';

/// Total-for-the-viewed-month figure plus an essential/non-essential breakdown
/// bar, driven by each expense's `essential` flag.
class ExpenseSummaryCard extends StatelessWidget {
  const ExpenseSummaryCard({
    super.key,
    required this.periodLabel,
    required this.total,
    required this.essentialAmount,
    required this.nonEssentialAmount,
  });

  /// e.g. "Total This Month" for the current month, or "Total for March 2026"
  /// once the viewer has picked a different month in [ExpenseFilterSheet].
  final String periodLabel;
  final double total;
  final double essentialAmount;
  final double nonEssentialAmount;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = theme.spacingSmall;
    final hasAmount = total > 0;
    final essentialFlex = hasAmount
        ? ((essentialAmount / total) * 1000).round().clamp(1, 999)
        : 1;
    final nonEssentialFlex = hasAmount
        ? (1000 - essentialFlex).clamp(1, 999)
        : 1;

    return Padding(
      padding: EdgeInsets.all(theme.horizontalMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabelText.large(
            periodLabel,
            color: colorScheme.outline,
          ),
          SizedBox(height: theme.spacingXSmall),
          HeadlineText.large(
            total.toCurrencyString(),
            color: colorScheme.primary,
          ),
          SizedBox(height: theme.spacingMedium),
          ClipRRect(
            borderRadius: BorderRadius.circular(theme.radiusPill),
            child: SizedBox(
              height: 8,
              child: hasAmount
                  ? Row(
                      children: [
                        Expanded(
                          flex: essentialFlex,
                          child: ColoredBox(color: colorScheme.primary),
                        ),
                        Expanded(
                          flex: nonEssentialFlex,
                          child: ColoredBox(color: colorScheme.tertiary),
                        ),
                      ],
                    )
                  : ColoredBox(color: colorScheme.surfaceContainerHighest),
            ),
          ),
          SizedBox(height: theme.spacingMedium),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SplitLegend(
                  color: colorScheme.primary,
                  label: AppStrings.essentialLabel,
                  amount: essentialAmount,
                  alignment: CrossAxisAlignment.start,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _SplitLegend(
                  color: colorScheme.error,
                  label: AppStrings.nonEssentialLabel,
                  amount: nonEssentialAmount,
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitLegend extends StatelessWidget {
  const _SplitLegend({
    required this.color,
    required this.label,
    required this.amount,
    required this.alignment,
  });

  final Color color;
  final String label;
  final double amount;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: alignment == CrossAxisAlignment.end
              ? TextDirection.rtl
              : TextDirection.ltr,
          children: [
            dot,
            SizedBox(width: theme.spacingXSmall),
            LabelText.large(label, color: colorScheme.outline),
          ],
        ),
        SizedBox(height: (theme.spacingXSmall) / 2),
        BodyText.large(
          amount.toCurrencyString(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
