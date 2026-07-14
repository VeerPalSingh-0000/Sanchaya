import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
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
    if (item.status != WatchStatus.watching) return SizedBox.shrink();

    final progress = item.progress ?? 0;
    final total = item.totalEpisodes;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12, vertical: compact ? 4 : 8),
      decoration: BoxDecoration(
        color: context.colors.surfaceLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(context, icon: Icons.remove,
            onTap: progress > 0 ? () {
              ref.read(watchlistProvider.notifier).updateProgress(item, progress - 1);
            } : null,
          ),
          SizedBox(width: compact ? 8 : 16),
          GestureDetector(
            onTap: () => _showEditDialog(context, ref, progress, total),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$progress',
                  style: TextStyle(
                    color: context.colors.textMain,
                    fontSize: compact ? 14 : 18,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                if (total != null)
                  Text(
                    'of $total',
                    style: TextStyle(
                      color: context.colors.textSubtle,
                      fontSize: compact ? 10 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: compact ? 8 : 16),
          _buildButton(context, icon: Icons.add,
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

  Widget _buildButton(BuildContext context, {required IconData icon, required VoidCallback? onTap}) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? context.colors.primary.withValues(alpha: 0.2) : Colors.transparent,
      shape: CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(compact ? 4.0 : 8.0),
          child: Icon(
            icon,
            size: compact ? 16 : 20,
            color: enabled ? context.colors.primary : context.colors.textMuted,
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, int current, int? total) async {
    final controller = TextEditingController(text: current.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surfaceLight,
        title: Text('Update Progress', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: total != null ? 'Episode (Max: $total)' : 'Episode',
            labelStyle: TextStyle(color: context.colors.textSubtle),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.colors.textMuted)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.colors.primary)),
          ),
          autofocus: true,
          onSubmitted: (val) {
            final valInt = int.tryParse(val);
            if (valInt != null) Navigator.pop(context, valInt);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSubtle)),
          ),
          TextButton(
            onPressed: () {
              final valInt = int.tryParse(controller.text);
              if (valInt != null) Navigator.pop(context, valInt);
            },
            child: Text('Save', style: TextStyle(color: context.colors.primary)),
          ),
        ],
      ),
    );

    if (result != null && result >= 0) {
      int newProgress = result;
      if (total != null && newProgress > total) {
        newProgress = total;
      }
      ref.read(watchlistProvider.notifier).updateProgress(item, newProgress);
      if (total != null && newProgress == total) {
        ref.read(watchlistProvider.notifier).updateStatus(item, WatchStatus.completed);
      }
    }
  }
}
