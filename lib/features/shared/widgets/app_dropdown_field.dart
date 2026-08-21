import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_assets.dart';
import 'package:manage_app/features/shared/widgets/app_svg_icon.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';

class AppDropdownField<T> extends StatefulWidget {
  const AppDropdownField({
    super.key,
    required this.items,
    required this.itemLabelBuilder,
    this.value,
    this.onChanged,
    this.hint,
    this.enabled = true,
  });

  final List<T> items;
  final String Function(T item) itemLabelBuilder;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String? hint;
  final bool enabled;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  static const _animDuration = Duration(milliseconds: 200);

  bool _isOpen = false;

  void _toggle() {
    if (!widget.enabled) return;
    setState(() => _isOpen = !_isOpen);
  }

  void _select(T item) {
    setState(() => _isOpen = false);
    widget.onChanged?.call(item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(theme.appBorderRadius);
    final outlineColor = theme.outlineColor;
    final controlHeight = theme.controlHeight;
    final selectedLabel = widget.value != null ? widget.itemLabelBuilder(widget.value as T) : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          enabled: widget.enabled,
          label: widget.hint,
          value: selectedLabel,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.enabled ? _toggle : null,
            child: Container(
              height: controlHeight,
              padding: EdgeInsets.symmetric(horizontal: theme.horizontalMargin),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: radius,
                border: Border.all(color: widget.enabled ? outlineColor : colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: BodyText.large(
                      selectedLabel ?? widget.hint ?? '',
                      color: selectedLabel != null ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: _animDuration,
                    child: AppSvgIcon(SvgIcons.downArrow, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: _animDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _isOpen
              ? Padding(
                  padding: EdgeInsets.only(top: theme.spacingSmall),
                  child: _DropdownPanel<T>(
                    items: widget.items,
                    value: widget.value,
                    itemLabelBuilder: widget.itemLabelBuilder,
                    onSelected: _select,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _DropdownPanel<T> extends StatelessWidget {
  const _DropdownPanel({required this.items, required this.value, required this.itemLabelBuilder, required this.onSelected});

  final List<T> items;
  final T? value;
  final String Function(T item) itemLabelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = theme.secondaryColor;
    final itemRadius = BorderRadius.circular(theme.appBorderRadius);

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(theme.appBorderRadius),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(theme.spacingSmall),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            final isSelected = item == value;
            return InkWell(
              borderRadius: itemRadius,
              onTap: () => onSelected(item),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: theme.horizontalMargin, vertical: theme.spacingSmall),
                decoration: BoxDecoration(borderRadius: itemRadius, border: isSelected ? Border.all(color: accentColor) : null),
                child: BodyText.large(itemLabelBuilder(item), color: colorScheme.onSurface),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
