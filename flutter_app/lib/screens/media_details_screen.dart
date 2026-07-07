import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../providers/media_details_provider.dart';
import '../providers/franchise_timeline_provider.dart';
import '../providers/watchlist_provider.dart';
import '../models/media.dart';
import '../models/watchlist_item.dart';
import '../widgets/watchlist_bottom_sheet.dart';
import '../widgets/episode_tracker_widget.dart';
import '../widgets/reaction_selector.dart';
import '../widgets/watchlist_dropdown_button.dart';
import '../widgets/anime_timeline.dart';
import '../widgets/story_arcs_widget.dart';
import '../widgets/season_episodes_widget.dart';

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
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
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
                          placeholder: (_, _) =>
                              Container(color: AppTheme.surfaceLight),
                          errorWidget: (_, _, _) => Container(
                            color: AppTheme.surfaceLight,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined, color: AppTheme.textSubtle, size: 48),
                            ),
                          ),
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
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFBBF24),
                              size: 18,
                            ),
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
                          if (media.releaseDate != null &&
                              media.releaseDate!.length >= 4) ...[
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
                          if (media.totalEpisodes != null && media.totalEpisodes! > 0) ...[
                            Text(
                              '${media.totalEpisodes} EPS',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSubtle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                          children: media.genres.take(3).map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(20),
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

                      if (media.originalTitle != null && media.originalTitle!.isNotEmpty && media.originalTitle != media.title) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Original Title: ${media.originalTitle}',
                          style: const TextStyle(color: AppTheme.textSubtle, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ],
                      
                      if (media.studios != null && media.studios!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Studio: ${media.studios!.join(', ')}',
                          style: const TextStyle(color: AppTheme.textSubtle, fontSize: 13),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // --- Watchlist Advanced Controls ---
                      Consumer(
                        builder: (context, ref, child) {
                          final watchlistNotifier = ref.watch(
                            watchlistProvider.notifier,
                          );
                          final existingItem = watchlistNotifier.getItem(
                            media.externalId,
                            media.type,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: WatchlistDropdownButton(
                                      media: media,
                                    ),
                                  ),
                                  
                                  if (media.trailer != null && media.trailer!.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final url = Uri.parse(media.trailer!);
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url);
                                          }
                                        },
                                        icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                                        label: const Text('Trailer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],

                                  if (existingItem != null) ...[
                                    const SizedBox(width: 12),
                                    ReactionSelectorWidget(item: existingItem),
                                  ],
                                ],
                              ),
                              if (existingItem != null &&
                                  existingItem.status ==
                                      WatchStatus.watching) ...[
                                const SizedBox(height: 16),
                                EpisodeTrackerWidget(item: existingItem),
                              ],
                            ],
                          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1);
                        },
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
                      _CollapsibleOverview(
                        text: media.overview.isNotEmpty
                            ? media.overview
                            : 'No overview available.',
                      ).animate().fadeIn(delay: 400.ms),

                      // --- Franchise / Seasons Timeline ---
                      if (media.seasons != null && media.seasons!.isNotEmpty)
                        AnimeTimeline(media: media),

                      // --- Seasons & Episodes List (Non-Anime TV) ---
                      if (media.type == MediaType.series && media.malId == null && !media.id.startsWith('anilist-'))
                        SeasonEpisodesWidget(media: media),

                      // --- Story Arcs & Episodes List (Anime) ---
                      if (media.type == MediaType.anime || media.malId != null || media.id.startsWith('anilist-'))
                        StoryArcsWidget(media: media),
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
        error: (err, stack) =>
            _buildError(context, 'Failed to load details.\\n$err'),
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
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSubtle,
                  fontSize: 14,
                ),
              ),
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: _isExpanded
                ? const BoxConstraints()
                : const BoxConstraints(maxHeight: 100),
            child: Stack(
              children: [
                Text(
                  widget.text,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
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
                            AppTheme.background.withValues(alpha: 0.0),
                            AppTheme.background,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Text(
            _isExpanded ? 'Show less' : 'Read more',
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
