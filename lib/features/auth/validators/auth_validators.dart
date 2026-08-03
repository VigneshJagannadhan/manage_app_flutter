import 'package:manage_app/core/resources/app_strings.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return AppStrings.emailRequired;
  if (!_emailPattern.hasMatch(trimmed)) return AppStrings.invalidEmail;
  return null;
}

const passwordMinLength = 8;

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return AppStrings.passwordRequired;
  if (value.length < passwordMinLength) return AppStrings.passwordTooShort;
  return null;
}
