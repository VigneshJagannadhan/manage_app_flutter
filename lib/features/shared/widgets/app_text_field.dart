import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  }) : obscureText = false,
       _borderless = false;

  const AppTextField.password({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  }) : obscureText = true,
       prefixIcon = null,
       suffixIcon = null,
       keyboardType = TextInputType.visiblePassword,
       maxLines = 1,
       textCapitalization = TextCapitalization.none,
       _borderless = false;

  /// A borderless, undecorated field that expands to fill its parent - for a full-page
  /// writing surface (e.g. a journal entry) rather than a form input.
  const AppTextField.multiline({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.sentences,
  }) : obscureText = false,
       label = null,
       helperText = null,
       prefixIcon = null,
       suffixIcon = null,
       keyboardType = TextInputType.multiline,
       textInputAction = TextInputAction.newline,
       validator = null,
       onFieldSubmitted = null,
       maxLines = null,
       autovalidateMode = null,
       _borderless = true;

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final AutovalidateMode? autovalidateMode;
  final bool obscureText;
  final bool _borderless;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(theme.appBorderRadius);
    final outlineColor = theme.outlineColor;
    final isSingleLine = widget.obscureText || widget.maxLines == 1;

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText && _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      expands: widget._borderless,
      textAlignVertical: widget._borderless ? TextAlignVertical.top : null,
      textCapitalization: widget.textCapitalization,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: widget._borderless
          ? InputDecoration.collapsed(hintText: widget.hint)
          : InputDecoration(
              isDense: isSingleLine,
              labelText: widget.label,
              hintText: widget.hint,
              helperText: widget.helperText,
              prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
                      tooltip: _obscured ? AppStrings.showPassword : AppStrings.hidePassword,
                      onPressed: () => setState(() => _obscured = !_obscured),
                    )
                  : widget.suffixIcon,
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
    );
  }
}
