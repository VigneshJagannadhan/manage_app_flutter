import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.elevation, this.clipBehavior = Clip.antiAlias, this.onTap, this.cardTap = true});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Clip clipBehavior;
  final VoidCallback? onTap;
  final bool cardTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final content = Padding(padding: padding ?? EdgeInsets.all(theme.horizontalMargin ?? 16), child: child);

    var card = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.appBorderRadius ?? 12)),
      elevation: elevation ?? theme.elevationSmall ?? 1,
      clipBehavior: clipBehavior,
      child: onTap != null ? InkWell(onTap: onTap, child: content) : content,
    );
    return cardTap ? InkWell(onTap: onTap, child: card) : card;
  }
}
