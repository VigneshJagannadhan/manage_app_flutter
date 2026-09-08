import 'package:huddle/core/data/json_cache.dart';
import 'package:huddle/core/data/mutation_store.dart';
import 'package:huddle/core/data/pending_mutation.dart';
import 'package:huddle/core/enums/expense_enums.dart';
import 'package:huddle/core/services/expense_service.dart';
import 'package:huddle/features/expense/models/expense_model.dart';

/// Read-through cache and pending-mutation data access for the account's expenses - pure
/// data access (fetch remote, mirror to [cache]/[mutations]), no scheduling/retry policy.
/// That lives in [ExpenseProvider]; mirrors the role [TaskRepository] plays for tasks.
class ExpenseRepository {
  ExpenseRepository({required this.remote, required this.cache, MutationStore? mutations}) : mutations = mutations ?? mutationStore;

  final ExpenseService remote;
  final JsonCache cache;
  final MutationStore mutations;

  static const _key = 'expenses';
  static const entityType = 'expense';

  List<ExpenseModel> cachedExpenses() => applyPendingOverlay(cache.getList(_key, ExpenseModel.fromJson));

  Future<List<ExpenseModel>> syncExpenses({ExpenseCategory? category, String? groupId}) async {
    final expenses = await remote.listExpenses(category: category, groupId: groupId);
    await cache.setList(_key, expenses.map((expense) => expense.toCacheJson()).toList());
    return applyPendingOverlay(expenses);
  }

  /// Applies every still-pending local mutation on top of [serverList] so an
  /// offline-created/edited/deleted expense survives being overwritten by a fresher
  /// cache/network read that predates it (app restart before a flush lands,
  /// pull-to-refresh, a filter/group-scope change while a flush is still in flight).
  List<ExpenseModel> applyPendingOverlay(List<ExpenseModel> serverList) {
    final pending = mutations.allFor(entityType);
    if (pending.isEmpty) return serverList;

    final byId = {for (final mutation in pending) mutation.entityId: mutation};
    final overlaid = <ExpenseModel>[];
    for (final expense in serverList) {
      final mutation = expense.id == null ? null : byId[expense.id];
      if (mutation == null) {
        overlaid.add(expense);
      } else if (mutation.op != MutationOp.delete) {
        overlaid.add(ExpenseModel.fromJson(mutation.payload!));
      }
      // op == delete: drop the item entirely.
    }

    final presentIds = overlaid.map((expense) => expense.id).whereType<String>().toSet();
    for (final mutation in pending) {
      if (mutation.op == MutationOp.create && !presentIds.contains(mutation.entityId)) {
        overlaid.add(ExpenseModel.fromJson(mutation.payload!));
      }
    }
    return overlaid;
  }

  PendingMutation? mutationFor(String entityId) => mutations.get(entityType, entityId);

  List<PendingMutation> allPendingMutations() => mutations.allFor(entityType);

  Future<void> recordMutation(PendingMutation mutation) => mutations.put(mutation);

  Future<void> discardMutation(String entityId) => mutations.delete(entityType, entityId);

  /// Dispatches one queued mutation to the network. Returns the resulting [ExpenseModel]
  /// for a successful create/update, `null` for a successful delete.
  Future<ExpenseModel?> flushMutation(PendingMutation mutation) async {
    switch (mutation.op) {
      case MutationOp.create:
        return remote.createExpense(ExpenseModel.fromJson(mutation.payload!));
      case MutationOp.update:
        final expense = ExpenseModel.fromJson(mutation.payload!);
        return remote.updateExpense(
          id: mutation.entityId,
          title: expense.title,
          amount: expense.amount,
          category: expense.category,
          date: expense.date,
          essential: expense.essential,
        );
      case MutationOp.delete:
        await remote.deleteExpense(id: mutation.entityId);
        return null;
    }
  }
}
