import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'aesthetic_loader.dart';
import '../models/media.dart';
import '../providers/franchise_timeline_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/watchlist_bottom_sheet.dart';

class AnimeTimeline extends ConsumerStatefulWidget {
  final Media media;

  const AnimeTimeline({super.key, required this.media});

  @override
  ConsumerState<AnimeTimeline> createState() => _AnimeTimelineState();
}

class _AnimeTimelineState extends ConsumerState<AnimeTimeline> {
  bool _mainStoryOnly = true;

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(franchiseTimelineProvider(widget.media));

    return timelineAsync.when(
      data: (arcs) {
        if (arcs.isEmpty) return SizedBox.shrink();

        final isAnime =
            widget.media.type == MediaType.anime ||
            (widget.media.originCountry == 'JP' &&
                widget.media.genres.any((g) => g.name == 'Animation'));

        final title = isAnime
            ? 'Franchise'
            : (widget.media.type == MediaType.series
                  ? 'Seasons'
                  : 'Collection Parts');

        final displayedArcs = _mainStoryOnly
            ? arcs.where((arc) {
                if (arc.relationType != null) {
                  final canon = ['CURRENT', 'PREQUEL', 'SEQUEL', 'PARENT'];
                  return canon.contains(arc.relationType!.toUpperCase());
                }
                return true; // Fallback if no relationType
              }).toList()
            : arcs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textMain,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'WATCH ORDER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),

                if (isAnime)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    padding: EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _mainStoryOnly = true),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _mainStoryOnly
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 12,
                                  color: _mainStoryOnly
                                      ? Colors.amber
                                      : Colors.white54,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'MAIN STORY',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: _mainStoryOnly
                                        ? Colors.white
                                        : Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _mainStoryOnly = false),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: !_mainStoryOnly
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.layers_rounded,
                                  size: 12,
                                  color: !_mainStoryOnly
                                      ? Colors.blueAccent
                                      : Colors.white54,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'ALL CONTENT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: !_mainStoryOnly
                                        ? Colors.white
                                        : Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20),

            // Carousel
            SizedBox(
              height: 310,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: displayedArcs.length,
                separatorBuilder: (context, index) => SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final arc = displayedArcs[index];
                  final isCurrent =
                      arc.relationType == 'CURRENT' ||
                      arc.mediaId == widget.media.id ||
                      arc.mediaId == widget.media.externalId;
                  final indexStr = (index + 1).toString().padLeft(2, '0');

                  final cleanMediaId = (arc.mediaId ?? widget.media.externalId)
                          .replaceAll('anilist-', '')
                          .replaceAll('tmdb-movie-', '')
                          .replaceAll('tmdb-tv-', '');
                  final targetType = arc.mediaType ?? widget.media.type;
                  final prefix = isAnime
                      ? 'anilist-'
                      : (targetType == MediaType.movie ? 'tmdb-movie-' : 'tmdb-tv-');

                  final pseudoMedia = Media(
                    id: '$prefix$cleanMediaId',
                    externalId: cleanMediaId,
                    type: arc.mediaType ?? widget.media.type,
                    title: arc.name,
                    overview: arc.overview,
                    posterUrl: arc.posterUrl ?? widget.media.posterUrl,
                    genres: widget.media.genres,
                    rating: 0.0,
                    voteCount: 0,
                    status: 'Airing',
                    franchiseId: widget.media.franchiseId,
                    franchiseTitle:
                        widget.media.franchiseTitle ?? widget.media.title,
                    franchisePosterUrl:
                        widget.media.franchisePosterUrl ??
                        widget.media.posterUrl,
                  );

                  return GestureDetector(
                    onTap: () {
                      if (arc.mediaId != null && !isCurrent) {
                        String routeId = pseudoMedia.id;
                        if (routeId.contains('-season-')) {
                          routeId = routeId.split('-season-').first;
                        }
                        context.push('/media/$routeId');
                      }
                    },
                    child: SizedBox(
                      width: 140,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Giant background number
                          Positioned(
                            top: -15,
                            left: -10,
                            child: Text(
                              indexStr,
                              style: TextStyle(
                                fontSize: 90,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -5,
                                color: Colors.white.withValues(alpha: 0.03),
                              ),
                            ),
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Poster
                              Container(
                                width: 140,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isCurrent
                                        ? context.colors.primary.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.white.withValues(alpha: 0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 15,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: arc.posterUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: arc.posterUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (_, _) => Container(
                                                color: context.colors.surfaceLight,
                                              ),
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
                                            )
                                          : Container(
                                              color: context.colors.surfaceLight,
                                              child: Icon(
                                                Icons.movie,
                                                color: context.colors.textMuted,
                                              ),
                                            ),
                                    ),
                                    // Part Badge
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'PART $indexStr',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 12),

                              // Info
                              Text(
                                arc.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrent
                                      ? context.colors.primary
                                      : context.colors.textMain,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 4),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (arc.episodeCount > 0) ...[
                                    Text(
                                      '${arc.episodeCount} EP',
                                      style: TextStyle(
                                        color: context.colors.textSubtle.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      ' • ',
                                      style: TextStyle(
                                        color: context.colors.textMuted.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                  if (arc.format != null)
                                    Text(
                                      arc.format!.toUpperCase(),
                                      style: TextStyle(
                                        color: context.colors.textSubtle.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: _StatusButton(
                                  media: pseudoMedia,
                                  franchiseTimeline: arcs,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
      },
      loading: () => Center(
        child: AestheticLoader(size: 40),
      ),
      error: (_, _) => SizedBox.shrink(),
    );
  }
}

class _StatusButton extends ConsumerWidget {
  final Media media;
  final List<Season>? franchiseTimeline;

  const _StatusButton({required this.media, this.franchiseTimeline});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(watchlistProvider);
    final watchlistNotifier = ref.read(watchlistProvider.notifier);
    final existingItem = watchlistNotifier.getItem(media.id, media.type);

    final status = existingItem?.status;
    final isAdded = status != null;

    Color color = Colors.white70;
    Color bgColor = Colors.white.withValues(alpha: 0.05);
    Color borderColor = Colors.white.withValues(alpha: 0.1);
    String label = '+ Add to List';

    if (isAdded) {
      switch (status) {
        case WatchStatus.planToWatch:
          color = Color(0xFFF59E0B);
          label = 'Plan to Watch';
          break;
        case WatchStatus.watching:
          color = Color(0xFF22C55E);
          label = 'Watching';
          break;
        case WatchStatus.completed:
          color = Color(0xFF3B82F6);
          label = 'Completed';
          break;
        case WatchStatus.onHold:
          color = Color(0xFF94A3B8);
          label = 'On Hold';
          break;
        case WatchStatus.dropped:
          color = Color(0xFFEF4444);
          label = 'Dropped';
          break;
      }
      bgColor = color.withValues(alpha: 0.1);
      borderColor = color.withValues(alpha: 0.4);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => WatchlistBottomSheet(
            media: media,
            franchiseTimeline: franchiseTimeline,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAdded) ...[
              Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scaleXY(
                    begin: 1.0,
                    end: 1.2,
                    duration: 1000.ms,
                    curve: Curves.easeInOutSine,
                  )
                  .then()
                  .scaleXY(
                    begin: 1.2,
                    end: 1.0,
                    duration: 1000.ms,
                    curve: Curves.easeInOutSine,
                  ),
              SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isAdded ? color : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
