import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MediaCard extends StatelessWidget {
  final String title;
  final String posterUrl;
  final double? rating;
  final String? subtitle;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onAddWatchlist;
  final bool showRating;
  final String? typeBadge;
  final bool isAdded;
  final bool isFavorite;

  const MediaCard({
    super.key,
    required this.title,
    required this.posterUrl,
    this.rating,
    this.subtitle,
    this.width = 140,
    this.height = 210,
    this.onTap,
    this.onAddWatchlist,
    this.showRating = true,
    this.typeBadge,
    this.isAdded = false,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Poster ──
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.colors.divider.withValues(alpha: 0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    posterUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: posterUrl,
                            fit: BoxFit.cover,
                            memCacheHeight: height.isFinite ? (height * 2).toInt() : 400,
                            placeholder: (context, url) => Container(
                              color: context.colors.surfaceLight,
                              child: Center(
                                child: Icon(
                                  Icons.movie_outlined,
                                  color: context.colors.textSubtle,
                                  size: 32,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: context.colors.surfaceLight,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: context.colors.textSubtle,
                                  size: 32,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: context.colors.surfaceLight,
                            child: Center(
                              child: Icon(
                                Icons.movie_outlined,
                                color: context.colors.textSubtle,
                                size: 32,
                              ),
                            ),
                          ),

                    // Bottom gradient for readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Rating badge
                    if (showRating && rating != null && rating! > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _ratingColor(rating!).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 12, color: Colors.white),
                              SizedBox(width: 2),
                              Text(
                                rating!.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Type badge
                    if (typeBadge != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeBadge!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    
                    // Favorite badge
                    if (isFavorite)
                      Positioned(
                        top: 8,
                        right: typeBadge != null ? null : 8,
                        left: typeBadge != null ? 8 : null,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    // Add/Added to Watchlist Button
                    if (isAdded)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Color(0xFF22C55E).withValues(alpha: 0.9), // Success green
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
                      )
                    else if (onAddWatchlist != null)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: onAddWatchlist,
                            child: Ink(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: context.colors.primary.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10),

            // ── Title ──
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.colors.textMain,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),

            // ── Subtitle ──
            if (subtitle != null) ...[
              SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.textSubtle,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _ratingColor(double r) {
    if (r >= 8.0) return Color(0xFF22C55E);
    if (r >= 6.5) return Color(0xFFF59E0B);
    return Color(0xFFEF4444);
  }
}
