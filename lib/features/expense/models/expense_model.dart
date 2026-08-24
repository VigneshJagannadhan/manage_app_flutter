import 'package:huddle/core/enums/expense_enums.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/features/expense/models/expense_split_model.dart';

class ExpenseModel {
  final String? id;
  final String? title;
  final double? amount;
  final ExpenseCategory? category;
  final DateTime? date;
  final DateTime? createdAt;
  final String? groupId;
  // A member's userId. `null` means "me" - defaults to the creator server-side when omitted.
  final String? payerId;
  final List<ExpenseSplit> splits;
  final bool essential;

  ExpenseModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.createdAt,
    this.groupId,
    this.payerId,
    this.splits = const [],
    this.essential = false,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['_id'] as String?,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] != null ? ExpenseCategoryApi.fromApiValue(json['category'] as String) : null,
      date: DateTime.parse(json['date'] as String),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      groupId: json['groupId'] as String?,
      payerId: (json['payer'] as Map<String, dynamic>?)?['userId'] as String?,
      splits: json['splits'] != null
          ? (json['splits'] as List<dynamic>).map((split) => ExpenseSplit.fromJson(split as Map<String, dynamic>)).toList()
          : const [],
      essential: json['essential'] as bool? ?? false,
    );
  }

  /// Serializes for the create-expense request body. `id` is server-assigned and omitted.
  /// `payer` is omitted entirely when [payerId] is null so the backend defaults it to the creator.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      if (category != null) 'category': category!.apiValue,
      if (date != null) 'date': date!.toServer(),
      if (createdAt != null) 'createdAt': createdAt!.toServer(),
      if (groupId != null) 'groupId': groupId,
      if (payerId != null) 'payer': {'userId': payerId},
      'splits': splits.map((split) => split.toJson()).toList(),
      'essential': essential,
    };
  }

  ExpenseModel copyWith({
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? payerId,
    List<ExpenseSplit>? splits,
    bool? essential,
  }) {
    return ExpenseModel(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt,
      groupId: groupId,
      payerId: payerId ?? this.payerId,
      splits: splits ?? this.splits,
      essential: essential ?? this.essential,
    );
  }
}
