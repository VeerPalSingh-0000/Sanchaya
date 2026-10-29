import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_app/config/theme_extension.dart';

class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheHeight;
  final int? memCacheWidth;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheHeight,
    this.memCacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(color: context.colors.surfaceLight);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheHeight: memCacheHeight,
      memCacheWidth: memCacheWidth,
      placeholder: (_, _) => Container(color: context.colors.surfaceLight),
      errorWidget: (_, _, _) => Container(
        color: context.colors.surfaceLight,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: context.colors.textSubtle,
            size: 24,
          ),
        ),
      ),
    );
  }
}
