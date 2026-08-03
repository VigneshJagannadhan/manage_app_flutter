import 'package:manage_app/core/resources/app_strings.dart';

extension CurrencyExtension on double? {
  String toCurrencyString() {
    final amount = this ?? 0.0;
    return '${AppStrings.currencySymbol}${amount.toStringAsFixed(2)}';
  }
}
