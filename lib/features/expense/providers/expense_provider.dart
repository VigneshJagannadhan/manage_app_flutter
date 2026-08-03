import 'package:manage_app/core/enums/expense_enums.dart';
import 'package:manage_app/core/services/expense_service.dart';
import 'package:manage_app/features/expense/models/expense_model.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/shared/providers/base_provider.dart';

class ExpenseProvider extends BaseProvider {
  ExpenseProvider({required this.expenseService, required this.groupProvider});
  final ExpenseService expenseService;
  final GroupProvider groupProvider;

  @override
  void onInit() {
    _init();
  }

  /// Waits for [GroupProvider] to finish restoring the active group before the first
  /// load, so this doesn't fetch in "all groups" mode just because that's still in flight.
  Future<void> _init() async {
    await groupProvider.ready;
    await loadExpenses();
  }

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

  bool _showAllGroups = false;
  bool get showAllGroups => _showAllGroups;

  void toggleShowAllGroups(bool value) {
    _showAllGroups = value;
    loadExpenses();
  }

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

  Future<ExpenseModel> updateExpense({required String id, String? title, double? amount, ExpenseCategory? category, DateTime? date}) async {
    final updated = await expenseService.updateExpense(id: id, title: title, amount: amount, category: category, date: date);
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
