import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/features/shared/widgets/text/app_text.dart';

enum _TitleTextSize { large, medium, small }

class TitleText extends AppText {
  const TitleText.large(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _TitleTextSize.large;

  const TitleText.medium(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _TitleTextSize.medium;

  const TitleText.small(super.text, {super.key, super.style, super.color, super.overflow, super.maxLines, super.textAlign})
    : _size = _TitleTextSize.small;

  final _TitleTextSize _size;

  @override
  TextStyle? themeStyle(BuildContext context) {
    final theme = context.appTheme;
    return switch (_size) {
      _TitleTextSize.large => theme.titleLarge,
      _TitleTextSize.medium => theme.titleMedium,
      _TitleTextSize.small => theme.titleSmall,
    };
  }
}
