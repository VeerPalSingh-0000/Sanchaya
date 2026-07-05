import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/watchlist_item.dart';
import '../models/media.dart';
import '../providers/watchlist_provider.dart';
import '../providers/watchlist_groups_provider.dart';

import '../widgets/profile_app_bar.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> with SingleTickerProviderStateMixin {
  static const _tabs = [
    WatchStatus.watching,
    WatchStatus.planToWatch,
    WatchStatus.completed,
    WatchStatus.onHold,
    WatchStatus.dropped,
  ];

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watchlistAsync = ref.watch(watchlistGroupsProvider);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title & Tabs ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: const Text(
                'Watchlist',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: AppTheme.textMain,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search watchlist...',
                  hintStyle: const TextStyle(color: AppTheme.textSubtle, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSubtle, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textSubtle, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.divider.withValues(alpha: 0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.divider.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                  ),
                ),
                style: const TextStyle(color: AppTheme.textMain, fontSize: 14),
              ),
            ).animate().fadeIn(duration: 400.ms),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.divider.withValues(alpha: 0.5),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSubtle,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: _tabs.map((status) {
                  return Tab(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(status), size: 14),
                          const SizedBox(width: 6),
                          Text(_statusLabel(status)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 50.ms),

            const SizedBox(height: 8),

            // ── Tab content ──
            Expanded(
              child: watchlistAsync.when(
                data: (items) {
                  return TabBarView(
                    controller: _tabController,
                    children: _tabs.map((status) {
                      final filtered = items.where((i) {
                        if (i.aggregateStatus != status) return false;
                        if (_searchQuery.isEmpty) return true;
                        
                        if (i is SingleDisplayItem) {
                          return i.item.title.toLowerCase().contains(_searchQuery);
                        } else if (i is FranchiseDisplayItem) {
                          return i.group.rootTitle.toLowerCase().contains(_searchQuery) ||
                                 i.items.any((child) => child.title.toLowerCase().contains(_searchQuery));
                        }
                        return false;
                      }).toList();

                      if (filtered.isEmpty) {
                        return _EmptyTab(status: status);
                      }
                      return _WatchlistItemList(items: filtered);
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.error, size: 36),
                      const SizedBox(height: 12),
                      const Text(
                        'Failed to load watchlist',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        e.toString(),
                        style: const TextStyle(
                            color: AppTheme.textSubtle, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(WatchStatus status) {
    switch (status) {
      case WatchStatus.watching:
        return 'Watching';
      case WatchStatus.planToWatch:
        return 'Plan to Watch';
      case WatchStatus.completed:
        return 'Completed';
      case WatchStatus.onHold:
        return 'On Hold';
      case WatchStatus.dropped:
        return 'Dropped';
    }
  }

  IconData _statusIcon(WatchStatus status) {
    switch (status) {
      case WatchStatus.watching:
        return Icons.play_circle_outline_rounded;
      case WatchStatus.planToWatch:
        return Icons.access_time_rounded;
      case WatchStatus.completed:
        return Icons.check_circle_outline_rounded;
      case WatchStatus.onHold:
        return Icons.pause_circle_outline_rounded;
      case WatchStatus.dropped:
        return Icons.cancel_outlined;
    }
  }
}

// ────────────────────────────────────────────────────────────
// Empty state per tab
// ────────────────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  final WatchStatus status;
  const _EmptyTab({required this.status});

  @override
  Widget build(BuildContext context) {
    final messages = {
      WatchStatus.watching: ('Nothing playing', 'Start watching something!'),
      WatchStatus.planToWatch: ('Your queue is empty', 'Add titles to watch later'),
      WatchStatus.completed: ('No completions yet', 'Finish watching something!'),
      WatchStatus.onHold: ('Nothing on hold', 'Paused shows will appear here'),
      WatchStatus.dropped: ('Nothing dropped', 'Dropped titles appear here'),
    };

    final (title, subtitle) = messages[status]!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border_rounded,
              color: AppTheme.textSubtle,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSubtle, fontSize: 13),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ────────────────────────────────────────────────────────────
// Watchlist item list
// ────────────────────────────────────────────────────────────

class _WatchlistItemList extends StatelessWidget {
  final List<DisplayItem> items;
  const _WatchlistItemList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final displayItem = items[index];
        final Widget child;
        if (displayItem is SingleDisplayItem) {
          child = _WatchlistTile(item: displayItem.item);
        } else if (displayItem is FranchiseDisplayItem) {
          child = _FranchiseTile(displayItem: displayItem);
        } else {
          child = const SizedBox.shrink();
        }

        return child
            .animate()
            .fadeIn(
              duration: 300.ms,
              delay: Duration(milliseconds: (40 * index).clamp(0, 300)),
            )
            .slideY(
              begin: 0.05,
              duration: 300.ms,
              delay: Duration(milliseconds: (40 * index).clamp(0, 300)),
              curve: Curves.easeOut,
            );
      },
    );
  }
}

class _WatchlistTile extends StatelessWidget {
  final WatchlistItem item;
  const _WatchlistTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasProgress = item.progress != null && item.totalEpisodes != null && item.totalEpisodes! > 0;
    final progressFraction = hasProgress ? (item.progress! / item.totalEpisodes!) : 0.0;

    return GestureDetector(
      onTap: () {
        String mediaRouteId = item.externalId;
        // Backwards compatibility for incorrectly saved IDs that miss the prefix
        if (!mediaRouteId.startsWith('tmdb-') && !mediaRouteId.startsWith('anilist-')) {
          switch (item.mediaType) {
            case MediaType.movie:
              mediaRouteId = 'tmdb-movie-${item.externalId}';
              break;
            case MediaType.series:
              mediaRouteId = 'tmdb-tv-${item.externalId}';
              break;
            case MediaType.anime:
              mediaRouteId = 'anilist-${item.externalId}';
              break;
          }
        }
        context.push('/media/$mediaRouteId');
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.divider.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 60,
                height: 85,
                child: item.posterUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppTheme.surfaceLight),
                        errorWidget: (_, __, ___) =>
                            Container(color: AppTheme.surfaceLight),
                      )
                    : Container(
                        color: AppTheme.surfaceLight,
                        child: const Icon(Icons.movie_outlined,
                            color: AppTheme.textSubtle, size: 24),
                      ),
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Type + rating row
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _typeLabel(item.mediaType),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (item.rating > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFBBF24), size: 13),
                            const SizedBox(width: 3),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      // Reaction emoji
                      if (item.reaction != null)
                        Text(
                          _reactionEmoji(item.reaction!),
                          style: const TextStyle(fontSize: 16),
                        ),
                    ],
                  ),

                  // Progress bar
                  if (hasProgress) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressFraction.clamp(0.0, 1.0),
                              backgroundColor: AppTheme.surfaceLight,
                              valueColor:
                                  const AlwaysStoppedAnimation(AppTheme.primary),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${item.progress}/${item.totalEpisodes}',
                          style: const TextStyle(
                            color: AppTheme.textSubtle,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  String _typeLabel(MediaType type) {
    switch (type) {
      case MediaType.movie:
        return 'MOVIE';
      case MediaType.series:
        return 'TV';
      case MediaType.anime:
        return 'ANIME';
    }
  }

  String _reactionEmoji(Reaction reaction) {
    switch (reaction) {
      case Reaction.love:
        return '❤️';
      case Reaction.good:
        return '👍';
      case Reaction.bad:
        return '👎';
    }
  }
}

// ────────────────────────────────────────────────────────────
// Franchise group tile
// ────────────────────────────────────────────────────────────

class _FranchiseTile extends StatelessWidget {
  final FranchiseDisplayItem displayItem;
  const _FranchiseTile({required this.displayItem});

  @override
  Widget build(BuildContext context) {
    final group = displayItem.group;
    final items = displayItem.items;

    // Use poster of the currently active item, fallback to root poster, then fallback to first item
    final watchingItem = items.where((i) => i.status == WatchStatus.watching).firstOrNull;
    final sortedItems = List<WatchlistItem>.from(items)..sort((a, b) => a.title.compareTo(b.title));
    final targetItem = watchingItem ?? 
        sortedItems.where((i) => i.status == WatchStatus.planToWatch).firstOrNull ?? 
        sortedItems.first;
        
    final posterUrl = targetItem.posterUrl.isNotEmpty ? targetItem.posterUrl : (group.rootPosterUrl.isNotEmpty ? group.rootPosterUrl : '');
    final title = (group.rootTitle != 'Unknown' && group.rootTitle.isNotEmpty) ? group.rootTitle : sortedItems.first.title;

    return GestureDetector(
      onTap: () {
        String mediaRouteId = targetItem.externalId;
        // Backwards compatibility for incorrectly saved IDs that miss the prefix
        if (!mediaRouteId.startsWith('tmdb-') && !mediaRouteId.startsWith('anilist-')) {
          switch (targetItem.mediaType) {
            case MediaType.movie:
              mediaRouteId = 'tmdb-movie-${targetItem.externalId}';
              break;
            case MediaType.series:
              mediaRouteId = 'tmdb-tv-${targetItem.externalId}';
              break;
            case MediaType.anime:
              mediaRouteId = 'anilist-${targetItem.externalId}';
              break;
          }
        }
        context.push('/media/$mediaRouteId');
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.divider.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 90,
                  child: posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppTheme.surfaceLight,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.surfaceLight,
                            child: const Icon(Icons.broken_image, size: 24, color: AppTheme.textMuted),
                          ),
                        )
                      : Container(
                          color: AppTheme.surfaceLight,
                          child: const Icon(Icons.movie, size: 24, color: AppTheme.textMuted),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMain,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
