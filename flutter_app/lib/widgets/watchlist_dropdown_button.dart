import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import '../providers/watchlist_provider.dart';

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
    final isAdded = franchiseItems.isNotEmpty;
    final aggregateStatus = watchlistNotifier.getAggregateStatus(media);

    String buttonLabel = 'Add to Watchlist';
    Color buttonColor = context.colors.primary;
    if (isAdded) {
      switch (aggregateStatus) {
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
        if (value == 'remove') {
          for (var item in franchiseItems) {
            await watchlistNotifier.remove(item.externalId, item.mediaType);
          }
        } else {
          final newStatus = WatchStatus.values.firstWhere(
            (s) => s.name == value,
          );
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
      color: context.colors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.divider.withValues(alpha: 0.5)),
      ),
      offset: Offset(0, 50),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isCompact ? 8 : 14,
          horizontal: isCompact ? 12 : 20,
        ),
        decoration: BoxDecoration(
          color: isAdded
              ? buttonColor.withValues(alpha: 0.1)
              : (isCompact ? Colors.black.withValues(alpha: 0.6) : buttonColor),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isAdded
                ? buttonColor.withValues(alpha: 0.5)
                : (isCompact
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.transparent),
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
            SizedBox(width: 6),
            Expanded(
              child: Text(
                buttonLabel,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isAdded ? buttonColor : Colors.white,
                  fontSize: isCompact ? 10 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!isCompact) ...[
              SizedBox(width: 8),
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
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: aggregateStatus == status && isAdded
                            ? Colors.white
                            : context.colors.textSubtle,
                        fontWeight: aggregateStatus == status && isAdded
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
