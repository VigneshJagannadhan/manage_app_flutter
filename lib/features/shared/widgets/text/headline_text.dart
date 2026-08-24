import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/features/shared/widgets/text/app_text.dart';

enum _HeadlineTextSize { large, medium, small }

class HeadlineText extends AppText {
  const HeadlineText.large(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _HeadlineTextSize.large;

  const HeadlineText.medium(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _HeadlineTextSize.medium;

  const HeadlineText.small(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _HeadlineTextSize.small;

  final _HeadlineTextSize _size;

  @override
  TextStyle? themeStyle(BuildContext context) {
    final theme = context.appTheme;
    return switch (_size) {
      _HeadlineTextSize.large => theme.headlineLarge,
      _HeadlineTextSize.medium => theme.headlineMedium,
      _HeadlineTextSize.small => theme.headlineSmall,
    };
  }
}
