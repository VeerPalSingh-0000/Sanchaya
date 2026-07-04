import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';

class ReactionSelectorWidget extends ConsumerStatefulWidget {
  final WatchlistItem item;

  const ReactionSelectorWidget({super.key, required this.item});

  @override
  ConsumerState<ReactionSelectorWidget> createState() => _ReactionSelectorWidgetState();
}

class _ReactionSelectorWidgetState extends ConsumerState<ReactionSelectorWidget> {
  final List<Map<String, dynamic>> _reactions = [
    {'id': Reaction.love, 'label': 'Love it', 'icon': Icons.favorite_rounded, 'color': const Color(0xFFF43F5E)},
    {'id': Reaction.good, 'label': "It's good", 'icon': Icons.thumb_up_rounded, 'color': const Color(0xFF10B981)},
    {'id': Reaction.bad, 'label': "It's bad", 'icon': Icons.thumb_down_rounded, 'color': const Color(0xFF64748B)},
  ];

  Future<void> _handleReactionSelect(Reaction? reactionId) async {
    final watchlistNotifier = ref.read(watchlistProvider.notifier);
    
    // Toggle off if clicking the same one
    final newReaction = widget.item.reaction == reactionId ? null : reactionId;

    // We should ideally update all items in the franchise if it has one
    final allItems = watchlistNotifier.state.value ?? [];
    final franchiseItems = widget.item.franchiseId != null 
        ? allItems.where((i) => i.franchiseId == widget.item.franchiseId).toList()
        : [widget.item];
        
    for (final i in franchiseItems) {
      await watchlistNotifier.updateReaction(i, newReaction);
    }
  }

  void _showReactionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.only(bottom: 24, top: 12),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              ..._reactions.map((r) {
                final rId = r['id'] as Reaction;
                final isActive = widget.item.reaction == rId;
                final color = r['color'] as Color;
                
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _handleReactionSelect(rId);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Icon(r['icon'] as IconData, color: isActive ? color : AppTheme.textSubtle, size: 24),
                        const SizedBox(width: 16),
                        Text(
                          r['label'] as String,
                          style: TextStyle(
                            color: isActive ? color : AppTheme.textMain,
                            fontSize: 16,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeReaction = _reactions.where((r) => r['id'] == widget.item.reaction).firstOrNull;

    return Material(
      color: activeReaction != null 
          ? (activeReaction['color'] as Color).withValues(alpha: 0.2)
          : AppTheme.surfaceLight.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _showReactionMenu(context),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: activeReaction != null 
                  ? (activeReaction['color'] as Color).withValues(alpha: 0.5) 
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                activeReaction != null ? activeReaction['icon'] as IconData : Icons.star_border_rounded,
                color: activeReaction != null ? activeReaction['color'] as Color : AppTheme.textMain,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                activeReaction != null ? activeReaction['label'] as String : 'Rate',
                style: TextStyle(
                  color: activeReaction != null ? activeReaction['color'] as Color : AppTheme.textMain,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: activeReaction != null ? activeReaction['color'] as Color : AppTheme.textSubtle,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
