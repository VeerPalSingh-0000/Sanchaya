import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import '../providers/watchlist_provider.dart';
import 'episode_tracker_widget.dart';
import 'reaction_selector.dart';

class WatchlistBottomSheet extends ConsumerStatefulWidget {
  final Media media;
  final List<Season>? franchiseTimeline;

  const WatchlistBottomSheet({super.key, required this.media, this.franchiseTimeline});

  @override
  ConsumerState<WatchlistBottomSheet> createState() =>
      _WatchlistBottomSheetState();
}

class _WatchlistBottomSheetState extends ConsumerState<WatchlistBottomSheet> {

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'value': WatchStatus.planToWatch,
      'label': 'Plan to Watch',
      'icon': Icons.calendar_today_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'value': WatchStatus.watching,
      'label': 'Watching',
      'icon': Icons.play_circle_fill_rounded,
      'color': Color(0xFF22C55E),
    },
    {
      'value': WatchStatus.completed,
      'label': 'Completed',
      'icon': Icons.check_circle_rounded,
      'color': Color(0xFF3B82F6),
    },
    {
      'value': WatchStatus.onHold,
      'label': 'On Hold',
      'icon': Icons.pause_circle_filled_rounded,
      'color': Color(0xFF94A3B8),
    },
    {
      'value': WatchStatus.dropped,
      'label': 'Dropped',
      'icon': Icons.cancel_rounded,
      'color': Color(0xFFEF4444),
    },
  ];

  Future<void> _handleStatusSelect(WatchStatus status) async {
    final watchlistNotifier = ref.read(watchlistProvider.notifier);
    await watchlistNotifier.updateStatusWithPropagation(
      widget.media,
      status,
      widget.franchiseTimeline,
    );

    if (mounted) Navigator.pop(context);
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
    ref.watch(watchlistProvider);
    final watchlistNotifier = ref.read(watchlistProvider.notifier);
    final franchiseItems = watchlistNotifier.getFranchiseItems(widget.media);
    final isAdded = franchiseItems.isNotEmpty;
    final currentStatus = watchlistNotifier.getAggregateStatus(widget.media);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
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
            SizedBox(height: 24),

            ..._statusOptions.map((option) {
              final status = option['value'] as WatchStatus;
              final isActive = isAdded && currentStatus == status;
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isActive
                      ? (option['color'] as Color).withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _handleStatusSelect(status),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            option['icon'] as IconData,
                            color: option['color'] as Color,
                            size: 20,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option['label'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isActive
                                    ? option['color'] as Color
                                    : context.colors.textMain,
                                fontSize: 15,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),


            if (isAdded) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Colors.white12),
              ),
              if (watchlistNotifier.getItem(
                    widget.media.id,
                    widget.media.type,
                  ) !=
                  null) ...[
                if (watchlistNotifier
                        .getItem(widget.media.id, widget.media.type)!
                        .status ==
                    WatchStatus.watching) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: EpisodeTrackerWidget(
                        item: watchlistNotifier.getItem(
                          widget.media.id,
                          widget.media.type,
                        )!,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: ReactionSelectorWidget(
                      item: watchlistNotifier.getItem(
                        widget.media.id,
                        widget.media.type,
                      )!,
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _handleRemove,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: context.colors.error,
                          size: 20,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Remove from List',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.colors.error,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
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


}
