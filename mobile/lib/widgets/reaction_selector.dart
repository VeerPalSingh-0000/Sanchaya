import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    {
      'id': Reaction.favorite,
      'label': 'Favourite',
      'icon': Icons.star_rounded,
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': Reaction.love,
      'label': 'Love it',
      'icon': Icons.favorite_rounded,
      'color': const Color(0xFFF43F5E),
    },
    {
      'id': Reaction.good,
      'label': "It's good",
      'icon': Icons.thumb_up_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'id': Reaction.bad,
      'label': "It's bad",
      'icon': Icons.thumb_down_rounded,
      'color': const Color(0xFF64748B),
    },
  ];

  Future<void> _handleReactionSelect(Reaction? reactionId) async {
    HapticFeedback.selectionClick();
    final watchlistNotifier = ref.read(watchlistProvider.notifier);

    // Toggle off if clicking the same one
    final newReaction = widget.item.reaction == reactionId ? null : reactionId;

    // Update all items in the franchise if it has one
    final allItems = ref.read(watchlistProvider).value ?? [];
    final franchiseItems = widget.item.franchiseId != null
        ? allItems.where((i) => i.franchiseId == widget.item.franchiseId).toList()
        : [widget.item];

    for (final i in franchiseItems) {
      await watchlistNotifier.updateReaction(i, newReaction);
    }
  }

  void _showReactionMenu(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.only(bottom: 28, top: 12),
        decoration: BoxDecoration(
          color: context.colors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'Rate & React',
                      style: TextStyle(
                        color: context.colors.textMain,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: context.colors.textSubtle,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ..._reactions.map((r) {
                final rId = r['id'] as Reaction;
                final isActive = widget.item.reaction == rId;
                final color = r['color'] as Color;

                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleReactionSelect(rId);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? color.withValues(alpha: 0.4) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            r['icon'] as IconData,
                            color: isActive ? color : context.colors.textSubtle,
                            size: 24,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            r['label'] as String,
                            style: TextStyle(
                              color: isActive ? color : context.colors.textMain,
                              fontSize: 15,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (isActive)
                            Icon(
                              Icons.check_circle_rounded,
                              color: color,
                              size: 20,
                            ),
                        ],
                      ),
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
    final isWide = MediaQuery.of(context).size.width > 480;

    return Material(
      color: activeReaction != null
          ? (activeReaction['color'] as Color).withValues(alpha: 0.18)
          : context.colors.surfaceLight.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _showReactionMenu(context),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          padding: EdgeInsets.symmetric(
            horizontal: (activeReaction != null && isWide) ? 14 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: activeReaction != null
                  ? (activeReaction['color'] as Color).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.12),
              width: activeReaction != null ? 1.5 : 1.0,
            ),
            boxShadow: activeReaction != null
                ? [
                    BoxShadow(
                      color: (activeReaction['color'] as Color).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                activeReaction != null
                    ? (activeReaction['icon'] as IconData)
                    : Icons.star_border_rounded,
                color: activeReaction != null
                    ? (activeReaction['color'] as Color)
                    : context.colors.textMain,
                size: 22,
              ),
              if (activeReaction != null && isWide) ...[
                const SizedBox(width: 6),
                Text(
                  activeReaction['label'] as String,
                  style: TextStyle(
                    color: activeReaction['color'] as Color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
