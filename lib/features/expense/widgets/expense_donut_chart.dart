import 'dart:math';

import 'package:flutter/material.dart';
import 'package:huddle/core/enums/expense_enums.dart';
import 'package:huddle/features/expense/widgets/expense_category_style.dart';

/// Ring chart showing each category's share of the total, colored via
/// [ExpenseCategoryStyle.colorFor]. [breakdown] values are fractions of 1.
class ExpenseDonutChart extends StatelessWidget {
  const ExpenseDonutChart({super.key, required this.breakdown, this.size = 120, this.strokeWidth = 16});

  final Map<ExpenseCategory, double> breakdown;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          breakdown: breakdown,
          strokeWidth: strokeWidth,
          emptyColor: colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.breakdown, required this.strokeWidth, required this.emptyColor});

  final Map<ExpenseCategory, double> breakdown;
  final double strokeWidth;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ringRect = rect.deflate(strokeWidth / 2);
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (breakdown.isEmpty) {
      canvas.drawArc(ringRect, 0, 2 * pi, false, basePaint..color = emptyColor);
      return;
    }

    var startAngle = -pi / 2;
    for (final entry in breakdown.entries) {
      final sweepAngle = 2 * pi * entry.value;
      canvas.drawArc(ringRect, startAngle, sweepAngle, false, basePaint..color = ExpenseCategoryStyle.colorFor(entry.key));
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.breakdown != breakdown || oldDelegate.strokeWidth != strokeWidth || oldDelegate.emptyColor != emptyColor;
}
