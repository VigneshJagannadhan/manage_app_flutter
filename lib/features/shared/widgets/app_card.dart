import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
    this.cardTap = true,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Clip clipBehavior;
  final VoidCallback? onTap;
  final bool cardTap;
  // Optional background gradient, painted behind the child. Leave null for the
  // default flat Card surface color.
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final content = Padding(padding: padding ?? EdgeInsets.all(theme.horizontalMargin ?? 16), child: child);

    var card = Card(
      color: gradient != null ? Colors.transparent : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.appBorderRadius ?? 12)),
      elevation: elevation ?? theme.elevationSmall ?? 1,
      clipBehavior: clipBehavior,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: onTap != null ? InkWell(onTap: onTap, child: content) : content,
      ),
    );
    return cardTap ? InkWell(onTap: onTap, child: card) : card;
  }
}
