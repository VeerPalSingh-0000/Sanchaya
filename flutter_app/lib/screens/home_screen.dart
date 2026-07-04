import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/media.dart';
import '../providers/trending_provider.dart';
import '../widgets/media_card.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/section_header.dart';
import '../widgets/profile_app_bar.dart';
import '../models/watchlist_item.dart';
import '../providers/trending_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/watchlist_bottom_sheet.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingMovies = ref.watch(trendingMoviesProvider);
    final trendingTV = ref.watch(trendingTVProvider);
    final trendingAnime = ref.watch(trendingAnimeProvider);

    return Scaffold(
      appBar: const ProfileAppBar(title: 'Sanchaya'),
      body: CustomScrollView(
        slivers: [
        // ── Search Bar Placeholder ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppTheme.textSubtle, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Search movies, TV shows & anime...',
                      style: TextStyle(
                        color: AppTheme.textSubtle.withValues(alpha: 0.7),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Hero Carousel ──
        SliverToBoxAdapter(
          child: trendingMovies.when(
            data: (movies) {
              if (movies.isEmpty) return const SizedBox.shrink();
              final heroItems = movies.take(6).toList();
              return _HeroCarousel(items: heroItems);
            },
            loading: () => const _HeroCarouselShimmer(),
            error: (_, __) => const SizedBox(height: 220),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        // ── Trending Movies ──
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Trending Movies',
            icon: Icons.local_fire_department_rounded,
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverToBoxAdapter(
          child: trendingMovies.when(
            data: (movies) => _MediaRow(items: movies, typeBadge: 'MOVIE'),
            loading: () => ShimmerCardRow(),
            error: (e, _) => _ErrorRow(message: 'Failed to load movies', error: e),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // ── Trending TV ──
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Trending TV Shows',
            icon: Icons.tv_rounded,
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverToBoxAdapter(
          child: trendingTV.when(
            data: (shows) => _MediaRow(items: shows, typeBadge: 'TV'),
            loading: () => ShimmerCardRow(),
            error: (e, _) => _ErrorRow(message: 'Failed to load TV shows', error: e),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // ── Trending Anime ──
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Trending Anime',
            icon: Icons.auto_awesome_rounded,
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.05),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverToBoxAdapter(
          child: trendingAnime.when(
            data: (anime) => _MediaRow(items: anime, typeBadge: 'ANIME'),
            loading: () => ShimmerCardRow(),
            error: (e, _) => _ErrorRow(message: 'Failed to load anime', error: e),
          ),
        ),

        // ── Bottom padding for nav bar ──
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Hero Carousel
// ────────────────────────────────────────────────────────────

class _HeroCarousel extends StatelessWidget {
  final List<Media> items;
  const _HeroCarousel({required this.items});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: items.length,
      options: CarouselOptions(
        height: 220,
        viewportFraction: 0.88,
        enlargeCenterPage: true,
        enlargeFactor: 0.18,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.easeInOutCubic,
      ),
      itemBuilder: (context, index, _) {
        final media = items[index];
        final imageUrl = media.backdropUrl ?? media.posterUrl;

        return GestureDetector(
          onTap: () => context.push('/media/${media.id}'),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                if (imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppTheme.surfaceLight),
                    errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceLight),
                  )
                else
                  Container(color: AppTheme.surfaceLight),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // Left gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4],
                    ),
                  ),
                ),

                // Content
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Genre chips
                      if (media.genres.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          children: media.genres.take(3).map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.4),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                genre.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 8),

                      // Title
                      Text(
                        media.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Rating + year
                      Row(
                        children: [
                          if (media.rating > 0) ...[
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFBBF24), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              media.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (media.releaseDate != null &&
                              media.releaseDate!.length >= 4)
                            Text(
                              media.releaseDate!.substring(0, 4),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )).animate().fadeIn(duration: 500.ms).scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.easeOut,
            );
      },
    );
  }
}

class _HeroCarouselShimmer extends StatelessWidget {
  const _HeroCarouselShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Shimmer.fromColors(
            baseColor: AppTheme.surfaceLight,
            highlightColor: AppTheme.surfaceLight.withValues(alpha: 0.5),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Horizontal Media Row
// ────────────────────────────────────────────────────────────

class _MediaRow extends ConsumerWidget {
  final List<Media> items;
  final String? typeBadge;

  const _MediaRow({required this.items, this.typeBadge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'Nothing trending right now',
            style: TextStyle(color: AppTheme.textSubtle),
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final media = items[index];
          final year = media.releaseDate != null && media.releaseDate!.length >= 4
              ? media.releaseDate!.substring(0, 4)
              : null;

          return MediaCard(
            title: media.title,
            posterUrl: media.posterUrl,
            rating: media.rating,
            subtitle: year,
            typeBadge: typeBadge,
            isAdded: ref.read(watchlistProvider.notifier).isAdded(media),
            onTap: () => context.push('/media/${media.id}'),
            onAddWatchlist: () {
              final user = ref.read(currentUserProvider);
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please sign in to use watchlist')),
                );
                return;
              }
              ref.read(watchlistProvider.notifier).addMediaToWatchlist(media, WatchStatus.planToWatch);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${media.title} added to Plan to Watch',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppTheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ).animate().fadeIn(
                duration: 400.ms,
                delay: Duration(milliseconds: (30 * index).clamp(0, 300)),
              ).slideX(
                begin: 0.1,
                duration: 400.ms,
                delay: Duration(milliseconds: (30 * index).clamp(0, 300)),
                curve: Curves.easeOut,
              );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Error Row
// ────────────────────────────────────────────────────────────

class _ErrorRow extends StatelessWidget {
  final String message;
  final Object? error;
  
  const _ErrorRow({required this.message, this.error});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                color: AppTheme.textSubtle, size: 28),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.textSubtle,
                fontSize: 13,
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.error.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
