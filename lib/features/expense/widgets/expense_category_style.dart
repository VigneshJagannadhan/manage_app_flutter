import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/expense_enums.dart';

/// Icon + color mapping for [ExpenseCategory], shared by the expense tile,
/// category breakdown chart/legend, and category filter chips.
///
/// Colors are a fixed decorative palette for telling categories apart at a
/// glance - not theme design tokens, so they're kept local to this class
/// rather than added to [AppTheme].
class ExpenseCategoryStyle {
  const ExpenseCategoryStyle._();

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

  static Color colorFor(ExpenseCategory? category) => switch (category) {
    ExpenseCategory.transport => const Color(0xFF3B82F6),
    ExpenseCategory.bills => const Color(0xFFF97316),
    ExpenseCategory.shopping => const Color(0xFF14B8A6),
    ExpenseCategory.entertainment => const Color(0xFFA855F7),
    ExpenseCategory.food => const Color(0xFFF43F5E),
    ExpenseCategory.health => const Color(0xFF22C55E),
    ExpenseCategory.other => const Color(0xFF64748B),
    null => const Color(0xFF64748B),
  };
}
