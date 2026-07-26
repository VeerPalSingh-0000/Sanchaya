import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/optimized_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/media_details_provider.dart';
import '../providers/watchlist_provider.dart';
import '../providers/palette_provider.dart';
import '../widgets/aesthetic_loader.dart';
import '../models/media.dart';
import '../widgets/episode_tracker_widget.dart';
import '../widgets/reaction_selector.dart';
import '../widgets/watchlist_dropdown_button.dart';
import '../widgets/anime_timeline.dart';
import '../widgets/story_arcs_widget.dart';
import '../widgets/season_episodes_widget.dart';
import '../widgets/notes_widget.dart';
import '../widgets/media_card.dart';

class MediaDetailsScreen extends ConsumerWidget {
  final String mediaId;
  final Media? initialMedia;

  const MediaDetailsScreen({super.key, required this.mediaId, this.initialMedia});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(mediaDetailsProvider(mediaId));
    
    final baseMedia = initialMedia ?? mediaAsync.value;
    final media = mediaAsync.value ?? initialMedia;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Builder(
        builder: (context) {
          if (baseMedia == null) {
            if (mediaAsync.isLoading) {
              return Center(child: AestheticLoader(size: 60));
            }
            return _buildError(context, ref, 'Media not found.');
          }

          final coverUrl = baseMedia.backdropUrl ?? baseMedia.posterUrl;
          final paletteAsync = ref.watch(paletteProvider(baseMedia.posterUrl.isNotEmpty ? baseMedia.posterUrl : coverUrl));
          final dominantColor = paletteAsync.value?.dominantColor?.color;
          final vibrantColor = paletteAsync.value?.vibrantColor?.color ?? paletteAsync.value?.darkVibrantColor?.color;
          final themeColor = vibrantColor ?? dominantColor ?? context.colors.primary;
          final bgTint = (dominantColor ?? context.colors.background).withValues(alpha: 0.15);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: context.colors.background,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Share.share('Check out ${baseMedia.title} on Sanchaya!');
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (coverUrl.isNotEmpty)
                        OptimizedNetworkImage(
                          imageUrl: coverUrl,
                          memCacheHeight: 600, // Large for headers
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              context.colors.background.withValues(alpha: 0.6),
                              bgTint,
                              context.colors.background,
                            ],
                            stops: [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (baseMedia.posterUrl.isNotEmpty) ...[
                            Transform.translate(
                              offset: Offset(0, -30),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 100,
                                    height: 150,
                                    child: OptimizedNetworkImage(
                                      imageUrl: baseMedia.posterUrl,
                                      memCacheHeight: 300,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  baseMedia.title,
                                  style: TextStyle(
                                    fontSize: 24, // slightly smaller to fit
                                    fontWeight: FontWeight.w800,
                                    color: context.colors.textMain,
                                    height: 1.2,
                                  ),
                                ).animate().fadeIn().slideY(begin: 0.1),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      // Meta info row
                      Row(
                        children: [
                          if (baseMedia.rating > 0) ...[
                            Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFBBF24),
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              baseMedia.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16),
                          ],
                          if (baseMedia.releaseDate != null &&
                              baseMedia.releaseDate!.length >= 4) ...[
                            Text(
                              baseMedia.releaseDate!.substring(0, 4),
                              style: TextStyle(
                                fontSize: 14,
                                color: context.colors.textSubtle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 16),
                          ],
                          if (baseMedia.totalEpisodes != null &&
                              baseMedia.totalEpisodes! > 0) ...[
                            Text(
                              '${baseMedia.totalEpisodes} EPS',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.colors.textSubtle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 16),
                          ],
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              baseMedia.type.name.toUpperCase(),
                              style: TextStyle(
                                color: context.colors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                      SizedBox(height: 16),

                      // Genres
                      if (baseMedia.genres.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: baseMedia.genres.take(3).map((genre) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.surfaceLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                genre.name,
                                style: TextStyle(
                                  color: context.colors.textSubtle,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                      if (baseMedia.originalTitle != null &&
                          baseMedia.originalTitle!.isNotEmpty &&
                          baseMedia.originalTitle != baseMedia.title) ...[
                        SizedBox(height: 12),
                        Text(
                          'Original Title: ${baseMedia.originalTitle}',
                          style: TextStyle(
                            color: context.colors.textSubtle,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      if (baseMedia.studios != null &&
                          baseMedia.studios!.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          'Studio: ${baseMedia.studios!.join(', ')}',
                          style: TextStyle(
                            color: context.colors.textSubtle,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      SizedBox(height: 24),

                      // --- Watchlist Advanced Controls ---
                      Consumer(
                        builder: (context, ref, child) {
                          ref.watch(watchlistProvider);
                          final watchlistNotifier = ref.read(watchlistProvider.notifier);
                          final existingItem = watchlistNotifier.getItem(
                            baseMedia.id,
                            baseMedia.type,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: WatchlistDropdownButton(
                                      media: baseMedia,
                                    ),
                                  ),

                                  if (baseMedia.trailer != null &&
                                      baseMedia.trailer!.isNotEmpty) ...[
                                    SizedBox(width: 12),
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final url = Uri.parse(baseMedia.trailer!);
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url);
                                          }
                                        },
                                        icon: Icon(
                                          Icons.play_circle_fill_rounded,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          'Trailer',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: themeColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  if (existingItem != null) ...[
                                    SizedBox(width: 12),
                                    ReactionSelectorWidget(item: existingItem),
                                  ],
                                ],
                              ),
                              if (existingItem != null &&
                                  existingItem.status ==
                                      'WATCHING') ...[
                                SizedBox(height: 16),
                                EpisodeTrackerWidget(item: existingItem),
                              ],

                              if (existingItem != null) ...[
                                SizedBox(height: 24),
                                NotesWidget(item: existingItem).animate().fadeIn(delay: 280.ms),
                              ],
                            ],
                          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1);
                        },
                      ),

                      SizedBox(height: 24),
                      // Overview
                      Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textMain,
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                      SizedBox(height: 12),
                      _CollapsibleOverview(
                        text: (media?.overview != null && media!.overview.isNotEmpty)
                            ? media!.overview
                            : (baseMedia.overview.isNotEmpty ? baseMedia.overview : 'No overview available.'),
                      ).animate().fadeIn(delay: 400.ms),

                      // --- Franchise / Seasons Timeline ---
                      if (media != null && media.seasons != null && media.seasons!.isNotEmpty)
                        AnimeTimeline(media: media),

                      // --- Seasons & Episodes List (Non-Anime TV) ---
                      if (media != null && media.type == MediaType.series &&
                          media.malId == null &&
                          !media.id.startsWith('anilist-'))
                        SeasonEpisodesWidget(media: media),

                      // --- Story Arcs & Episodes List (Anime) ---
                      if (media != null && (media.type == MediaType.anime ||
                          media.malId != null ||
                          media.id.startsWith('anilist-')))
                        StoryArcsWidget(media: media),

                      // --- Similar Titles ---
                      if (media != null && media.id.startsWith('tmdb-'))
                        _SimilarTitlesRow(mediaId: media.id),

                      // --- Loading Indicator for lower screen ---
                      if (mediaAsync.isLoading) ...[
                        SizedBox(height: 32),
                        Center(
                          child: AestheticLoader(size: 40),
                        ),
                        SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    final watchlistItem = ref.watch(watchlistProvider).value?.where((e) => e.externalId == mediaId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: context.colors.background,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: context.colors.primary,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textSubtle,
                  fontSize: 14,
                ),
              ),
              if (watchlistItem != null) ...[
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(watchlistProvider.notifier).remove(watchlistItem.externalId, watchlistItem.mediaType);
                    if (context.mounted) {
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Removed from watchlist')),
                      );
                    }
                  },
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.white),
                  label: Text('Remove from Watchlist', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}


class _CollapsibleOverview extends StatefulWidget {
  final String text;
  const _CollapsibleOverview({required this.text});

  @override
  State<_CollapsibleOverview> createState() => _CollapsibleOverviewState();
}

class _CollapsibleOverviewState extends State<_CollapsibleOverview> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: _isExpanded
                ? BoxConstraints()
                : BoxConstraints(maxHeight: 100),
            child: Stack(
              children: [
                Text(
                  widget.text,
                  style: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  softWrap: true,
                  overflow: _isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.fade,
                ),
                if (!_isExpanded)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.colors.background.withValues(alpha: 0.0),
                            context.colors.background,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Text(
            _isExpanded ? 'Show less' : 'Read more',
            style: TextStyle(
              color: context.colors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SimilarTitlesRow extends ConsumerWidget {
  final String mediaId;

  const _SimilarTitlesRow({required this.mediaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarAsync = ref.watch(similarTitlesProvider(mediaId));

    return similarAsync.when(
      data: (similar) {
        if (similar.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Text(
                'Similar Titles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textMain,
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                scrollDirection: Axis.horizontal,
                itemCount: similar.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: SizedBox(
                      width: 120,
                      child: MediaCard(
                        title: similar[index].title,
                        posterUrl: similar[index].posterUrl ?? '',
                        rating: similar[index].rating,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(), // Don't show loading for similar titles to keep UI clean
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
