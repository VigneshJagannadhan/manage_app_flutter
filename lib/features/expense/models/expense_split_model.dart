/// One member's share of an expense - a real group member userId (validated
/// server-side), not a placeholder. Splits are just recorded amounts for now;
/// no settle-up/netting logic exists.
class ExpenseSplit {
  ExpenseSplit({required this.userId, required this.amountOwed});

  final String userId;
  final double amountOwed;

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(userId: json['userId'] as String, amountOwed: (json['amountOwed'] as num).toDouble());
  }

  Map<String, dynamic> toJson() => {'userId': userId, 'amountOwed': amountOwed};
}
