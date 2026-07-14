import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../models/media.dart';
import '../providers/trending_provider.dart';
import '../widgets/media_card.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/section_header.dart';
import '../widgets/profile_app_bar.dart';
import '../providers/watchlist_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/error_retry_widget.dart';
import '../widgets/aesthetic_loader.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingMovies = ref.watch(trendingMoviesProvider);
    final trendingTV = ref.watch(trendingTVProvider);
    final trendingAnime = ref.watch(trendingAnimeProvider);
    final watchlistAsync = ref.watch(watchlistProvider);

    final isInitialLoading = !trendingMovies.hasValue || 
                             !trendingTV.hasValue || 
                             !trendingAnime.hasValue || 
                             !watchlistAsync.hasValue;

    if (isInitialLoading) {
      return Scaffold(
        appBar: ProfileAppBar(title: 'Sanchaya'),
        backgroundColor: context.colors.background,
        body: Center(
          child: AestheticLoader(),
        ),
      );
    }


    return Scaffold(
      appBar: ProfileAppBar(title: 'Sanchaya'),
      body: RefreshIndicator(
        color: context.colors.primary,
        backgroundColor: context.colors.surfaceLight,
        onRefresh: () async {
          ref.invalidate(trendingMoviesProvider);
          ref.invalidate(trendingTVProvider);
          ref.invalidate(trendingAnimeProvider);
          await ref.read(watchlistProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
        // ── Search Bar Placeholder ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: GestureDetector(
              onTap: () {
                ref.read(homeSearchQueryProvider.notifier).updateQuery('');
                ref.read(homeSearchFilterProvider.notifier).updateFilter(MediaFilter.all);
                context.push('/search');
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.colors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.divider, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: context.colors.textSubtle, size: 22),
                    SizedBox(width: 12),
                    Text(
                      'Search movies, TV shows & anime...',
                      style: TextStyle(
                        color: context.colors.textSubtle.withValues(alpha: 0.7),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Hero Carousel ──
        SliverToBoxAdapter(
          child: trendingMovies.when(
            data: (movies) {
              if (movies.isEmpty) return SizedBox.shrink();
              final heroItems = movies.take(6).toList();
              return _HeroCarousel(items: heroItems);
            },
            loading: () => const _HeroCarouselShimmer(),
            error: (_, _) => SizedBox(height: 220),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: 28)),

        // ── Continue Watching ──
        SliverToBoxAdapter(
          child: watchlistAsync.when(
            data: (watchlist) {
              final watching = watchlist.where((i) => i.status == WatchStatus.watching).toList();
              if (watching.isEmpty) return SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SectionHeader(
                    title: 'Continue Watching',
                    icon: Icons.play_circle_fill_rounded,
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
                  SizedBox(height: 14),
                      SizedBox(
                        height: 280,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          itemCount: watching.length,
                          separatorBuilder: (_, _) => SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final item = watching[index];
                            final progressText = (item.progress != null && item.totalEpisodes != null && item.totalEpisodes! > 0)
                                ? 'EP ${item.progress}/${item.totalEpisodes}'
                                : null;

                            return MediaCard(
                              title: item.title,
                              posterUrl: item.franchisePosterUrl ?? item.posterUrl,
                              rating: item.rating,
                              subtitle: progressText,
                              typeBadge: item.mediaType.name.toUpperCase(),
                              isAdded: true,
                              onTap: () {
                                String mediaRouteId = item.externalId;
                                if (!mediaRouteId.startsWith('tmdb-') && !mediaRouteId.startsWith('anilist-')) {
                                  switch (item.mediaType) {
                                    case MediaType.movie: mediaRouteId = 'tmdb-movie-${item.externalId}'; break;
                                    case MediaType.series: mediaRouteId = 'tmdb-tv-${item.externalId}'; break;
                                    case MediaType.anime: mediaRouteId = 'anilist-${item.externalId}'; break;
                                  }
                                }
                                context.push('/media/$mediaRouteId');
                              },
                            ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: 30 * index));
                          },
                        ),
                      ),
                      SizedBox(height: 32),
                    ],
                  );
            },
            loading: () => SizedBox.shrink(),
            error: (_, _) => SizedBox.shrink(),
          ),
        ),

        // ── Trending Movies ──
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Trending Movies',
            icon: Icons.local_fire_department_rounded,
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverToBoxAdapter(
          child: trendingMovies.when(
            data: (movies) => _MediaRow(items: movies, typeBadge: 'MOVIE'),
            loading: () => ShimmerCardRow(),
            error: (e, _) => ErrorRetryWidget(
              message: 'Failed to load movies',
              error: e,
              onRetry: () => ref.invalidate(trendingMoviesProvider),
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: 32)),

        // ── Trending TV ──
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Trending TV Shows',
            icon: Icons.tv_rounded,
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverToBoxAdapter(
          child: trendingTV.when(
            data: (shows) => _MediaRow(items: shows, typeBadge: 'TV'),
            loading: () => ShimmerCardRow(),
            error: (e, _) => ErrorRetryWidget(
              message: 'Failed to load TV shows',
              error: e,
              onRetry: () => ref.invalidate(trendingTVProvider),
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: 32)),

        // ── Trending Anime ──
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Trending Anime',
            icon: Icons.auto_awesome_rounded,
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.05),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverToBoxAdapter(
          child: trendingAnime.when(
            data: (anime) => _MediaRow(items: anime, typeBadge: 'ANIME'),
            loading: () => ShimmerCardRow(),
            error: (e, _) => ErrorRetryWidget(
              message: 'Failed to load anime',
              error: e,
              onRetry: () => ref.invalidate(trendingAnimeProvider),
            ),
          ),
        ),

        // ── Bottom padding for nav bar ──
        SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    ),
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
        autoPlayInterval: Duration(seconds: 5),
        autoPlayAnimationDuration: Duration(milliseconds: 800),
        autoPlayCurve: Curves.easeInOutCubic,
      ),
      itemBuilder: (context, index, _) {
        final media = items[index];
        final imageUrl = media.backdropUrl ?? media.posterUrl;

        return GestureDetector(
          onTap: () => context.push('/media/${media.id}'),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: Offset(0, 8),
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
                    placeholder: (_, _) => Container(color: context.colors.surfaceLight),
                    errorWidget: (_, _, _) => Container(
                      color: context.colors.surfaceLight,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined, color: context.colors.textSubtle, size: 32),
                      ),
                    ),
                  )
                else
                  Container(color: context.colors.surfaceLight),

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
                      stops: [0.0, 0.5, 1.0],
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
                      stops: [0.0, 0.4],
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: context.colors.primary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: context.colors.primary.withValues(alpha: 0.4),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                genre.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      SizedBox(height: 8),

                      // Title
                      Text(
                        media.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),

                      SizedBox(height: 6),

                      // Rating + year
                      Row(
                        children: [
                          if (media.rating > 0) ...[
                            Icon(Icons.star_rounded,
                                color: Color(0xFFFBBF24), size: 16),
                            SizedBox(width: 4),
                            Text(
                              media.rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 12),
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
              begin: Offset(0.95, 0.95),
              end: Offset(1, 1),
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
          margin: EdgeInsets.symmetric(vertical: 8),
          child: Shimmer.fromColors(
            baseColor: context.colors.surfaceLight,
            highlightColor: context.colors.surfaceLight.withValues(alpha: 0.5),
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.surfaceLight,
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
      return SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'Nothing trending right now',
            style: TextStyle(color: context.colors.textSubtle),
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(width: 14),
        itemBuilder: (context, index) {
          final media = items[index];
          final year = media.releaseDate != null && media.releaseDate!.length >= 4
              ? media.releaseDate!.substring(0, 4)
              : null;

          return MediaCard(
            title: media.title,
            posterUrl: media.franchisePosterUrl ?? media.posterUrl,
            rating: media.rating,
            subtitle: year,
            typeBadge: typeBadge,
            isAdded: ref.watch(watchlistProvider.notifier).isAdded(media),
            onTap: () => context.push('/media/${media.id}'),
            onAddWatchlist: () {
              final user = ref.read(currentUserProvider);
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please sign in to use watchlist')),
                );
                return;
              }
              ref.read(watchlistProvider.notifier).addMediaToWatchlist(media, WatchStatus.planToWatch);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${media.title} added to Plan to Watch',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: context.colors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  duration: Duration(seconds: 2),
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

// Removed _ErrorRow in favor of ErrorRetryWidget
