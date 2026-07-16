import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/watchlist_item.dart';
import '../models/media.dart';
import '../providers/watchlist_provider.dart';
import '../providers/watchlist_groups_provider.dart';

import '../widgets/media_card.dart';
import '../widgets/aesthetic_loader.dart';
import '../widgets/profile_app_bar.dart';

enum WatchlistTab { all, favorites, watching, planToWatch, completed, onHold, dropped }

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    WatchlistTab.all,
    WatchlistTab.favorites,
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
      appBar: ProfileAppBar(title: 'Watchlist'),
      body: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search watchlist...',
                  hintStyle: TextStyle(
                    color: context.colors.textSubtle,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.colors.textSubtle,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: context.colors.textSubtle,
                            size: 18,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: context.colors.surfaceLight,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.colors.divider.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.colors.divider.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.colors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                style: TextStyle(color: context.colors.textMain, fontSize: 14),
              ),
            ).animate().fadeIn(duration: 400.ms),

            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              height: 42,
              decoration: BoxDecoration(
                color: context.colors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: context.colors.divider.withValues(alpha: 0.5),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: EdgeInsets.symmetric(horizontal: 6),
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: context.colors.primary.withValues(alpha: 0.2),
                  border: Border.all(
                    color: context.colors.primary.withValues(alpha: 0.4),
                  ),
                ),
                labelColor: context.colors.primary,
                unselectedLabelColor: context.colors.textSubtle,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: _tabs.map((tab) {
                  return Tab(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_tabIcon(tab), size: 14),
                          SizedBox(width: 6),
                          Text(_tabLabel(tab)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 50.ms),

            SizedBox(height: 8),

            // ── Tab content ──
            Expanded(
              child: RefreshIndicator(
                color: context.colors.primary,
                backgroundColor: context.colors.surfaceLight,
                onRefresh: () async {
                  await ref.read(watchlistProvider.notifier).refresh();
                },
                child: watchlistAsync.when(
                  data: (items) {
                    return TabBarView(
                      controller: _tabController,
                      children: _tabs.map((tab) {
                        final filtered = items.where((i) {
                          if (tab == WatchlistTab.favorites) {
                            if (i is SingleDisplayItem) {
                              if (i.item.reaction != Reaction.favorite) return false;
                            } else if (i is FranchiseDisplayItem) {
                              if (!i.items.any((child) => child.reaction == Reaction.favorite)) return false;
                            }
                          } else if (tab != WatchlistTab.all) {
                            final status = _tabToStatus(tab);
                            if (i.aggregateStatus != status) return false;
                          }

                          if (_searchQuery.isEmpty) return true;

                          if (i is SingleDisplayItem) {
                            return i.item.title.toLowerCase().contains(
                              _searchQuery,
                            );
                          } else if (i is FranchiseDisplayItem) {
                            return i.group.rootTitle.toLowerCase().contains(
                                  _searchQuery,
                                ) ||
                                i.items.any(
                                  (child) => child.title.toLowerCase().contains(
                                    _searchQuery,
                                  ),
                                );
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
                  loading: () => Center(
                    child: AestheticLoader(size: 50),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: context.colors.error,
                          size: 36,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Failed to load watchlist',
                          style: TextStyle(color: context.colors.textMuted),
                        ),
                        SizedBox(height: 6),
                        Text(
                          e.toString(),
                          style: TextStyle(
                            color: context.colors.textSubtle,
                            fontSize: 12,
                          ),
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
      case WatchlistTab.all:
        return 'All Items';
      case WatchlistTab.favorites:
        return 'Favourites';
      case WatchlistTab.watching:
        return 'Watching';
      case WatchlistTab.planToWatch:
        return 'Plan to Watch';
      case WatchlistTab.completed:
        return 'Completed';
      case WatchlistTab.onHold:
        return 'On Hold';
      case WatchlistTab.dropped:
        return 'Dropped';
    }
  }

  IconData _tabIcon(WatchlistTab tab) {
    switch (tab) {
      case WatchlistTab.all:
        return Icons.all_inbox_rounded;
      case WatchlistTab.favorites:
        return Icons.star_rounded;
      case WatchlistTab.watching:
        return Icons.play_circle_outline_rounded;
      case WatchlistTab.planToWatch:
        return Icons.access_time_rounded;
      case WatchlistTab.completed:
        return Icons.check_circle_outline_rounded;
      case WatchlistTab.onHold:
        return Icons.pause_circle_outline_rounded;
      case WatchlistTab.dropped:
        return Icons.cancel_outlined;
    }
  }

  WatchStatus _tabToStatus(WatchlistTab tab) {
    switch (tab) {
      case WatchlistTab.watching:
        return WatchStatus.watching;
      case WatchlistTab.planToWatch:
        return WatchStatus.planToWatch;
      case WatchlistTab.completed:
        return WatchStatus.completed;
      case WatchlistTab.onHold:
        return WatchStatus.onHold;
      case WatchlistTab.dropped:
        return WatchStatus.dropped;
      default:
        return WatchStatus.watching; // Fallback
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
      WatchlistTab.all: (
        'Watchlist is empty',
        'Start adding movies and shows!',
      ),
      WatchlistTab.favorites: (
        'No favourites yet',
        'Mark titles you love with a heart',
      ),
      WatchlistTab.watching: ('Nothing playing', 'Start watching something!'),
      WatchlistTab.planToWatch: (
        'Your queue is empty',
        'Add titles to watch later',
      ),
      WatchlistTab.completed: (
        'No completions yet',
        'Finish watching something!',
      ),
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
              color: context.colors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border_rounded,
              color: context.colors.textSubtle,
              size: 28,
            ),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: context.colors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: context.colors.textSubtle, fontSize: 13),
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
      padding: EdgeInsets.fromLTRB(20, 8, 20, 100),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
          child = SizedBox.shrink();
        }

        return child;
      },
    );
  }
}

class _WatchlistCard extends ConsumerWidget {
  final WatchlistItem item;
  const _WatchlistCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _showRemoveDialog(context, ref, item),
      child: MediaCard(
        title: item.title,
        posterUrl: item.franchisePosterUrl ?? item.posterUrl,
        rating: item.rating,
        width: double.infinity,
        height: 155,
        typeBadge: _typeLabel(item.mediaType),
        isFavorite: item.reaction == Reaction.favorite,
        onTap: () {
          String cleanId = item.externalId.replaceAll(RegExp(r'^(tmdb-movie-|tmdb-tv-|anilist-)+'), '');
          String mediaRouteId = cleanId;
          switch (item.mediaType) {
            case MediaType.movie:
              mediaRouteId = 'tmdb-movie-$cleanId';
              break;
            case MediaType.series:
              mediaRouteId = 'tmdb-tv-$cleanId';
              break;
            case MediaType.anime:
              mediaRouteId = 'anilist-$cleanId';
              break;
          }
          if (mediaRouteId.contains('-season-')) {
            mediaRouteId = mediaRouteId.split('-season-').first;
          }
          context.push('/media/$mediaRouteId');
        },
      ),
    );
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
}

// ────────────────────────────────────────────────────────────
// Franchise group card (Stacked style)
// ────────────────────────────────────────────────────────────

class _FranchiseCard extends ConsumerWidget {
  final FranchiseDisplayItem displayItem;
  const _FranchiseCard({required this.displayItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = displayItem.group;
    final items = displayItem.items;

    if (items.isEmpty) return SizedBox.shrink();

    final watchingItem = items
        .where((i) => i.status == WatchStatus.watching)
        .firstOrNull;
    final sortedItems = List<WatchlistItem>.from(items)
      ..sort((a, b) {
        final aDate = (a.releaseDate?.isEmpty ?? true) ? null : a.releaseDate;
        final bDate = (b.releaseDate?.isEmpty ?? true) ? null : b.releaseDate;
        if (aDate != null && bDate != null) {
          return aDate.compareTo(bDate);
        }
        if (aDate != null) return -1;
        if (bDate != null) return 1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    final targetItem =
        watchingItem ??
        sortedItems
            .where((i) => i.status == WatchStatus.planToWatch)
            .firstOrNull ??
        sortedItems.first;

    final posterUrl = targetItem.posterUrl.isNotEmpty
        ? targetItem.posterUrl
        : (group.rootPosterUrl.isNotEmpty ? group.rootPosterUrl : '');
    final title = (group.rootTitle != 'Unknown' && group.rootTitle.isNotEmpty)
        ? group.rootTitle
        : sortedItems.first.title;

    final bool hasFavorite = items.any((i) => i.reaction == Reaction.favorite);
    final int extraItems = items.length - 1;

    return GestureDetector(
      onTap: () {
        String cleanId = targetItem.externalId.replaceAll(RegExp(r'^(tmdb-movie-|tmdb-tv-|anilist-)+'), '');
        String mediaRouteId = cleanId;
        switch (targetItem.mediaType) {
          case MediaType.movie:
            mediaRouteId = 'tmdb-movie-$cleanId';
            break;
          case MediaType.series:
            mediaRouteId = 'tmdb-tv-$cleanId';
            break;
          case MediaType.anime:
            mediaRouteId = 'anilist-$cleanId';
            break;
        }
        if (mediaRouteId.contains('-season-')) {
          mediaRouteId = mediaRouteId.split('-season-').first;
        }
        context.push('/media/$mediaRouteId');
      },
      onLongPress: () => _showFranchiseManageSheet(context, ref, displayItem),
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
                        color: context.colors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: context.colors.divider.withValues(alpha: 0.3),
                        ),
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
                      border: Border.all(
                        color: context.colors.divider.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: Offset(0, 5),
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
                                  memCacheHeight: 310, // ~155 * 2 for high DPI
                                  placeholder: (_, _) =>
                                      Container(color: context.colors.surfaceLight),
                                  errorWidget: (_, _, _) => Container(
                                    color: context.colors.surfaceLight,
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: context.colors.textSubtle,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(color: context.colors.surfaceLight),
                          // Favorite badge
                          if (hasFavorite)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.pinkAccent.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          // Badge for grouping
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.primary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.collections_bookmark_rounded,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    items.length.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
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
          SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colors.textMain,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          SizedBox(height: 2),
          Text(
            '${items.length} titles',
            style: TextStyle(
              color: context.colors.textSubtle,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Dialogs & Sheets for Deletion
// ────────────────────────────────────────────────────────────

void _showRemoveDialog(BuildContext context, WidgetRef ref, WatchlistItem item) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colors.divider.withValues(alpha: 0.5)),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: context.colors.error, size: 24),
          SizedBox(width: 8),
          Text(
            'Remove Item',
            style: TextStyle(color: context.colors.textMain, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to remove "${item.title}" from your watchlist?',
        style: TextStyle(color: context.colors.textMuted, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: context.colors.textMuted),
          ),
        ),
        FilledButton(
          onPressed: () {
            ref.read(watchlistProvider.notifier).remove(item.externalId, item.mediaType);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Removed ${item.title} from watchlist'),
                backgroundColor: context.colors.surfaceLight,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Remove'),
        ),
      ],
    ),
  );
}

void _showFranchiseManageSheet(BuildContext context, WidgetRef ref, FranchiseDisplayItem displayItem) {
  final group = displayItem.group;
  final items = displayItem.items;

  showModalBottomSheet(
    context: context,
    backgroundColor: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      group.rootTitle,
                      style: TextStyle(
                        color: context.colors.textMain,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showFranchiseBulkDeleteConfirm(context, ref, group.rootTitle, items);
                    },
                    icon: Icon(Icons.delete_sweep_rounded, color: context.colors.error, size: 18),
                    label: Text(
                      'Remove All',
                      style: TextStyle(color: context.colors.error, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Select items to remove from watchlist:',
                style: TextStyle(color: context.colors.textMuted, fontSize: 13),
              ),
              SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.colors.divider.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Tiny poster thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 32,
                              height: 48,
                              child: item.posterUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: item.posterUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => Container(
                                        color: context.colors.surface,
                                        child: Icon(Icons.broken_image_outlined, size: 16, color: context.colors.textSubtle),
                                      ),
                                    )
                                  : Container(color: context.colors.surface),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    color: context.colors.textMain,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  _statusLabel(item.status),
                                  style: TextStyle(
                                    color: context.colors.textSubtle,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ref.read(watchlistProvider.notifier).remove(item.externalId, item.mediaType);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Removed ${item.title} from watchlist'),
                                  backgroundColor: context.colors.surfaceLight,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: Icon(Icons.delete_outline_rounded, color: context.colors.error),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showFranchiseBulkDeleteConfirm(BuildContext context, WidgetRef ref, String title, List<WatchlistItem> items) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colors.divider.withValues(alpha: 0.5)),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: context.colors.error, size: 24),
          SizedBox(width: 8),
          Text(
            'Remove Franchise',
            style: TextStyle(color: context.colors.textMain, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to remove all ${items.length} items of "$title" from your watchlist?',
        style: TextStyle(color: context.colors.textMuted, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: context.colors.textMuted),
          ),
        ),
        FilledButton(
          onPressed: () {
            ref.read(watchlistProvider.notifier).bulkRemoveFranchise(items);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Removed all items of $title from watchlist'),
                backgroundColor: context.colors.surfaceLight,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Remove All'),
        ),
      ],
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
