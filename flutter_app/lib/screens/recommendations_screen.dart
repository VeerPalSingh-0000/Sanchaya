import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/media.dart';
import '../providers/recommendations_provider.dart';
import '../widgets/media_card.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/profile_app_bar.dart';
import '../screens/media_details_screen.dart';

import '../widgets/error_retry_widget.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  String _selectedFilter = 'Everything';

  @override
  Widget build(BuildContext context) {
    final recommendationsAsync = ref.watch(recommendationsProvider);

    return Scaffold(
      appBar: const ProfileAppBar(title: 'For You'),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(recommendationsProvider);
            return await ref.read(recommendationsProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              recommendationsAsync.when(
                data: (data) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Discoveries',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.topGenres.isNotEmpty
                                ? 'Based on your love for ${data.topGenres.take(3).join(', ')}'
                                : 'Top picks for you',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSubtle,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('Everything'),
                                const SizedBox(width: 8),
                                _buildFilterChip('Movies'),
                                const SizedBox(width: 8),
                                _buildFilterChip('Webseries'),
                                const SizedBox(width: 8),
                                _buildFilterChip('Anime'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              recommendationsAsync.when(
                data: (data) {
                  if (data.results.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No recommendations available',
                          style: TextStyle(color: AppTheme.textSubtle),
                        ),
                      ),
                    );
                  }
                  
                  final filteredResults = data.results.where((res) {
                    if (_selectedFilter == 'Everything') return true;
                    if (_selectedFilter == 'Movies') return res.media.type == MediaType.movie;
                    if (_selectedFilter == 'Webseries') return res.media.type == MediaType.series;
                    if (_selectedFilter == 'Anime') return res.media.type == MediaType.anime;
                    return true;
                  }).toList();
                  
                  if (filteredResults.isEmpty) {
                     return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No $_selectedFilter recommendations',
                          style: const TextStyle(color: AppTheme.textSubtle),
                        ),
                      ),
                    );
                  }
                  
                  return _RecommendationsGrid(results: filteredResults);
                },
                loading: () => const _LoadingGrid(),
                error: (e, _) => SliverFillRemaining(
                  child: ErrorRetryWidget(
                    message: 'Failed to load recommendations',
                    error: e,
                    onRetry: () => ref.invalidate(recommendationsProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = label);
        }
      },
      backgroundColor: Colors.transparent,
      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : AppTheme.textSubtle,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _RecommendationsGrid extends StatelessWidget {
  final List<RecommendationResult> results;
  const _RecommendationsGrid({required this.results});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55, // Changed to 0.55 to accommodate the match tag
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final rec = results[index];
            final media = rec.media;
            final year = media.releaseDate != null && media.releaseDate!.length >= 4
                ? media.releaseDate!.substring(0, 4)
                : null;

            String? badge;
            switch (media.type) {
              case MediaType.movie: badge = 'MOVIE'; break;
              case MediaType.series: badge = 'TV'; break;
              case MediaType.anime: badge = 'ANIME'; break;
            }

            return GestureDetector(
              onTap: () {
                String mediaRouteId = media.externalId;
                if (!mediaRouteId.startsWith('tmdb-') && !mediaRouteId.startsWith('anilist-')) {
                  switch (media.type) {
                    case MediaType.movie: mediaRouteId = 'tmdb-movie-${media.externalId}'; break;
                    case MediaType.series: mediaRouteId = 'tmdb-tv-${media.externalId}'; break;
                    case MediaType.anime: mediaRouteId = 'anilist-${media.externalId}'; break;
                  }
                }
                context.push('/media/$mediaRouteId');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MediaCard(
                    title: media.title,
                    posterUrl: media.posterUrl,
                    rating: media.rating,
                    subtitle: year,
                    width: double.infinity,
                    typeBadge: badge,
                  ),
                  if (rec.matchedGenres.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Match: ${rec.matchedGenres.first}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]
                ],
              ).animate().fadeIn(
                duration: 300.ms,
                delay: index > 10 ? Duration.zero : Duration(milliseconds: (20 * index).clamp(0, 150)),
              ),
            );
          },
          childCount: results.length,
        ),
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const ShimmerCard(
            width: double.infinity,
            height: 220,
          ),
          childCount: 6,
        ),
      ),
    );
  }
}
