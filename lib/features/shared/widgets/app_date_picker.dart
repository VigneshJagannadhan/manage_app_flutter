import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_assets.dart';
import 'package:manage_app/features/shared/widgets/app_svg_icon.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';

class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    this.value,
    this.label,
    this.hint,
    this.helperText,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.autovalidateMode,
    this.firstDate,
    this.lastDate,
  });

  final DateTime? value;
  final String? label;
  final String? hint;
  final String? helperText;
  final FormFieldValidator<DateTime>? validator;
  final ValueChanged<DateTime>? onChanged;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;
  final DateTime? firstDate;
  final DateTime? lastDate;

  static const _monthAbbreviations = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_monthAbbreviations[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate(BuildContext context, FormFieldState<DateTime> field) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: field.value ?? now,
      firstDate: firstDate ?? DateTime(now.year - 5),
      lastDate: lastDate ?? DateTime(now.year + 5),
    );
    if (picked == null) return;
    field.didChange(picked);
    onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(theme.appBorderRadius);
    final outlineColor = theme.outlineColor;

    return FormField<DateTime>(
      initialValue: value,
      validator: validator,
      autovalidateMode: autovalidateMode,
      enabled: enabled,
      builder: (field) {
        final selectedLabel = field.value != null ? formatDate(field.value!) : null;

        return SizedBox(
          height: theme.controlHeight,
          child: Semantics(
            button: true,
            enabled: enabled,
            label: label ?? hint,
            value: selectedLabel,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: enabled ? () => _pickDate(context, field) : null,
              child: InputDecorator(
                isEmpty: field.value == null,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: label,
                  hintText: hint,
                  helperText: helperText,
                  errorText: field.errorText,
                  suffixIcon: const AppSvgIcon(SvgIcons.calendar),
                  border: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(color: outlineColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(color: outlineColor),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: BodyText.large(selectedLabel ?? ''),
              ),
            ),
          ),
        );
      },
    );
  }
}
