import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/watchlist_item.dart';
import '../models/media.dart';
import '../providers/watchlist_provider.dart';

class EpisodeTrackerWidget extends ConsumerWidget {
  final WatchlistItem item;
  final bool compact;

  const EpisodeTrackerWidget({
    super.key,
    required this.item,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.status != WatchStatus.watching) return const SizedBox.shrink();

    final progress = item.progress ?? 0;
    final total = item.totalEpisodes;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12, vertical: compact ? 4 : 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: Icons.remove,
            onTap: progress > 0 ? () {
              ref.read(watchlistProvider.notifier).updateProgress(item, progress - 1);
            } : null,
          ),
          SizedBox(width: compact ? 8 : 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$progress',
                style: TextStyle(
                  color: AppTheme.textMain,
                  fontSize: compact ? 14 : 18,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              if (total != null)
                Text(
                  'of \$total',
                  style: TextStyle(
                    color: AppTheme.textSubtle,
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          SizedBox(width: compact ? 8 : 16),
          _buildButton(
            icon: Icons.add,
            onTap: (total == null || progress < total) ? () {
              final newProgress = progress + 1;
              ref.read(watchlistProvider.notifier).updateProgress(item, newProgress);
              
              if (total != null && newProgress == total) {
                // Auto-complete!
                ref.read(watchlistProvider.notifier).updateStatus(item, WatchStatus.completed);
              }
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({required IconData icon, required VoidCallback? onTap}) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(compact ? 4.0 : 8.0),
          child: Icon(
            icon,
            size: compact ? 16 : 20,
            color: enabled ? AppTheme.primary : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
