import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/media.dart';
import '../providers/watchlist_provider.dart';

class WatchlistDropdownButton extends ConsumerWidget {
  final Media media;
  final bool isCompact;

  const WatchlistDropdownButton({super.key, required this.media, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistNotifier = ref.watch(watchlistProvider.notifier);
    final existingItem = watchlistNotifier.getItem(media.externalId, media.type);
    final franchiseItems = watchlistNotifier.getFranchiseItems(media);
    final isAdded = franchiseItems.isNotEmpty;
    final aggregateStatus = watchlistNotifier.getAggregateStatus(media);

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

    final options = [
      {'status': WatchStatus.planToWatch, 'label': 'Plan to Watch', 'color': const Color(0xFFF59E0B)},
      {'status': WatchStatus.watching, 'label': 'Watching', 'color': const Color(0xFF22C55E)},
      {'status': WatchStatus.completed, 'label': 'Completed', 'color': const Color(0xFF3B82F6)},
      {'status': WatchStatus.onHold, 'label': 'On Hold', 'color': const Color(0xFF94A3B8)},
      {'status': WatchStatus.dropped, 'label': 'Dropped', 'color': const Color(0xFFEF4444)},
    ];

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'remove') {
          for (var item in franchiseItems) {
            await watchlistNotifier.remove(item.externalId, item.mediaType);
          }
        } else if (value == 'franchise_plan') {
          if (existingItem != null) {
            await watchlistNotifier.updateStatus(existingItem, WatchStatus.planToWatch);
          } else {
            await watchlistNotifier.addMediaToWatchlist(media, WatchStatus.planToWatch);
          }
        } else if (value == 'franchise_completed') {
          if (existingItem != null) {
            await watchlistNotifier.updateStatus(existingItem, WatchStatus.completed);
          } else {
            await watchlistNotifier.addMediaToWatchlist(media, WatchStatus.completed);
          }
        } else {
          final newStatus = WatchStatus.values.firstWhere((s) => s.name == value);
          if (franchiseItems.isNotEmpty) {
            for (var item in franchiseItems) {
              await watchlistNotifier.updateStatus(item, newStatus);
            }
            if (existingItem == null) {
              await watchlistNotifier.addMediaToWatchlist(media, newStatus);
            }
          } else {
            await watchlistNotifier.addMediaToWatchlist(media, newStatus);
          }
        }
      },
      color: AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      offset: const Offset(0, 50),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isCompact ? 8 : 14, 
          horizontal: isCompact ? 12 : 20
        ),
        decoration: BoxDecoration(
          color: isAdded ? buttonColor.withValues(alpha: 0.1) : (isCompact ? Colors.black.withValues(alpha: 0.6) : buttonColor),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isAdded ? buttonColor.withValues(alpha: 0.5) : (isCompact ? Colors.white.withValues(alpha: 0.2) : Colors.transparent),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAdded ? Icons.check_rounded : Icons.add_rounded,
              color: isAdded ? buttonColor : Colors.white,
              size: isCompact ? 14 : 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                buttonLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isAdded ? buttonColor : Colors.white,
                  fontSize: isCompact ? 10 : 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isAdded ? buttonColor : Colors.white,
                size: 20,
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
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: aggregateStatus == status && isAdded ? Colors.white : AppTheme.textSubtle,
                      fontWeight: aggregateStatus == status && isAdded ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (media.franchiseId != null || media.type == MediaType.anime) {
          menuItems.add(const PopupMenuDivider());
          menuItems.add(
            const PopupMenuItem<String>(
              enabled: false,
              child: Text(
                'ENTIRE FRANCHISE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          );
          menuItems.add(
            PopupMenuItem<String>(
              value: 'franchise_plan',
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Mark all Plan to Watch', style: TextStyle(color: AppTheme.textMain)),
                ],
              ),
            ),
          );
          menuItems.add(
            PopupMenuItem<String>(
              value: 'franchise_completed',
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Mark all Completed', style: TextStyle(color: AppTheme.textMain)),
                ],
              ),
            ),
          );
        }

        if (isAdded) {
          menuItems.add(const PopupMenuDivider());
          menuItems.add(
            const PopupMenuItem<String>(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, color: AppTheme.textSubtle, size: 20),
                  SizedBox(width: 12),
                  Text('Remove from List', style: TextStyle(color: AppTheme.textSubtle)),
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
