import 'package:manage_app/core/constants/app_urls.dart';
import 'package:manage_app/core/enums/expense_enums.dart';
import 'package:manage_app/core/extensions/date_time_extensions.dart';
import 'package:manage_app/core/services/api_result.dart';
import 'package:manage_app/core/services/api_services.dart';
import 'package:manage_app/features/expense/models/expense_model.dart';

class ExpenseServiceException implements Exception {
  ExpenseServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExpenseService {
  ExpenseService({ApiServices? api}) : _api = api ?? apiServices;

  final ApiServices _api;

  Future<ExpenseModel?> createExpense(ExpenseModel expense) async {
    final result = await _api.post<ExpenseModel>(
      AppUrls.expenses,
      data: expense.toJson(),
      parser: (data) => ExpenseModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  Future<ExpenseModel> updateExpense({
    required String id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    bool? essential,
  }) async {
    final result = await _api.patch<ExpenseModel>(
      '${AppUrls.expenses}/$id',
      data: {
        'title': ?title,
        'amount': ?amount,
        'category': ?category?.apiValue,
        'date': ?date?.toServer(),
        'essential': ?essential,
      },
      parser: (data) => ExpenseModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  Future<void> deleteExpense({required String id}) async {
    final result = await _api.delete<void>('${AppUrls.expenses}/$id', parser: (_) {});
    return _unwrap(result);
  }

  /// [groupId] omitted fetches expenses across every group the caller belongs to.
  Future<List<ExpenseModel>> listExpenses({ExpenseCategory? category, String? groupId}) async {
    final result = await _api.get<List<ExpenseModel>>(
      AppUrls.expenses,
      queryParameters: {'category': ?category?.apiValue, 'groupId': ?groupId},
      parser: (data) => (data as List<dynamic>).map((expense) => ExpenseModel.fromJson(expense as Map<String, dynamic>)).toList(),
    );
    return _unwrap(result);
  }

  T _unwrap<T>(ApiResult<T> result) {
    return result.when(success: (data) => data, failure: (failure) => throw ExpenseServiceException(failure.message));
  }
}

final expenseService = ExpenseService();
