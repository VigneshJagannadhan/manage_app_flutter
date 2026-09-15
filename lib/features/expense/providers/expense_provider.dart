import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huddle/core/data/pending_mutation.dart';
import 'package:huddle/core/enums/expense_enums.dart';
import 'package:huddle/core/services/api_result.dart';
import 'package:huddle/core/services/expense_service.dart';
import 'package:huddle/features/expense/data/expense_repository.dart';
import 'package:huddle/features/expense/models/expense_model.dart';
import 'package:huddle/features/group/providers/group_provider.dart';
import 'package:huddle/features/settings/providers/profile_provider.dart';
import 'package:huddle/features/shared/providers/base_provider.dart';
import 'package:uuid/uuid.dart';

/// Per-expense sync status for the offline write queue - drives the pending/failed badge on
/// `ExpenseTile`. `synced` covers both "never had a pending write" and "successfully flushed".
enum ExpenseSyncState { synced, pending, failed }

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

  static const _entityType = 'expense';
  static const _tempIdPrefix = 'local-';
  static const _maxAttempts = 5;

  // In-memory only - a restart clears it, which is fine since the underlying
  // PendingMutation stays `pending` in storage and just gets retried fresh.
  final Set<String> _inFlightIds = {};
  // temp id -> real id, populated once a queued create's flush succeeds. Lets a screen
  // that's still holding a temp id (e.g. ExpenseDetailScreen opened right after an offline
  // create) resolve to the real one once it exists.
  final Map<String, String> _idRemap = {};

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

  /// Looks up an expense by id in the raw list - used by ExpenseDetailScreen to resolve a
  /// reactive reference (mirrors [TaskProvider.taskById]).
  ExpenseModel? expenseById(String id) {
    for (final expense in _expenses) {
      if (expense.id == id) return expense;
    }
    return null;
  }

  /// Resolves a temp id to its real server id once the create that made it has synced;
  /// returns [id] unchanged otherwise (already-real ids, or a create still pending).
  String currentIdFor(String id) => _idRemap[id] ?? id;

  ExpenseSyncState syncStateFor(String id) {
    final mutation = expenseRepository.mutationFor(id);
    if (mutation == null) return ExpenseSyncState.synced;
    return mutation.state == MutationSyncState.failed ? ExpenseSyncState.failed : ExpenseSyncState.pending;
  }

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
      setExpenses(expenseRepository.applyPendingOverlay(result));
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

  // ---------------------------------------------------------------------------------
  // Mutations - always apply optimistically and queue for background delivery, online
  // or offline, so nothing ever blocks on the network (see the offline write-queue plan).
  // ---------------------------------------------------------------------------------

  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final tempId = '$_tempIdPrefix${const Uuid().v4()}';
    final optimistic = expense.copyWith(id: tempId);
    addExpense(optimistic);
    await _recordMutation(entityId: tempId, op: MutationOp.create, expense: optimistic);
    unawaited(_flushOne(expenseRepository.mutationFor(tempId)!));
    return optimistic;
  }

  Future<ExpenseModel> updateExpense({
    required String id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    bool? essential,
  }) async {
    final current = expenseById(id);
    if (current == null) throw StateError('ExpenseProvider.updateExpense: no expense with id $id');
    final updated = current.copyWith(title: title, amount: amount, category: category, date: date, essential: essential);
    setExpenses([
      for (final expense in _expenses)
        if (expense.id != id) expense,
      updated,
    ]);

    // A still-pending, not-yet-synced create just gets its payload replaced - it's not a
    // separate "update" against a server id yet.
    final existingOp = expenseRepository.mutationFor(id)?.op;
    final op = existingOp == MutationOp.create ? MutationOp.create : MutationOp.update;
    await _recordMutation(entityId: id, op: op, expense: updated);
    unawaited(_flushOne(expenseRepository.mutationFor(id)!));
    return updated;
  }

  Future<void> deleteExpense(String id) async {
    setExpenses([
      for (final expense in _expenses)
        if (expense.id != id) expense,
    ]);

    final existing = expenseRepository.mutationFor(id);
    if (existing != null && existing.op == MutationOp.create && !_inFlightIds.contains(id)) {
      // Never made it to the server and never will - nothing to tell it.
      await expenseRepository.discardMutation(id);
      return;
    }
    await _recordMutation(entityId: id, op: MutationOp.delete, expense: null);
    unawaited(_flushOne(expenseRepository.mutationFor(id)!));
  }

  /// Records/coalesces one local mutation. A mutation for an id currently mid-flight
  /// (see [_inFlightIds]) is stored with `dirty: true` rather than triggering a second,
  /// overlapping network call - see `_finishCreate`/`_finishUpdate` for how a dirty record
  /// gets replayed once the in-flight attempt resolves.
  Future<void> _recordMutation({required String entityId, required MutationOp op, required ExpenseModel? expense}) async {
    await expenseRepository.recordMutation(
      PendingMutation(
        entityType: _entityType,
        entityId: entityId,
        op: op,
        payload: expense?.toCacheJson(),
        queuedAt: DateTime.now(),
        dirty: _inFlightIds.contains(entityId),
      ),
    );
  }

  /// Dispatches every non-in-flight pending expense mutation to the network. Safe to call
  /// repeatedly (app resume/reconnect) - already-in-flight entries are skipped.
  Future<void> flushPending() async {
    final pending = expenseRepository.allPendingMutations();
    await Future.wait(pending.map(_flushOne));
  }

  Future<void> _flushOne(PendingMutation mutation) async {
    if (_inFlightIds.contains(mutation.entityId)) return;
    _inFlightIds.add(mutation.entityId);
    try {
      final result = await expenseRepository.flushMutation(mutation);
      switch (mutation.op) {
        case MutationOp.create:
          await _finishCreate(mutation.entityId, result!);
        case MutationOp.update:
          await _finishUpdate(mutation.entityId, result!);
        case MutationOp.delete:
          await expenseRepository.discardMutation(mutation.entityId);
      }
    } on ExpenseServiceException catch (e) {
      await _handleFlushFailure(mutation, e);
    } finally {
      _inFlightIds.remove(mutation.entityId);
      notifyListeners();
    }
  }

  Future<void> _finishCreate(String tempId, ExpenseModel result) async {
    _idRemap[tempId] = result.id!;
    final coalesced = expenseRepository.mutationFor(tempId);
    await expenseRepository.discardMutation(tempId);

    if (coalesced == null || !coalesced.dirty) {
      setExpenses([
        for (final e in _expenses)
          if (e.id == tempId) result else e,
      ]);
      return;
    }

    // A local edit/delete arrived while this create was still in flight - the POST already
    // went out with the pre-edit payload, so it was never sent. Replay it now against the
    // real id: an edit becomes an `update` (the entity now exists), a delete stays a delete.
    final followUp = coalesced.op == MutationOp.delete
        ? PendingMutation(entityType: _entityType, entityId: result.id!, op: MutationOp.delete, payload: null, queuedAt: coalesced.queuedAt)
        : PendingMutation(
            entityType: _entityType,
            entityId: result.id!,
            op: MutationOp.update,
            payload: coalesced.payload,
            queuedAt: coalesced.queuedAt,
          );
    await expenseRepository.recordMutation(followUp);

    if (followUp.op == MutationOp.delete) {
      setExpenses([
        for (final e in _expenses)
          if (e.id != tempId) e,
      ]);
    } else {
      final patched = ExpenseModel.fromJson(followUp.payload!).copyWith(id: result.id);
      setExpenses([
        for (final e in _expenses)
          if (e.id == tempId) patched else e,
      ]);
    }
    unawaited(_flushOne(followUp));
  }

  Future<void> _finishUpdate(String id, ExpenseModel result) async {
    final coalesced = expenseRepository.mutationFor(id);
    if (coalesced == null || !coalesced.dirty) {
      await expenseRepository.discardMutation(id);
      setExpenses([
        for (final e in _expenses)
          if (e.id == id) result else e,
      ]);
      return;
    }

    // A local edit/delete arrived while this update was in flight - replay it now.
    final followUp = coalesced.copyWith(dirty: false, attempts: 0);
    await expenseRepository.recordMutation(followUp);
    if (followUp.op == MutationOp.delete) {
      setExpenses([
        for (final e in _expenses)
          if (e.id != id) e,
      ]);
    } else {
      setExpenses([
        for (final e in _expenses)
          if (e.id == id) ExpenseModel.fromJson(followUp.payload!) else e,
      ]);
    }
    unawaited(_flushOne(followUp));
  }

  Future<void> _handleFlushFailure(PendingMutation mutation, ExpenseServiceException e) async {
    final current = expenseRepository.mutationFor(mutation.entityId) ?? mutation;

    // The item is already gone server-side (someone/something else deleted it first) -
    // that's the intended end state for an update or delete, not a real failure.
    if (mutation.op != MutationOp.create && e.statusCode == 404) {
      await expenseRepository.discardMutation(mutation.entityId);
      setExpenses([
        for (final e in _expenses)
          if (e.id != mutation.entityId) e,
      ]);
      return;
    }

    final isPermanent = e.type == FailureType.badResponse && (e.statusCode == null || e.statusCode! < 500);
    if (isPermanent || current.attempts + 1 >= _maxAttempts) {
      await expenseRepository.recordMutation(current.copyWith(state: MutationSyncState.failed, attempts: current.attempts + 1));
    } else {
      await expenseRepository.recordMutation(current.copyWith(attempts: current.attempts + 1));
    }
  }

  /// Resets a permanently-failed mutation and retries it - used by the ExpenseTile action
  /// sheet's "Retry" option.
  Future<void> retryFailed(String id) async {
    final mutation = expenseRepository.mutationFor(id);
    if (mutation == null) return;
    final reset = mutation.copyWith(state: MutationSyncState.pending, attempts: 0, dirty: false);
    await expenseRepository.recordMutation(reset);
    unawaited(_flushOne(reset));
  }

  /// Drops a permanently-failed mutation without retrying - used by the ExpenseTile action
  /// sheet's "Discard" option. Also removes the local item if it was never actually
  /// created server-side.
  Future<void> discardFailed(String id) async {
    final mutation = expenseRepository.mutationFor(id);
    await expenseRepository.discardMutation(id);
    if (mutation?.op == MutationOp.create) {
      setExpenses([
        for (final e in _expenses)
          if (e.id != id) e,
      ]);
    } else {
      notifyListeners();
    }
  }
}
