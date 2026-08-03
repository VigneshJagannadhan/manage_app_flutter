import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Drop-in SVG replacement for [Icon] - inherits size/color from the
/// ambient [IconTheme] the same way [Icon] does when not given explicitly.
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(this.assetPath, {super.key, this.size, this.color});

  final String assetPath;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final resolvedColor = color ?? iconTheme.color;

    return SizedBox(
      width: resolvedSize,
      height: resolvedSize,
      child: Center(
        child: SvgPicture.asset(
          assetPath,
          width: resolvedSize,
          height: resolvedSize,
          colorFilter: resolvedColor != null ? ColorFilter.mode(resolvedColor, BlendMode.srcIn) : null,
        ),
      ),
    );
  }
}
