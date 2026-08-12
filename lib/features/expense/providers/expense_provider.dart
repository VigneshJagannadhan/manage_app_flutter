import 'package:manage_app/core/enums/expense_enums.dart';
import 'package:manage_app/core/services/expense_service.dart';
import 'package:manage_app/features/expense/models/expense_model.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/shared/providers/base_provider.dart';

class ExpenseProvider extends BaseProvider {
  ExpenseProvider({required this.expenseService, required this.groupProvider});
  final ExpenseService expenseService;
  final GroupProvider groupProvider;

  /// Loading is driven explicitly by AppProvider.loadAllData, so there's nothing to
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
