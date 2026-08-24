import 'package:huddle/core/resources/app_strings.dart';

final _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');

/// Phone is optional - an empty value clears it, so only the format is checked when present.
String? validatePhone(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  if (!_phonePattern.hasMatch(trimmed)) return AppStrings.invalidPhone;
  return null;
}
