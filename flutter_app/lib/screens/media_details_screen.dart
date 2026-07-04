import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../providers/media_details_provider.dart';
import '../providers/franchise_timeline_provider.dart';
import '../providers/watchlist_provider.dart';
import '../models/media.dart';
import '../widgets/watchlist_bottom_sheet.dart';
import '../widgets/episode_tracker_widget.dart';
import '../widgets/reaction_selector.dart';

class MediaDetailsScreen extends ConsumerWidget {
  final String mediaId;

  const MediaDetailsScreen({super.key, required this.mediaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(mediaDetailsProvider(mediaId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: mediaAsync.when(
        data: (media) {
          if (media == null) {
            return _buildError(context, 'Media not found.');
          }

          final coverUrl = media.backdropUrl ?? media.posterUrl;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppTheme.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (coverUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppTheme.surfaceLight),
                          errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceLight),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.background.withValues(alpha: 0.6),
                              Colors.transparent,
                              AppTheme.background,
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        media.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                          height: 1.2,
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1),
                      
                      const SizedBox(height: 12),

                      // Meta info row
                      Row(
                        children: [
                          if (media.rating > 0) ...[
                            const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              media.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (media.releaseDate != null && media.releaseDate!.length >= 4) ...[
                            Text(
                              media.releaseDate!.substring(0, 4),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSubtle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              media.type.name.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                      const SizedBox(height: 16),

                      // Genres
                      if (media.genres.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: media.genres.map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: Text(
                                genre.name,
                                style: const TextStyle(
                                  color: AppTheme.textSubtle,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                      const SizedBox(height: 24),

                      // --- Watchlist Advanced Controls ---
                      Consumer(
                        builder: (context, ref, child) {
                          final watchlistNotifier = ref.watch(watchlistProvider.notifier);
                          final existingItem = watchlistNotifier.getItem(media.externalId, media.type);
                          final aggregateStatus = watchlistNotifier.getAggregateStatus(media);
                          final isAdded = watchlistNotifier.getFranchiseItems(media).isNotEmpty;

                          String buttonLabel = 'Add to Watchlist';
                          Color buttonColor = AppTheme.primary;
                          if (isAdded) {
                            switch (aggregateStatus) {
                              case WatchStatus.planToWatch:
                                buttonLabel = 'Plan to Watch';
                                buttonColor = const Color(0xFFF59E0B);
                                break;
                              case WatchStatus.watching:
                                buttonLabel = 'Watching';
                                buttonColor = const Color(0xFF22C55E);
                                break;
                              case WatchStatus.completed:
                                buttonLabel = 'Completed';
                                buttonColor = const Color(0xFF3B82F6);
                                break;
                              case WatchStatus.onHold:
                                buttonLabel = 'On Hold';
                                buttonColor = const Color(0xFF94A3B8);
                                break;
                              case WatchStatus.dropped:
                                buttonLabel = 'Dropped';
                                buttonColor = const Color(0xFFEF4444);
                                break;
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Material(
                                      color: isAdded ? buttonColor.withValues(alpha: 0.1) : buttonColor,
                                      borderRadius: BorderRadius.circular(24),
                                      child: InkWell(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => WatchlistBottomSheet(media: media),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(24),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(
                                              color: isAdded ? buttonColor.withValues(alpha: 0.5) : Colors.transparent,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                isAdded ? Icons.check_rounded : Icons.add_rounded,
                                                color: isAdded ? buttonColor : Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                buttonLabel,
                                                style: TextStyle(
                                                  color: isAdded ? buttonColor : Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  if (existingItem != null) ...[
                                    const SizedBox(width: 12),
                                    ReactionSelectorWidget(item: existingItem),
                                  ],
                                ],
                              ),
                              if (existingItem != null && existingItem.status == WatchStatus.watching) ...[
                                const SizedBox(height: 16),
                                EpisodeTrackerWidget(item: existingItem),
                              ],
                            ],
                          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1);
                        }
                      ),

                      const SizedBox(height: 24),

                      // Overview
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 12),
                      Text(
                        media.overview.isNotEmpty ? media.overview : 'No overview available.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSubtle,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      
                      const SizedBox(height: 40),

                      _FranchiseTimeline(media: media),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (err, stack) => _buildError(context, 'Failed to load details.\\n$err'),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.primary, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSubtle, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FranchiseTimeline extends ConsumerWidget {
  final Media media;

  const _FranchiseTimeline({required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(franchiseTimelineProvider(media));

    return timelineAsync.when(
      data: (arcs) {
        if (arcs.isEmpty) return const SizedBox.shrink();

        final title = media.type == MediaType.anime 
            ? 'Anime Arcs / Timeline' 
            : (media.type == MediaType.series ? 'Seasons' : 'Collection Parts');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 16),
            ...arcs.map((arc) {
              final isCurrent = arc.relationType == 'CURRENT' || arc.mediaId == media.id || arc.mediaId == media.externalId;
              
              return GestureDetector(
                onTap: () {
                  if (arc.mediaId != null && !isCurrent) {
                    context.push('/media/${arc.mediaId}');
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrent 
                        ? AppTheme.primary.withValues(alpha: 0.1) 
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent 
                          ? AppTheme.primary.withValues(alpha: 0.5) 
                          : AppTheme.divider,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (arc.posterUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: arc.posterUrl!,
                            width: 60,
                            height: 85,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppTheme.surfaceLight),
                            errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceLight),
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 85,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.movie, color: AppTheme.textMuted),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              arc.name,
                              style: TextStyle(
                                color: isCurrent ? AppTheme.primary : AppTheme.textMain,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${arc.format ?? (media.type == MediaType.series ? "Season ${arc.number}" : "Movie")} • ${arc.airDate != null && arc.airDate!.length >= 4 ? arc.airDate!.substring(0, 4) : 'TBA'}',
                              style: const TextStyle(
                                color: AppTheme.textSubtle,
                                fontSize: 12,
                              ),
                            ),
                            if (arc.relationType != null && arc.relationType != 'CURRENT') ...[
                              const SizedBox(height: 4),
                              Text(
                                arc.relationType!.replaceAll('_', ' '),
                                style: const TextStyle(
                                  color: AppTheme.textSubtle,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else if (arc.episodeCount > 0 && media.type == MediaType.series) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${arc.episodeCount} Episodes',
                                style: const TextStyle(
                                  color: AppTheme.textSubtle,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

