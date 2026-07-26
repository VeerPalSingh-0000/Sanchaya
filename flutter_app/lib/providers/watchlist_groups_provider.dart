import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/watchlist_item.dart';
import '../models/media.dart';
import 'watchlist_provider.dart';

class FranchiseGroup {
  final String rootId;
  final String rootTitle;
  final String rootPosterUrl;
  final List<String> memberIds;

  FranchiseGroup({
    required this.rootId,
    required this.rootTitle,
    required this.rootPosterUrl,
    required this.memberIds,
  });
}

abstract class DisplayItem {
  WatchStatus get aggregateStatus;
  DateTime get sortDate;
  String get title;
  double get rating;
  double get progressPercentage;
}

class SingleDisplayItem extends DisplayItem {
  final WatchlistItem item;

  SingleDisplayItem(this.item);

  @override
  WatchStatus get aggregateStatus => item.status;

  @override
  DateTime get sortDate => item.addedAt;

  @override
  String get title => item.title;

  @override
  double get rating => item.rating;

  @override
  double get progressPercentage {
    if (item.totalEpisodes != null && item.totalEpisodes! > 0) {
      return (item.progress ?? 0) / item.totalEpisodes!;
    }
    return item.status == WatchStatus.completed ? 1.0 : 0.0;
  }
}

class FranchiseDisplayItem extends DisplayItem {
  final FranchiseGroup group;
  final List<WatchlistItem> items;
  final WatchStatus _aggregateStatus;

  FranchiseDisplayItem(this.group, this.items, this._aggregateStatus);

  @override
  WatchStatus get aggregateStatus => _aggregateStatus;

  @override
  DateTime get sortDate {
    if (items.isEmpty) return DateTime.now();
    return items.map((e) => e.addedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  String get title => group.rootTitle;

  @override
  double get rating {
    if (items.isEmpty) return 0.0;
    return items.map((e) => e.rating).reduce((a, b) => a + b) / items.length;
  }

  @override
  double get progressPercentage {
    if (items.isEmpty) return 0.0;
    double totalP = 0;
    for (var i in items) {
      if (i.totalEpisodes != null && i.totalEpisodes! > 0) {
        totalP += (i.progress ?? 0) / i.totalEpisodes!;
      } else {
        totalP += i.status == WatchStatus.completed ? 1.0 : 0.0;
      }
    }
    return totalP / items.length;
  }
}

class _FranchiseTemp {
  final String title;
  final String posterUrl;
  final List<WatchlistItem> items;

  _FranchiseTemp({
    required this.title,
    required this.posterUrl,
    required this.items,
  });
}

/// Strips all known provider prefixes and any trailing season suffix to get
/// a canonical numeric-only base ID for dedup / grouping.
String _canonicalBaseId(String raw) {
  var id = raw.replaceAll(RegExp(r'^(tmdb-tv-|tmdb-movie-|anilist-)+'), '');
  // Also strip trailing season suffixes like "-season-1"
  final seasonIdx = id.indexOf('-season-');
  if (seasonIdx != -1) id = id.substring(0, seasonIdx);
  return id;
}

enum WatchlistSortOption { dateAdded, title, rating, progress }
enum WatchlistSortOrder { ascending, descending }

final watchlistSortOptionProvider = NotifierProvider<WatchlistSortOptionNotifier, WatchlistSortOption>(WatchlistSortOptionNotifier.new);
final watchlistSortOrderProvider = NotifierProvider<WatchlistSortOrderNotifier, WatchlistSortOrder>(WatchlistSortOrderNotifier.new);

class WatchlistSortOptionNotifier extends Notifier<WatchlistSortOption> {
  @override
  WatchlistSortOption build() => WatchlistSortOption.dateAdded;
  void set(WatchlistSortOption option) => state = option;
}

class WatchlistSortOrderNotifier extends Notifier<WatchlistSortOrder> {
  @override
  WatchlistSortOrder build() => WatchlistSortOrder.descending;
  void set(WatchlistSortOrder order) => state = order;
}

final watchlistGroupsProvider = Provider<AsyncValue<List<DisplayItem>>>((ref) {
  final watchlistAsync = ref.watch(watchlistProvider);

  return watchlistAsync.whenData((watchlist) {
    final list = <DisplayItem>[];
    final franchiseMap = <String, _FranchiseTemp>{};

    // ── Step 0: Deduplicate watchlist items ──
    // Two items are duplicates if they share the same canonical base ID
    // AND the same media type. When duplicates exist, prefer the one with
    // a non-empty posterUrl and a non-null franchiseId.
    final uniqueWatchlist = <WatchlistItem>[];
    final seenKeys = <String, int>{}; // key → index in uniqueWatchlist

    for (final item in watchlist) {
      final extId = item.externalId.isNotEmpty ? item.externalId : item.id;
      final baseId = _canonicalBaseId(extId);
      final key = '$baseId-${item.mediaType.name}';

      if (seenKeys.containsKey(key)) {
        // We already have an entry – keep the "better" one
        final existingIdx = seenKeys[key]!;
        final existing = uniqueWatchlist[existingIdx];
        final existingScore = _qualityScore(existing);
        final newScore = _qualityScore(item);
        if (newScore > existingScore) {
          uniqueWatchlist[existingIdx] = item;
        }
      } else {
        seenKeys[key] = uniqueWatchlist.length;
        uniqueWatchlist.add(item);
      }
    }

    // ── Step 1: Group items by franchise ──
    for (final item in uniqueWatchlist) {
      String? computedFranchiseId = item.franchiseId;
      String computedFranchiseTitle = item.franchiseTitle ?? item.title;
      String computedFranchisePosterUrl = item.franchisePosterUrl ?? item.posterUrl;

      if (computedFranchiseId == null || computedFranchiseId.isEmpty) {
        if (item.externalId.contains('-season-')) {
          computedFranchiseId = item.externalId.split('-season-').first;
          if (item.title.contains(': ')) {
            computedFranchiseTitle = item.title.split(': ').first;
          } else if (item.title.contains(' - ')) {
            computedFranchiseTitle = item.title.split(' - ').first;
          }
        } else {
          // Standalone show – use its own external ID as franchise root
          computedFranchiseId = item.externalId;
        }
      }

      if (computedFranchiseId.isNotEmpty) {
        final cleanFranchiseId = _canonicalBaseId(computedFranchiseId);
        if (!franchiseMap.containsKey(cleanFranchiseId)) {
          franchiseMap[cleanFranchiseId] = _FranchiseTemp(
            title: computedFranchiseTitle,
            posterUrl: computedFranchisePosterUrl,
            items: [],
          );
        } else {
          // Update title/poster if the existing entry has weaker data
          final existing = franchiseMap[cleanFranchiseId]!;
          if (existing.posterUrl.isEmpty && computedFranchisePosterUrl.isNotEmpty) {
            franchiseMap[cleanFranchiseId] = _FranchiseTemp(
              title: computedFranchiseTitle,
              posterUrl: computedFranchisePosterUrl,
              items: existing.items,
            );
          }
        }
        franchiseMap[cleanFranchiseId]!.items.add(item);
      }
    }

    // ── Step 2: Build display items ──
    // Franchise groups with 2+ items → FranchiseDisplayItem (stacked card)
    // Franchise groups with exactly 1 item → SingleDisplayItem (regular card)
    franchiseMap.forEach((franchiseId, data) {
      if (data.items.isEmpty) return;

      if (data.items.length == 1) {
        // Single item – show as a normal card, not a stacked franchise card
        list.add(SingleDisplayItem(data.items.first));
      } else {
        // Multi-item franchise group
        WatchStatus aggregateStatus = WatchStatus.planToWatch;

        if (data.items.any((i) => i.status == WatchStatus.watching)) {
          aggregateStatus = WatchStatus.watching;
        } else if (data.items.every((i) => i.status == WatchStatus.completed)) {
          aggregateStatus = WatchStatus.completed;
        } else if (data.items.any((i) => i.status == WatchStatus.onHold)) {
          aggregateStatus = WatchStatus.onHold;
        } else if (data.items.any((i) => i.status == WatchStatus.planToWatch)) {
          aggregateStatus = WatchStatus.planToWatch;
        } else {
          aggregateStatus = WatchStatus.dropped;
        }



        // Pick the best poster for the group
        final bestPoster = data.posterUrl.isNotEmpty
            ? data.posterUrl
            : data.items
                .where((i) => i.posterUrl.isNotEmpty)
                .map((i) => i.posterUrl)
                .firstOrNull ?? '';

        list.add(FranchiseDisplayItem(
          FranchiseGroup(
            rootId: franchiseId,
            rootTitle: data.title,
            rootPosterUrl: bestPoster,
            memberIds: data.items.map((i) => i.externalId).toList(),
          ),
          data.items,
          aggregateStatus,
        ));
      }
    });

    // ── Step 3: Sort by most recent activity (descending) ──
    list.sort((a, b) => b.sortDate.compareTo(a.sortDate));

    return list;
  });
});

/// Score an item for quality-based dedup. Higher is better.
int _qualityScore(WatchlistItem item) {
  var score = 0;
  if (item.posterUrl.isNotEmpty) score += 2;
  if (item.franchiseId != null && item.franchiseId!.isNotEmpty) score += 1;
  if (item.franchiseTitle != null && item.franchiseTitle!.isNotEmpty) score += 1;
  if (item.franchisePosterUrl != null && item.franchisePosterUrl!.isNotEmpty) score += 1;
  if (item.title.isNotEmpty && item.title != 'Unknown') score += 1;
  return score;
}
