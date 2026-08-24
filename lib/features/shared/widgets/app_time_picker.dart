import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/features/shared/widgets/text/body_text.dart';

class AppTimePicker extends StatelessWidget {
  const AppTimePicker({
    super.key,
    this.value,
    this.label,
    this.hint,
    this.helperText,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.autovalidateMode,
  });

  final TimeOfDay? value;
  final String? label;
  final String? hint;
  final String? helperText;
  final FormFieldValidator<TimeOfDay>? validator;
  final ValueChanged<TimeOfDay>? onChanged;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;

  Future<void> _pickTime(BuildContext context, FormFieldState<TimeOfDay> field) async {
    final picked = await showTimePicker(context: context, initialTime: field.value ?? TimeOfDay.now());
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

    return FormField<TimeOfDay>(
      initialValue: value,
      validator: validator,
      autovalidateMode: autovalidateMode,
      enabled: enabled,
      builder: (field) {
        final selectedLabel = field.value?.format(context);

        return SizedBox(
          height: theme.controlHeight,
          child: Semantics(
            button: true,
            enabled: enabled,
            label: label ?? hint,
            value: selectedLabel,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: enabled ? () => _pickTime(context, field) : null,
              child: InputDecorator(
                isEmpty: field.value == null,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: label,
                  hintText: hint,
                  helperText: helperText,
                  errorText: field.errorText,
                  suffixIcon: const Icon(Icons.access_time_outlined),
                  border: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide(color: outlineColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide(color: outlineColor)),
                  disabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide(color: colorScheme.outlineVariant)),
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
