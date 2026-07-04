import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/media.dart';
import '../providers/trending_provider.dart';
import '../widgets/media_card.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/profile_app_bar.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, we will use Trending Movies as our recommended content in Flutter 
    // since we do not have a separate backend endpoint hooked up yet.
    final trendingMovies = ref.watch(trendingMoviesProvider);

    return Scaffold(
      appBar: const ProfileAppBar(title: 'For You'),
      body: SafeArea(
        bottom: false,
        child: trendingMovies.when(
          data: (movies) {
            if (movies.isEmpty) {
              return const Center(
                child: Text(
                  'No recommendations available',
                  style: TextStyle(color: AppTheme.textSubtle),
                ),
              );
            }
            return _RecommendationsGrid(results: movies);
          },
          loading: () => const _LoadingGrid(),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.error, size: 36),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load recommendations',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendationsGrid extends StatelessWidget {
  final List<Media> results;
  const _RecommendationsGrid({required this.results});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final media = results[index];
        final year = media.releaseDate != null && media.releaseDate!.length >= 4
            ? media.releaseDate!.substring(0, 4)
            : null;

        String? badge;
        switch (media.type) {
          case MediaType.movie:
            badge = 'MOVIE';
            break;
          case MediaType.series:
            badge = 'TV';
            break;
          case MediaType.anime:
            badge = 'ANIME';
            break;
        }

        return MediaCard(
          title: media.title,
          posterUrl: media.posterUrl,
          rating: media.rating,
          subtitle: year,
          width: double.infinity,
          height: 220,
          typeBadge: badge,
        ).animate().fadeIn(
              duration: 300.ms,
              delay: Duration(milliseconds: (30 * index).clamp(0, 300)),
            );
      },
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const ShimmerCard(
        width: double.infinity,
        height: 220,
      ),
    );
  }
}
