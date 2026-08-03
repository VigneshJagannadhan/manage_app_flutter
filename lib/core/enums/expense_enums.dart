enum ExpenseCategory { food, transport, shopping, bills, entertainment, health, other }

extension ExpenseCategoryApi on ExpenseCategory {
  /// Matches the backend's case-sensitive category string exactly.
  String get apiValue => switch (this) {
    ExpenseCategory.food => 'FOOD',
    ExpenseCategory.transport => 'TRANSPORT',
    ExpenseCategory.shopping => 'SHOPPING',
    ExpenseCategory.bills => 'BILLS',
    ExpenseCategory.entertainment => 'ENTERTAINMENT',
    ExpenseCategory.health => 'HEALTH',
    ExpenseCategory.other => 'OTHER',
  };

  static ExpenseCategory fromApiValue(String value) => switch (value) {
    'FOOD' => ExpenseCategory.food,
    'TRANSPORT' => ExpenseCategory.transport,
    'SHOPPING' => ExpenseCategory.shopping,
    'BILLS' => ExpenseCategory.bills,
    'ENTERTAINMENT' => ExpenseCategory.entertainment,
    'HEALTH' => ExpenseCategory.health,
    'OTHER' => ExpenseCategory.other,
    _ => throw ArgumentError('Unknown expense category: $value'),
  };
}
