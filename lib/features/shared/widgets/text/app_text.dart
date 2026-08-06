import 'package:flutter/material.dart';

abstract class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.overflow,
    this.maxLines,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final Color? color;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextAlign? textAlign;

  @protected
  TextStyle? themeStyle(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = themeStyle(context)?.merge(style) ?? style;
    return Text(
      text,
      style: color != null
          ? (resolvedStyle ?? const TextStyle()).copyWith(color: color)
          : resolvedStyle,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
    );
  }
}
