import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import '../providers/watchlist_provider.dart';
import '../providers/service_providers.dart';

class WatchlistDropdownButton extends ConsumerWidget {
  final Media media;
  final bool isCompact;

  const WatchlistDropdownButton({
    super.key,
    required this.media,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(watchlistProvider);
    final watchlistNotifier = ref.read(watchlistProvider.notifier);
    final existingItem = watchlistNotifier.getItem(media.id, media.type);
    final franchiseItems = watchlistNotifier.getFranchiseItems(media);
    final isAdded = existingItem != null;

    String buttonLabel = 'Add to Watchlist';
    Color buttonColor = context.colors.primary;
    if (isAdded) {
      switch (existingItem.status) {
        case WatchStatus.planToWatch:
          buttonLabel = 'Plan to Watch';
          buttonColor = Color(0xFFF59E0B);
          break;
        case WatchStatus.watching:
          buttonLabel = 'Watching';
          buttonColor = Color(0xFF22C55E);
          break;
        case WatchStatus.completed:
          buttonLabel = 'Completed';
          buttonColor = Color(0xFF3B82F6);
          break;
        case WatchStatus.onHold:
          buttonLabel = 'On Hold';
          buttonColor = Color(0xFF94A3B8);
          break;
        case WatchStatus.dropped:
          buttonLabel = 'Dropped';
          buttonColor = Color(0xFFEF4444);
          break;
      }
    }

    final options = [
      {
        'status': WatchStatus.planToWatch,
        'label': 'Plan to Watch',
        'color': Color(0xFFF59E0B),
      },
      {
        'status': WatchStatus.watching,
        'label': 'Watching',
        'color': Color(0xFF22C55E),
      },
      {
        'status': WatchStatus.completed,
        'label': 'Completed',
        'color': Color(0xFF3B82F6),
      },
      {
        'status': WatchStatus.onHold,
        'label': 'On Hold',
        'color': Color(0xFF94A3B8),
      },
      {
        'status': WatchStatus.dropped,
        'label': 'Dropped',
        'color': Color(0xFFEF4444),
      },
    ];

    return PopupMenuButton<String>(
      onSelected: (value) async {
        HapticFeedback.selectionClick();
        if (value == 'remove') {
          for (var item in franchiseItems) {
            await watchlistNotifier.remove(item.externalId, item.mediaType);
          }
        } else if (value == 'mark_all_ptw' || value == 'mark_all_completed') {
          final targetStatus = value == 'mark_all_ptw' ? WatchStatus.planToWatch : WatchStatus.completed;
          List<Media> franchiseMedia = [];
          
          if (media.type == MediaType.anime) {
            final anilist = ref.read(anilistServiceProvider);
            final seasons = await anilist.getAnimeSeasons(media.externalId);
            
            if (seasons.isNotEmpty) {
              final rootItem = seasons.where((s) => s.format == 'TV').firstOrNull ?? seasons.first;
              for (final season in seasons) {
                franchiseMedia.add(Media(
                  id: season.mediaId ?? '',
                  externalId: season.mediaId?.replaceAll('anilist-', '') ?? '',
                  type: MediaType.anime,
                  title: season.name,
                  overview: season.overview,
                  posterUrl: season.posterUrl ?? media.posterUrl,
                  genres: media.genres,
                  rating: media.rating,
                  voteCount: 0,
                  status: 'released',
                  totalEpisodes: null,
                  franchiseId: rootItem.mediaId?.toString() ?? media.id,
                  franchiseTitle: rootItem.name,
                  franchisePosterUrl: rootItem.posterUrl ?? media.posterUrl,
                  releaseDate: season.airDate,
                ));
              }
            }
          } else if (media.type == MediaType.movie) {
            final tmdb = ref.read(tmdbServiceProvider);
            Media? mediaWithFranchise = media;
            if (mediaWithFranchise.franchiseId == null) {
              mediaWithFranchise = await tmdb.getMovieDetails(media.externalId) ?? media;
            }
            if (mediaWithFranchise.franchiseId != null) {
              franchiseMedia = await tmdb.getCollection(mediaWithFranchise.franchiseId!);
            }
          } else if (media.type == MediaType.series) {
            final tmdb = ref.read(tmdbServiceProvider);
            final details = await tmdb.getTVDetails(media.id);
            if (details != null && details.seasons != null) {
              for (var s in details.seasons!) {
                final cleanId = (s.mediaId ?? '${media.externalId}-season-${s.number}').replaceAll('tmdb-tv-', '');
                franchiseMedia.add(Media(
                  id: 'tmdb-tv-$cleanId',
                  externalId: cleanId,
                  type: MediaType.series,
                  title: s.name,
                  overview: s.overview,
                  posterUrl: s.posterUrl ?? media.posterUrl,
                  genres: media.genres,
                  rating: 0,
                  voteCount: 0,
                  status: 'Unknown',
                  franchiseId: media.franchiseId ?? media.id,
                ));
              }
            }
            // Add the main show to the list as well
            franchiseMedia.add(media);
          }

          if (franchiseMedia.isNotEmpty) {
            await watchlistNotifier.bulkUpdateFranchise(franchiseMedia, targetStatus);
          } else {
            await watchlistNotifier.addMediaToWatchlist(media, targetStatus);
          }
        } else {
          final newStatus = WatchStatus.values.firstWhere(
            (s) => s.name == value,
          );
          if (existingItem != null) {
            await watchlistNotifier.updateStatus(existingItem, newStatus);
          } else {
            await watchlistNotifier.addMediaToWatchlist(media, newStatus);
          }
        }
      },
      color: context.colors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.divider.withValues(alpha: 0.5)),
      ),
      offset: Offset(0, 50),
      child: Container(
        height: isCompact ? 32 : 48,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: isAdded
              ? buttonColor.withValues(alpha: 0.15)
              : (isCompact ? Colors.black.withValues(alpha: 0.6) : buttonColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAdded
                ? buttonColor.withValues(alpha: 0.5)
                : (isCompact
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.transparent),
            width: isAdded ? 1.5 : 1.0,
          ),
          boxShadow: (!isAdded && !isCompact)
              ? [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAdded ? Icons.check_circle_outline_rounded : Icons.add_circle_outline_rounded,
              color: isAdded ? buttonColor : Colors.white,
              size: isCompact ? 16 : 22,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                buttonLabel,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isAdded ? buttonColor : Colors.white,
                  fontSize: isCompact ? 11 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (!isCompact) ...[
              SizedBox(width: 8),
              Container(
                width: 1,
                height: 24,
                color: (isAdded ? buttonColor : Colors.white).withValues(alpha: 0.3),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isAdded ? buttonColor : Colors.white,
                size: 22,
              ),
            ],
          ],
        ),
      ),
      itemBuilder: (context) {
        final menuItems = <PopupMenuEntry<String>>[];

        for (var opt in options) {
          final status = opt['status'] as WatchStatus;
          final label = opt['label'] as String;
          final color = opt['color'] as Color;
          menuItems.add(
            PopupMenuItem<String>(
              value: status.name,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: existingItem?.status == status
                            ? Colors.white
                            : context.colors.textSubtle,
                        fontWeight: existingItem?.status == status
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final showFranchiseOptions = media.franchiseId != null || media.type == MediaType.anime || media.type == MediaType.movie;

        if (showFranchiseOptions) {
          menuItems.add(PopupMenuDivider());
          menuItems.add(
            PopupMenuItem<String>(
              enabled: false,
              height: 24,
              child: Text(
                'ENTIRE FRANCHISE',
                style: TextStyle(
                  color: context.colors.textSubtle,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          );
          
          menuItems.add(
            PopupMenuItem<String>(
              value: 'mark_all_ptw',
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mark all Plan to Watch',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.colors.textSubtle),
                    ),
                  ),
                ],
              ),
            ),
          );

          menuItems.add(
            PopupMenuItem<String>(
              value: 'mark_all_completed',
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mark all Completed',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.colors.textSubtle),
                    ),
                  ),
                ],
              ),
            ),
          );
        }


        if (isAdded) {
          menuItems.add(PopupMenuDivider());
          menuItems.add(
            PopupMenuItem<String>(
              value: 'remove',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    color: context.colors.textSubtle,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Remove from List',
                    style: TextStyle(color: context.colors.textSubtle),
                  ),
                ],
              ),
            ),
          );
        }

        return menuItems;
      },
    );
  }
}
