import 'package:huddle/core/data/json_cache.dart';
import 'package:huddle/core/enums/expense_enums.dart';
import 'package:huddle/core/services/expense_service.dart';
import 'package:huddle/features/expense/models/expense_model.dart';

/// Read-through cache for the account's expenses - pure data access (fetch remote, mirror
/// to [cache]), no scheduling/retry policy. That lives in [ExpenseProvider]; mirrors the
/// role [JournalRepository] plays for journal drafts.
class ExpenseRepository {
  ExpenseRepository({required this.remote, required this.cache});

  final ExpenseService remote;
  final JsonCache cache;

  static const _key = 'expenses';

  List<ExpenseModel> cachedExpenses() => cache.getList(_key, ExpenseModel.fromJson);

  Future<List<ExpenseModel>> syncExpenses({ExpenseCategory? category, String? groupId}) async {
    final expenses = await remote.listExpenses(category: category, groupId: groupId);
    await cache.setList(_key, expenses.map((expense) => expense.toCacheJson()).toList());
    return expenses;
  }
}
