import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import '../models/search_result.dart';
import 'service_providers.dart';
import 'dart:async';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String q) => state = q;
}

class SearchFilterNotifier extends Notifier<MediaFilter> {
  @override
  MediaFilter build() => MediaFilter.all;
  void updateFilter(MediaFilter f) => state = f;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);
final searchFilterProvider = NotifierProvider<SearchFilterNotifier, MediaFilter>(SearchFilterNotifier.new);

class SearchResultsNotifier extends AsyncNotifier<SearchResult> {
  Timer? _debounceTimer;

  @override
  Future<SearchResult> build() async {
    final query = ref.watch(searchQueryProvider);
    final filter = ref.watch(searchFilterProvider);

    if (query.isEmpty) {
      return SearchResult(results: [], totalResults: 0, totalPages: 0, page: 1);
    }

    final completer = Completer<SearchResult>();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final cacheService = ref.read(cacheServiceProvider);
        final cacheKey = 'search_${filter.name}_$query';
        final cached = cacheService.getSearchCache(cacheKey);
        if (cached != null) {
          completer.complete(SearchResult.fromJson(cached));
          return;
        }

        final tmdbService = ref.read(tmdbServiceProvider);
        final anilistService = ref.read(anilistServiceProvider);

        SearchResult result = SearchResult(results: [], totalResults: 0, totalPages: 0, page: 1);

        switch (filter) {
          case MediaFilter.movie:
            result = await tmdbService.searchMovies(query);
            break;
          case MediaFilter.series:
            result = await tmdbService.searchTV(query);
            break;
          case MediaFilter.anime:
            result = await anilistService.searchAnime(query);
            break;
          case MediaFilter.all:
            final tmdbMulti = await tmdbService.searchMulti(query);
            final anilistAnime = await anilistService.searchAnime(query, 1, 10);
            
            final combinedResults = <Media>[];
            
            // Filter out Japanese animation from TMDB if we have Anilist results
            for (final tmdbItem in tmdbMulti.results) {
              if (tmdbItem.originCountry == 'JP' && tmdbItem.genres.any((g) => g.name == 'Animation')) {
                // Skip it, we'll use AniList for anime
                continue;
              }
              combinedResults.add(tmdbItem);
            }
            
            combinedResults.addAll(anilistAnime.results);
            
            // Sort by vote count roughly
            combinedResults.sort((a, b) => b.voteCount.compareTo(a.voteCount));

            result = SearchResult(
              results: combinedResults,
              totalResults: tmdbMulti.totalResults + anilistAnime.totalResults,
              totalPages: 1, // Simplifying pagination for combined
              page: 1,
            );
            break;
        }

        await cacheService.setSearchCache(cacheKey, result.toJson());
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });

    return completer.future;
  }
}

final searchResultsProvider = AsyncNotifierProvider<SearchResultsNotifier, SearchResult>(SearchResultsNotifier.new);
