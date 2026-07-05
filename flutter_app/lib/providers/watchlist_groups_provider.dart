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
}

class SingleDisplayItem extends DisplayItem {
  final WatchlistItem item;

  SingleDisplayItem(this.item);

  @override
  WatchStatus get aggregateStatus => item.status;

  @override
  DateTime get sortDate => item.addedAt;
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

final watchlistGroupsProvider = Provider<AsyncValue<List<DisplayItem>>>((ref) {
  final watchlistAsync = ref.watch(watchlistProvider);

  return watchlistAsync.whenData((watchlist) {
    final list = <DisplayItem>[];
    final groupedIds = <String>{};
    final franchiseMap = <String, _FranchiseTemp>{};

    final uniqueWatchlist = <WatchlistItem>[];
    final seenKeys = <String>{};

    for (final item in watchlist) {
      final extId = item.externalId.isNotEmpty ? item.externalId : item.id;
      final cleanExtId = extId.replaceAll(RegExp(r'tmdb-tv-|tmdb-movie-|anilist-'), '');
      final key = '$cleanExtId-${item.mediaType.name}';
      
      if (!seenKeys.contains(key)) {
        seenKeys.add(key);
        uniqueWatchlist.add(item);
      }
    }

    // 1. Group items with franchiseId
    for (final item in uniqueWatchlist) {
      if (item.franchiseId != null && item.franchiseId!.isNotEmpty) {
        if (!franchiseMap.containsKey(item.franchiseId)) {
          franchiseMap[item.franchiseId!] = _FranchiseTemp(
            title: item.franchiseTitle ?? item.title,
            posterUrl: item.franchisePosterUrl ?? item.posterUrl,
            items: [],
          );
        }
        franchiseMap[item.franchiseId!]!.items.add(item);
        groupedIds.add(item.id);
      }
    }

    // 2. Compute aggregate status and build FranchiseDisplayItem
    franchiseMap.forEach((franchiseId, data) {
      if (data.items.isNotEmpty) {
        WatchStatus aggregateStatus = WatchStatus.planToWatch;
        
        if (data.items.any((i) => i.status == WatchStatus.watching)) {
          aggregateStatus = WatchStatus.watching;
        } else if (data.items.every((i) => i.status == WatchStatus.completed)) {
          aggregateStatus = WatchStatus.completed;
        } else if (data.items.any((i) => i.status == WatchStatus.planToWatch)) {
          aggregateStatus = WatchStatus.planToWatch;
        } else if (data.items.any((i) => i.status == WatchStatus.onHold)) {
          aggregateStatus = WatchStatus.onHold;
        } else {
          aggregateStatus = WatchStatus.dropped;
        }

        list.add(FranchiseDisplayItem(
          FranchiseGroup(
            rootId: franchiseId,
            rootTitle: data.title,
            rootPosterUrl: data.posterUrl,
            memberIds: data.items.map((i) => i.externalId).toList(),
          ),
          data.items,
          aggregateStatus,
        ));
      }
    });

    // 3. Add remaining non-grouped items
    for (final item in uniqueWatchlist) {
      if (!groupedIds.contains(item.id)) {
        list.add(SingleDisplayItem(item));
      }
    }

    // 4. Sort strictly by sortDate (descending)
    list.sort((a, b) => b.sortDate.compareTo(a.sortDate));

    return list;
  });
});
