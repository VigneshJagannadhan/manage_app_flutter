import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/features/shared/widgets/text/app_text.dart';

enum _DisplayTextSize { large, medium, small }

class DisplayText extends AppText {
  const DisplayText.large(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _DisplayTextSize.large;

  const DisplayText.medium(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _DisplayTextSize.medium;

  const DisplayText.small(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _DisplayTextSize.small;

  final _DisplayTextSize _size;

  @override
  TextStyle? themeStyle(BuildContext context) {
    final theme = context.appTheme;
    return switch (_size) {
      _DisplayTextSize.large => theme.displayLarge,
      _DisplayTextSize.medium => theme.displayMedium,
      _DisplayTextSize.small => theme.displaySmall,
    };
  }
}
