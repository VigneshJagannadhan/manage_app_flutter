import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/extensions/currency_extension.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:manage_app/features/shared/widgets/text/headline_text.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';

/// "Total this month" figure plus an essential/non-essential breakdown bar,
/// driven by each expense's `essential` flag.
class ExpenseSummaryCard extends StatelessWidget {
  const ExpenseSummaryCard({
    super.key,
    required this.totalThisMonth,
    required this.essentialAmount,
    required this.nonEssentialAmount,
  });

  final double totalThisMonth;
  final double essentialAmount;
  final double nonEssentialAmount;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = theme.spacingSmall ?? 8;
    final hasAmount = totalThisMonth > 0;
    final essentialFlex = hasAmount
        ? ((essentialAmount / totalThisMonth) * 1000).round().clamp(1, 999)
        : 1;
    final nonEssentialFlex = hasAmount
        ? (1000 - essentialFlex).clamp(1, 999)
        : 1;

    return Padding(
      padding: EdgeInsets.all(theme.horizontalMargin ?? 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabelText.large(
            AppStrings.totalThisMonth,
            color: colorScheme.outline,
          ),
          SizedBox(height: theme.spacingXSmall ?? 4),
          HeadlineText.large(
            totalThisMonth.toCurrencyString(),
            color: colorScheme.primary,
          ),
          SizedBox(height: theme.spacingMedium ?? 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(theme.spacingXSmall ?? 4),
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
          SizedBox(height: theme.spacingMedium ?? 16),
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
            SizedBox(width: theme.spacingXSmall ?? 4),
            LabelText.large(label, color: colorScheme.outline),
          ],
        ),
        SizedBox(height: (theme.spacingXSmall ?? 4) / 2),
        BodyText.large(
          amount.toCurrencyString(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
