import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/media.dart';
import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';
import '../providers/service_providers.dart';

class WatchlistBottomSheet extends ConsumerStatefulWidget {
  final Media media;

  const WatchlistBottomSheet({super.key, required this.media});

  @override
  ConsumerState<WatchlistBottomSheet> createState() => _WatchlistBottomSheetState();
}

class _WatchlistBottomSheetState extends ConsumerState<WatchlistBottomSheet> {
  bool _isBulkUpdating = false;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': WatchStatus.planToWatch, 'label': 'Plan to Watch', 'icon': Icons.calendar_today_rounded, 'color': const Color(0xFFF59E0B)},
    {'value': WatchStatus.watching, 'label': 'Watching', 'icon': Icons.play_circle_fill_rounded, 'color': const Color(0xFF22C55E)},
    {'value': WatchStatus.completed, 'label': 'Completed', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF3B82F6)},
    {'value': WatchStatus.onHold, 'label': 'On Hold', 'icon': Icons.pause_circle_filled_rounded, 'color': const Color(0xFF94A3B8)},
    {'value': WatchStatus.dropped, 'label': 'Dropped', 'icon': Icons.cancel_rounded, 'color': const Color(0xFFEF4444)},
  ];

  Future<void> _handleStatusSelect(WatchStatus status) async {
    final watchlistNotifier = ref.read(watchlistProvider.notifier);
    final franchiseItems = watchlistNotifier.getFranchiseItems(widget.media);
    final existingItem = watchlistNotifier.getItem(widget.media.externalId, widget.media.type);

    if (franchiseItems.isNotEmpty) {
      for (final item in franchiseItems) {
        await watchlistNotifier.updateStatus(item, status);
      }
      if (existingItem == null) {
        await _addSingleItem(status);
      }
    } else {
      await _addSingleItem(status);
    }
    
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addSingleItem(WatchStatus status) async {
    final watchlistNotifier = ref.read(watchlistProvider.notifier);
    await watchlistNotifier.addMediaToWatchlist(widget.media, status);
  }

  Future<void> _handleBulkFranchise(WatchStatus status) async {
    setState(() => _isBulkUpdating = true);
    try {
      final watchlistNotifier = ref.read(watchlistProvider.notifier);
      List<Media> franchiseMedia = [];

      if (widget.media.type == MediaType.anime) {
        final anilist = ref.read(anilistServiceProvider);
        final seasons = await anilist.getAnimeSeasons(widget.media.externalId);
        if (seasons.isNotEmpty) {
          final rootItem = seasons.where((s) => s.format == 'TV').firstOrNull ?? seasons.first;
          for (final s in seasons) {
            franchiseMedia.add(Media(
              id: 'anilist-${s.mediaId}',
              externalId: s.mediaId.toString(),
              type: MediaType.anime,
              title: s.name,
              overview: '',
              posterUrl: s.posterUrl ?? widget.media.posterUrl,
              backdropUrl: widget.media.backdropUrl,
              genres: widget.media.genres,
              rating: widget.media.rating,
              voteCount: 0,
              status: 'released',
              totalEpisodes: null,
              franchiseId: rootItem.mediaId?.toString() ?? widget.media.id,
              franchiseTitle: rootItem.name,
              franchisePosterUrl: rootItem.posterUrl ?? widget.media.posterUrl,
            ));
          }
        }
      } else if (widget.media.type == MediaType.movie) {
        final tmdb = ref.read(tmdbServiceProvider);
        Media? mediaWithFranchise = widget.media;
        if (mediaWithFranchise.franchiseId == null) {
          mediaWithFranchise = await tmdb.getMovieDetails(widget.media.externalId) ?? widget.media;
        }
        if (mediaWithFranchise.franchiseId != null) {
          franchiseMedia = await tmdb.getCollection(mediaWithFranchise.franchiseId!);
        }
      }

      if (franchiseMedia.isNotEmpty) {
        await watchlistNotifier.bulkUpdateFranchise(franchiseMedia, status);
      } else {
        await _handleStatusSelect(status);
      }
    } catch (e) {
      debugPrint('Error bulk adding franchise: $e');
    } finally {
      if (mounted) {
        setState(() => _isBulkUpdating = false);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleRemove() async {
    final watchlistNotifier = ref.read(watchlistProvider.notifier);
    final franchiseItems = watchlistNotifier.getFranchiseItems(widget.media);
    if (franchiseItems.isNotEmpty) {
      await watchlistNotifier.bulkRemoveFranchise(franchiseItems);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final watchlistNotifier = ref.watch(watchlistProvider.notifier);
    final franchiseItems = watchlistNotifier.getFranchiseItems(widget.media);
    final isAdded = franchiseItems.isNotEmpty;
    final currentStatus = watchlistNotifier.getAggregateStatus(widget.media);

    final showFranchiseOptions = widget.media.franchiseId != null || widget.media.type == MediaType.anime;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            ..._statusOptions.map((option) {
              final status = option['value'] as WatchStatus;
              final isActive = isAdded && currentStatus == status;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isActive ? (option['color'] as Color).withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _handleStatusSelect(status),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            option['icon'] as IconData,
                            color: option['color'] as Color,
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            option['label'] as String,
                            style: TextStyle(
                              color: isActive ? option['color'] as Color : AppTheme.textMain,
                              fontSize: 15,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            if (showFranchiseOptions) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Colors.white12),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'ENTIRE FRANCHISE',
                  style: TextStyle(
                    color: AppTheme.textSubtle,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _buildBulkOption('Mark all Plan to Watch', WatchStatus.planToWatch, const Color(0xFFF59E0B)),
              _buildBulkOption('Mark all Completed', WatchStatus.completed, const Color(0xFF3B82F6)),
            ],

            if (isAdded) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Colors.white12),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _handleRemove,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                        SizedBox(width: 16),
                        Text(
                          'Remove from List',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBulkOption(String label, WatchStatus status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isBulkUpdating ? null : () => _handleBulkFranchise(status),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _isBulkUpdating ? color.withValues(alpha: 0.5) : color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _isBulkUpdating ? 'Updating...' : label,
                  style: TextStyle(
                    color: _isBulkUpdating ? AppTheme.textMuted : AppTheme.textMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
