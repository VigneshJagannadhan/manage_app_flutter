import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/themes/constants/app_radius.dart';

enum _AppImageSource { asset, network }

class AppImage extends StatelessWidget {
  const AppImage.asset({super.key, required this.source, this.width, this.height, this.fit, this.radius = AppRadius.large})
    : _source = _AppImageSource.asset;

  const AppImage.network({super.key, required this.source, this.width, this.height, this.fit, this.radius = AppRadius.large})
    : _source = _AppImageSource.network;

  final String source;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final double? radius;
  final _AppImageSource _source;

  @override
  Widget build(BuildContext context) {
    final image = switch (_source) {
      _AppImageSource.asset => Image.asset(
        source,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildStatus(context, const Icon(Icons.broken_image_outlined, color: Colors.white)),
      ),
      _AppImageSource.network => CachedNetworkImage(
        imageUrl: source,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        placeholder: (context, url) => _buildStatus(context, const CircularProgressIndicator.adaptive()),
        errorWidget: (context, url, error) => _buildStatus(context, const Icon(Icons.broken_image_outlined, color: Colors.white)),
      ),
    };

    if (radius == null) return image;
    return ClipRRect(borderRadius: BorderRadius.circular(radius!), child: image);
  }

  Widget _buildStatus(BuildContext context, Widget child) {
    return Container(
      width: width,
      height: height,
      color: context.appTheme.outlineColor ?? Colors.red,
      child: Center(child: child),
    );
  }
}
