import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/features/shared/widgets/text/app_text.dart';

enum _BodyTextSize { large, medium, small }

class BodyText extends AppText {
  const BodyText.large(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _BodyTextSize.large;

  const BodyText.medium(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _BodyTextSize.medium;

  const BodyText.small(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _BodyTextSize.small;

  final _BodyTextSize _size;

  @override
  TextStyle? themeStyle(BuildContext context) {
    final theme = context.appTheme;
    return switch (_size) {
      _BodyTextSize.large => theme.bodyLarge,
      _BodyTextSize.medium => theme.bodyMedium,
      _BodyTextSize.small => theme.bodySmall,
    };
  }
}
