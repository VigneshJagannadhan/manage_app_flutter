import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/features/shared/widgets/text/app_text.dart';

enum _LabelTextSize { large, medium, small }

class LabelText extends AppText {
  const LabelText.large(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _LabelTextSize.large;

  const LabelText.medium(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _LabelTextSize.medium;

  const LabelText.small(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _LabelTextSize.small;

  final _LabelTextSize _size;

  @override
  TextStyle? themeStyle(BuildContext context) {
    final theme = context.appTheme;
    return switch (_size) {
      _LabelTextSize.large => theme.labelLarge,
      _LabelTextSize.medium => theme.labelMedium,
      _LabelTextSize.small => theme.labelSmall,
    };
  }
}
