import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/expense_enums.dart';
import 'package:manage_app/core/services/expense_service.dart';
import 'package:manage_app/core/services/group_preference_service.dart';
import 'package:manage_app/features/expense/models/expense_model.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/shared/providers/base_provider.dart';

class ExpenseProvider extends BaseProvider {
  ExpenseProvider({required this.expenseService, required this.groupProvider, required this.groupPreferenceService});
  final ExpenseService expenseService;
  final GroupProvider groupProvider;
  final GroupPreferenceService groupPreferenceService;

  /// Loading is driven explicitly by GlobalDataProvider.loadAllData, so there's nothing to
  /// self-trigger here - it just needs to satisfy the BaseProvider contract.
  @override
  void onInit() {}

  @override
  void onDispose() {
    clearExpenses();
  }

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => _expenses;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _showAllGroups = true;
  bool get showAllGroups => _showAllGroups;

  /// Reads the last-picked group scope from local storage. Must complete before
  /// [loadExpenses] so the very first load after sign-in respects it - see
  /// GlobalDataProvider.loadAllData.
  Future<void> restoreShowAllGroups() async {
    _showAllGroups = await groupPreferenceService.readExpensesShowAllGroups();
    notifyListeners();
  }

  /// Resets the group-scope choice back to "all groups" and wipes the persisted
  /// preference, so it doesn't linger into the next account signed in on this device.
  void resetShowAllGroupsPreference() {
    _showAllGroups = true;
    unawaited(groupPreferenceService.clearExpensesShowAllGroups());
  }

  // All Expenses screen filters/sort - client-side only, applied on top of the loaded [_expenses].
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  ExpenseCategory? _categoryFilter;
  ExpenseCategory? get categoryFilter => _categoryFilter;

  DateTimeRange? _dateRangeFilter;
  DateTimeRange? get dateRangeFilter => _dateRangeFilter;

  ExpenseSortOption _sortOption = ExpenseSortOption.newest;
  ExpenseSortOption get sortOption => _sortOption;

  void toggleShowAllGroups(bool value) {
    _showAllGroups = value;
    unawaited(groupPreferenceService.saveExpensesShowAllGroups(value));
    loadExpenses();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setCategoryFilter(ExpenseCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setDateRangeFilter(DateTimeRange? range) {
    _dateRangeFilter = range;
    notifyListeners();
  }

  void setSortOption(ExpenseSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void clearAllExpensesFilters() {
    _searchQuery = '';
    _categoryFilter = null;
    _dateRangeFilter = null;
    _sortOption = ExpenseSortOption.newest;
    notifyListeners();
  }

  /// [_expenses] filtered by [searchQuery]/[categoryFilter]/[dateRangeFilter] and sorted by [sortOption].
  List<ExpenseModel> get filteredExpenses {
    final filtered = _expenses.where(_matchesFilters).toList();
    filtered.sort(_compareBySortOption);
    return filtered;
  }

  bool _matchesFilters(ExpenseModel expense) {
    if (_categoryFilter != null && expense.category != _categoryFilter) return false;
    if (_searchQuery.trim().isNotEmpty && !(expense.title ?? '').toLowerCase().contains(_searchQuery.trim().toLowerCase())) return false;
    final range = _dateRangeFilter;
    final date = expense.date;
    if (range != null) {
      if (date == null) return false;
      if (date.isBefore(range.start)) return false;
      if (date.isAfter(range.end.add(const Duration(days: 1)))) return false;
    }
    return true;
  }

  int _compareBySortOption(ExpenseModel a, ExpenseModel b) => switch (_sortOption) {
    ExpenseSortOption.newest => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
    ExpenseSortOption.oldest => (a.date ?? DateTime(0)).compareTo(b.date ?? DateTime(0)),
    ExpenseSortOption.amountHigh => (b.amount ?? 0).compareTo(a.amount ?? 0),
    ExpenseSortOption.amountLow => (a.amount ?? 0).compareTo(b.amount ?? 0),
  };

  /// The most recent expenses, newest first - used by the dashboard's "Recent" section.
  List<ExpenseModel> recentExpenses({int limit = 3}) {
    final sorted = [..._expenses]..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
    return sorted.take(limit).toList();
  }

  List<ExpenseModel> get _thisMonthExpenses {
    final now = DateTime.now();
    return _expenses.where((expense) {
      final date = expense.date;
      return date != null && date.year == now.year && date.month == now.month;
    }).toList();
  }

  double get totalThisMonth => _thisMonthExpenses.fold(0.0, (sum, expense) => sum + (expense.amount ?? 0));

  /// Share of [totalThisMonth] contributed by each category present this month, keyed by category
  /// and sorted from largest to smallest share.
  Map<ExpenseCategory, double> get categoryBreakdownThisMonth {
    final total = totalThisMonth;
    if (total <= 0) return {};
    final totals = <ExpenseCategory, double>{};
    for (final expense in _thisMonthExpenses) {
      final category = expense.category ?? ExpenseCategory.other;
      totals[category] = (totals[category] ?? 0) + (expense.amount ?? 0);
    }
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final entry in entries) entry.key: entry.value / total};
  }

  double get essentialAmountThisMonth =>
      _thisMonthExpenses.where((expense) => expense.essential).fold(0.0, (sum, expense) => sum + (expense.amount ?? 0));

  double get nonEssentialAmountThisMonth =>
      _thisMonthExpenses.where((expense) => !expense.essential).fold(0.0, (sum, expense) => sum + (expense.amount ?? 0));

  void setExpenses(List<ExpenseModel> expenses) {
    _expenses = expenses;
    notifyListeners();
  }

  void addExpense(ExpenseModel expense) {
    _expenses = [..._expenses, expense];
    notifyListeners();
  }

  void clearExpenses() {
    _expenses = [];
    notifyListeners();
  }

  Future<void> loadExpenses({ExpenseCategory? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await expenseService.listExpenses(
        category: category,
        groupId: _showAllGroups ? null : groupProvider.activeGroupId,
      );
      setExpenses(result);
    } on ExpenseServiceException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ExpenseModel?> createExpense(ExpenseModel expense) async {
    final result = await expenseService.createExpense(expense);
    if (result != null) {
      addExpense(result);
    }
    return result;
  }

  Future<ExpenseModel> updateExpense({
    required String id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    bool? essential,
  }) async {
    final updated = await expenseService.updateExpense(id: id, title: title, amount: amount, category: category, date: date, essential: essential);
    setExpenses([
      for (final expense in _expenses)
        if (expense.id != id) expense,
      updated,
    ]);
    return updated;
  }

  Future<void> deleteExpense(String id) async {
    await expenseService.deleteExpense(id: id);
    setExpenses([
      for (final expense in _expenses)
        if (expense.id != id) expense,
    ]);
  }
}
