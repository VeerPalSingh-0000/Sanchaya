import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';

class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerCard({
    super.key,
    this.width = 140,
    this.height = 210,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Shimmer.fromColors(
            baseColor: AppTheme.surfaceLight,
            highlightColor: AppTheme.surfaceLight.withValues(alpha: 0.5),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Shimmer.fromColors(
            baseColor: AppTheme.surfaceLight,
            highlightColor: AppTheme.surfaceLight.withValues(alpha: 0.5),
            child: Container(
              width: width * 0.8,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Shimmer.fromColors(
            baseColor: AppTheme.surfaceLight,
            highlightColor: AppTheme.surfaceLight.withValues(alpha: 0.5),
            child: Container(
              width: width * 0.5,
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontal row of shimmer cards for loading state.
class ShimmerCardRow extends StatelessWidget {
  final int count;
  final double cardWidth;
  final double cardHeight;

  const ShimmerCardRow({
    super.key,
    this.count = 5,
    this.cardWidth = 140,
    this.cardHeight = 210,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight + 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, _) => ShimmerCard(
          width: cardWidth,
          height: cardHeight,
        ),
      ),
    );
  }
}
