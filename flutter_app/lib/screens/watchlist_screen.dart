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
import '../widgets/media_card.dart';

enum WatchlistTab { all, watching, planToWatch, completed, onHold, dropped }

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> with SingleTickerProviderStateMixin {
  static const _tabs = [
    WatchlistTab.all,
    WatchlistTab.watching,
    WatchlistTab.planToWatch,
    WatchlistTab.completed,
    WatchlistTab.onHold,
    WatchlistTab.dropped,
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
                tabs: _tabs.map((tab) {
                  return Tab(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_tabIcon(tab), size: 14),
                          const SizedBox(width: 6),
                          Text(_tabLabel(tab)),
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
              child: RefreshIndicator(
                color: AppTheme.primary,
                backgroundColor: AppTheme.surfaceLight,
                onRefresh: () async {
                  await ref.read(watchlistProvider.notifier).refresh();
                },
                child: watchlistAsync.when(
                  data: (items) {
                    return TabBarView(
                      controller: _tabController,
                      children: _tabs.map((tab) {
                      final filtered = items.where((i) {
                        if (tab != WatchlistTab.all) {
                          final status = _tabToStatus(tab);
                          if (i.aggregateStatus != status) return false;
                        }
                        
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
                        return _EmptyTab(tab: tab);
                      }
                      return _WatchlistGrid(items: filtered);
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
            ),
          ],
        ),
      ),
    );
  }

  String _tabLabel(WatchlistTab tab) {
    switch (tab) {
      case WatchlistTab.all: return 'All Items';
      case WatchlistTab.watching: return 'Watching';
      case WatchlistTab.planToWatch: return 'Plan to Watch';
      case WatchlistTab.completed: return 'Completed';
      case WatchlistTab.onHold: return 'On Hold';
      case WatchlistTab.dropped: return 'Dropped';
    }
  }

  IconData _tabIcon(WatchlistTab tab) {
    switch (tab) {
      case WatchlistTab.all: return Icons.all_inbox_rounded;
      case WatchlistTab.watching: return Icons.play_circle_outline_rounded;
      case WatchlistTab.planToWatch: return Icons.access_time_rounded;
      case WatchlistTab.completed: return Icons.check_circle_outline_rounded;
      case WatchlistTab.onHold: return Icons.pause_circle_outline_rounded;
      case WatchlistTab.dropped: return Icons.cancel_outlined;
    }
  }

  WatchStatus _tabToStatus(WatchlistTab tab) {
    switch (tab) {
      case WatchlistTab.watching: return WatchStatus.watching;
      case WatchlistTab.planToWatch: return WatchStatus.planToWatch;
      case WatchlistTab.completed: return WatchStatus.completed;
      case WatchlistTab.onHold: return WatchStatus.onHold;
      case WatchlistTab.dropped: return WatchStatus.dropped;
      default: return WatchStatus.watching; // Fallback
    }
  }
}

// ────────────────────────────────────────────────────────────
// Empty state per tab
// ────────────────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  final WatchlistTab tab;
  const _EmptyTab({required this.tab});

  @override
  Widget build(BuildContext context) {
    final messages = {
      WatchlistTab.all: ('Watchlist is empty', 'Start adding movies and shows!'),
      WatchlistTab.watching: ('Nothing playing', 'Start watching something!'),
      WatchlistTab.planToWatch: ('Your queue is empty', 'Add titles to watch later'),
      WatchlistTab.completed: ('No completions yet', 'Finish watching something!'),
      WatchlistTab.onHold: ('Nothing on hold', 'Paused shows will appear here'),
      WatchlistTab.dropped: ('Nothing dropped', 'Dropped titles appear here'),
    };

    final (title, subtitle) = messages[tab]!;

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
// Watchlist grid layout
// ────────────────────────────────────────────────────────────

class _WatchlistGrid extends StatelessWidget {
  final List<DisplayItem> items;
  const _WatchlistGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.46,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final displayItem = items[index];
        final Widget child;
        if (displayItem is SingleDisplayItem) {
          child = _WatchlistCard(item: displayItem.item);
        } else if (displayItem is FranchiseDisplayItem) {
          child = _FranchiseCard(displayItem: displayItem);
        } else {
          child = const SizedBox.shrink();
        }

        return child
            .animate()
            .fadeIn(
              duration: 300.ms,
              delay: index > 12 ? Duration.zero : Duration(milliseconds: (30 * index).clamp(0, 300)),
            );
      },
    );
  }
}

class _WatchlistCard extends StatelessWidget {
  final WatchlistItem item;
  const _WatchlistCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return MediaCard(
      title: item.title,
      posterUrl: item.posterUrl,
      rating: item.rating,
      width: double.infinity,
      height: 155,
      typeBadge: _typeLabel(item.mediaType),
      onTap: () {
        String mediaRouteId = item.externalId;
        if (!mediaRouteId.startsWith('tmdb-') && !mediaRouteId.startsWith('anilist-')) {
          switch (item.mediaType) {
            case MediaType.movie: mediaRouteId = 'tmdb-movie-${item.externalId}'; break;
            case MediaType.series: mediaRouteId = 'tmdb-tv-${item.externalId}'; break;
            case MediaType.anime: mediaRouteId = 'anilist-${item.externalId}'; break;
          }
        }
        context.push('/media/$mediaRouteId');
      },
    );
  }

  String _typeLabel(MediaType type) {
    switch (type) {
      case MediaType.movie: return 'MOVIE';
      case MediaType.series: return 'TV';
      case MediaType.anime: return 'ANIME';
    }
  }
}

// ────────────────────────────────────────────────────────────
// Franchise group card (Stacked style)
// ────────────────────────────────────────────────────────────

class _FranchiseCard extends StatelessWidget {
  final FranchiseDisplayItem displayItem;
  const _FranchiseCard({required this.displayItem});

  @override
  Widget build(BuildContext context) {
    final group = displayItem.group;
    final items = displayItem.items;

    if (items.isEmpty) return const SizedBox.shrink();

    final watchingItem = items.where((i) => i.status == WatchStatus.watching).firstOrNull;
    final sortedItems = List<WatchlistItem>.from(items)..sort((a, b) => a.title.compareTo(b.title));
    final targetItem = watchingItem ?? 
        sortedItems.where((i) => i.status == WatchStatus.planToWatch).firstOrNull ?? 
        sortedItems.first;
        
    final posterUrl = targetItem.posterUrl.isNotEmpty ? targetItem.posterUrl : (group.rootPosterUrl.isNotEmpty ? group.rootPosterUrl : '');
    final title = (group.rootTitle != 'Unknown' && group.rootTitle.isNotEmpty) ? group.rootTitle : sortedItems.first.title;
    
    final int extraItems = items.length - 1;

    return GestureDetector(
      onTap: () {
        String mediaRouteId = targetItem.externalId;
        if (!mediaRouteId.startsWith('tmdb-') && !mediaRouteId.startsWith('anilist-')) {
          switch (targetItem.mediaType) {
            case MediaType.movie: mediaRouteId = 'tmdb-movie-${targetItem.externalId}'; break;
            case MediaType.series: mediaRouteId = 'tmdb-tv-${targetItem.externalId}'; break;
            case MediaType.anime: mediaRouteId = 'anilist-${targetItem.externalId}'; break;
          }
        }
        context.push('/media/$mediaRouteId');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stacked Poster
          SizedBox(
            width: double.infinity,
            height: 155,
            child: Stack(
              children: [
                // Background card
                if (extraItems > 0)
                  Positioned(
                    top: 0,
                    left: 6,
                    right: 6,
                    bottom: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                // Foreground card
                Positioned(
                  top: extraItems > 0 ? 8 : 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.divider.withValues(alpha: 0.3), width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          posterUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: posterUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => Container(color: AppTheme.surfaceLight),
                                  errorWidget: (_, _, _) => Container(
                                    color: AppTheme.surfaceLight,
                                    child: const Center(
                                      child: Icon(Icons.broken_image_outlined, color: AppTheme.textSubtle, size: 24),
                                    ),
                                  ),
                                )
                              : Container(color: AppTheme.surfaceLight),
                          // Badge for grouping
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.collections_bookmark_rounded, size: 10, color: Colors.white),
                                  const SizedBox(width: 2),
                                  Text(
                                    items.length.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textMain,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${items.length} titles',
            style: const TextStyle(
              color: AppTheme.textSubtle,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
