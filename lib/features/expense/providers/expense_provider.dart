import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huddle/core/enums/expense_enums.dart';
import 'package:huddle/core/services/expense_service.dart';
import 'package:huddle/features/expense/data/expense_repository.dart';
import 'package:huddle/features/expense/models/expense_model.dart';
import 'package:huddle/features/group/providers/group_provider.dart';
import 'package:huddle/features/settings/providers/profile_provider.dart';
import 'package:huddle/features/shared/providers/base_provider.dart';

class ExpenseProvider extends BaseProvider {
  ExpenseProvider({
    required this.expenseService,
    required this.expenseRepository,
    required this.groupProvider,
    required this.profileProvider,
  });
  final ExpenseService expenseService;
  final ExpenseRepository expenseRepository;
  final GroupProvider groupProvider;
  final ProfileProvider profileProvider;

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

  /// Month the dashboard summary/breakdown/recent list are scoped to - always starts on the
  /// current month for a fresh app session (deliberately not persisted).
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime get selectedMonth => _selectedMonth;

  /// Lower bound for [ExpenseFilterSheet]'s month stepper - falls back to the current month
  /// when the profile hasn't loaded `createdAt` yet, mirrors [TaskProvider.accountCreatedDate].
  DateTime get earliestSelectableMonth {
    final createdAt = profileProvider.profile?.createdAt ?? DateTime.now();
    return DateTime(createdAt.year, createdAt.month);
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

  /// Commits the viewed month staged in [ExpenseFilterSheet] - used by its Apply button.
  /// The sheet commits the group scope to [groupProvider] (see [GroupProvider.setGroupScope])
  /// before calling this. [groupScopeChanged] is passed in rather than derived here because
  /// "did the scope change" also depends on which specific group is now active, which this
  /// provider doesn't track - only the caller, which holds both [GroupProvider] and this
  /// provider, can tell (mirrors [TaskProvider.applyFilters]). Changing the month is
  /// client-side only (no reload needed), so only a group scope change triggers [loadExpenses].
  void applyDashboardFilters({required bool groupScopeChanged, required DateTime selectedMonth}) {
    _selectedMonth = DateTime(selectedMonth.year, selectedMonth.month);
    if (groupScopeChanged) {
      loadExpenses();
    } else {
      notifyListeners();
    }
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

  List<ExpenseModel> get _selectedMonthExpenses => _expenses.where((expense) {
    final date = expense.date;
    return date != null && date.year == _selectedMonth.year && date.month == _selectedMonth.month;
  }).toList();

  double get totalForSelectedMonth => _selectedMonthExpenses.fold(0.0, (sum, expense) => sum + (expense.amount ?? 0));

  /// Share of [totalForSelectedMonth] contributed by each category present in [selectedMonth],
  /// keyed by category and sorted from largest to smallest share.
  Map<ExpenseCategory, double> get categoryBreakdownForSelectedMonth {
    final total = totalForSelectedMonth;
    if (total <= 0) return {};
    final totals = <ExpenseCategory, double>{};
    for (final expense in _selectedMonthExpenses) {
      final category = expense.category ?? ExpenseCategory.other;
      totals[category] = (totals[category] ?? 0) + (expense.amount ?? 0);
    }
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final entry in entries) entry.key: entry.value / total};
  }

  double get essentialAmountForSelectedMonth =>
      _selectedMonthExpenses.where((expense) => expense.essential).fold(0.0, (sum, expense) => sum + (expense.amount ?? 0));

  double get nonEssentialAmountForSelectedMonth =>
      _selectedMonthExpenses.where((expense) => !expense.essential).fold(0.0, (sum, expense) => sum + (expense.amount ?? 0));

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
        groupId: groupProvider.showAllGroups ? null : groupProvider.activeGroupId,
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

  /// Populates from the local cache instantly, with no loading/error state - called once
  /// by GlobalDataProvider.primeFromCache() before Home is ever shown, so the list isn't
  /// empty while [syncExpenses] is still in flight against a possibly cold-starting server.
  void primeFromCache() {
    final cached = expenseRepository.cachedExpenses();
    if (cached.isNotEmpty) setExpenses(cached);
  }

  /// Background refresh from the network - called by GlobalDataProvider.syncAllData() on
  /// app open/resume/reconnect. Unlike [loadExpenses], a failure here is silent: the
  /// cached/previous list stays on screen rather than surfacing an error, since the user
  /// never asked for this reload.
  Future<void> syncExpenses() async {
    try {
      final result = await expenseRepository.syncExpenses(
        groupId: groupProvider.showAllGroups ? null : groupProvider.activeGroupId,
      );
      setExpenses(result);
    } on ExpenseServiceException {
      // Swallowed by design - see doc comment above.
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
