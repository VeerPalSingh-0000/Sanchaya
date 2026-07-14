import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import '../models/search_result.dart';
import 'service_providers.dart';
import 'dart:async';
import '../services/tmdb_service.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String q) => state = q.trim();
}

class SearchFilterNotifier extends Notifier<MediaFilter> {
  @override
  MediaFilter build() => MediaFilter.all;
  void updateFilter(MediaFilter f) => state = f;
}

final discoverSearchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);
final discoverSearchFilterProvider = NotifierProvider<SearchFilterNotifier, MediaFilter>(SearchFilterNotifier.new);

final homeSearchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);
final homeSearchFilterProvider = NotifierProvider<SearchFilterNotifier, MediaFilter>(SearchFilterNotifier.new);

abstract class BaseSearchResultsNotifier extends AsyncNotifier<SearchResult> {
  NotifierProvider<SearchQueryNotifier, String> get queryProvider;
  NotifierProvider<SearchFilterNotifier, MediaFilter> get filterProvider;
  
  Timer? _debounceTimer;
  int _currentPage = 1;
  bool _isLoadingNextPage = false;
  String _lastQuery = '';
  MediaFilter _lastFilter = MediaFilter.all;

  @override
  Future<SearchResult> build() async {
    final query = ref.watch(queryProvider);
    final filter = ref.watch(filterProvider);

    if (query.isEmpty) {
      return SearchResult(results: [], totalResults: 0, totalPages: 0, page: 1);
    }

    _currentPage = 1;
    _lastQuery = query;
    _lastFilter = filter;
    final completer = Completer<SearchResult>();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final cacheService = ref.read(cacheServiceProvider);
        final cacheKey = 'search_v2_${filter.name}_${query}_page_1';
        final cached = cacheService.getSearchCache(cacheKey);
        if (cached != null) {
          completer.complete(SearchResult.fromJson(cached));
          return;
        }

        final result = await _fetchResults(query, filter, 1);
        await cacheService.setSearchCache(cacheKey, result.toJson());
        completer.complete(result);
      } catch (e, st) {
        if (!completer.isCompleted) {
          completer.completeError(e, st);
        }
      }
    });

    return completer.future;
  }

  Future<void> fetchNextPage() async {
    if (_isLoadingNextPage) return;
    if (state.value == null) return;
    
    final currentResult = state.value!;
    if (currentResult.page >= currentResult.totalPages || currentResult.totalPages == 0) return;
    
    _isLoadingNextPage = true;
    final nextPage = _currentPage + 1;
    
    try {
      final newResult = await _fetchResults(_lastQuery, _lastFilter, nextPage);
      
      _currentPage = nextPage;
      state = AsyncValue.data(SearchResult(
        results: [...currentResult.results, ...newResult.results],
        totalResults: newResult.totalResults,
        totalPages: newResult.totalPages,
        page: _currentPage,
      ));
    } finally {
      _isLoadingNextPage = false;
    }
  }

  Future<SearchResult> _fetchResults(String query, MediaFilter filter, int page) async {
    final tmdbService = ref.read(tmdbServiceProvider);
    final anilistService = ref.read(anilistServiceProvider);

    if (query.startsWith('#genre:')) {
      final genreIdStr = query.replaceFirst('#genre:', '');
      final genreId = int.tryParse(genreIdStr);
      if (genreId != null) {
        final genreName = TmdbService.tmdbGenreMap[genreId] ?? '';
        final anilistGenre = genreName == 'Sci-Fi' ? 'Sci-Fi' : genreName;

        switch (filter) {
          case MediaFilter.movie:
             return await tmdbService.discoverByGenres('movie', [genreId], page);
          case MediaFilter.series:
             return await tmdbService.discoverByGenres('tv', [genreId], page);
          case MediaFilter.anime:
             return await anilistService.discoverAnimeByGenres([anilistGenre], page);
          case MediaFilter.all:
             final m = await tmdbService.discoverByGenres('movie', [genreId], page);
             final t = await tmdbService.discoverByGenres('tv', [genreId], page);
             final a = await anilistService.discoverAnimeByGenres([anilistGenre], page);
             
             final combined = [...m.results, ...t.results, ...a.results];
             combined.shuffle();
             
             return SearchResult(
                results: combined,
                totalResults: m.totalResults + t.totalResults + a.totalResults,
                totalPages: m.totalPages > t.totalPages ? (m.totalPages > a.totalPages ? m.totalPages : a.totalPages) : (t.totalPages > a.totalPages ? t.totalPages : a.totalPages),
                page: page,
             );
        }
      }
    }

    final tmdbQuery = query;

    switch (filter) {
      case MediaFilter.movie:
        return await tmdbService.searchMovies(tmdbQuery, page);
      case MediaFilter.series:
        return await tmdbService.searchTV(tmdbQuery, page);
      case MediaFilter.anime:
        return await anilistService.searchAnime(query, page);
      case MediaFilter.all:
                SearchResult? tmdbMulti;
        SearchResult? anilistAnime;
        
        try {
          tmdbMulti = await tmdbService.searchMulti(tmdbQuery, page);
        } catch (e) {
          print('TMDB search error: $e');
        }
        
        try {
          anilistAnime = await anilistService.searchAnime(query, page, 10);
        } catch (e) {
          print('Anilist search error: $e');
        }
        
        if (tmdbMulti == null && anilistAnime == null) {
          throw Exception('Search failed. Please check your internet connection.');
        }
        
        tmdbMulti ??= SearchResult(results: [], totalResults: 0, totalPages: 0, page: page);
        anilistAnime ??= SearchResult(results: [], totalResults: 0, totalPages: 0, page: page);
        
        final combinedResults = <Media>[];
        for (final tmdbItem in tmdbMulti.results) {
          if (tmdbItem.originCountry == 'JP' && tmdbItem.genres.any((g) => g.name == 'Animation')) {
            continue;
          }
          combinedResults.add(tmdbItem);
        }
        
        combinedResults.addAll(anilistAnime.results);
        combinedResults.sort((a, b) => b.voteCount.compareTo(a.voteCount));

        return SearchResult(
          results: combinedResults,
          totalResults: tmdbMulti.totalResults + anilistAnime.totalResults,
          totalPages: tmdbMulti.totalPages > anilistAnime.totalPages ? tmdbMulti.totalPages : anilistAnime.totalPages,
          page: page,
        );
    }
  }
}

class DiscoverSearchResultsNotifier extends BaseSearchResultsNotifier {
  @override
  NotifierProvider<SearchQueryNotifier, String> get queryProvider => discoverSearchQueryProvider;
  @override
  NotifierProvider<SearchFilterNotifier, MediaFilter> get filterProvider => discoverSearchFilterProvider;
}

class HomeSearchResultsNotifier extends BaseSearchResultsNotifier {
  @override
  NotifierProvider<SearchQueryNotifier, String> get queryProvider => homeSearchQueryProvider;
  @override
  NotifierProvider<SearchFilterNotifier, MediaFilter> get filterProvider => homeSearchFilterProvider;
}

final discoverSearchResultsProvider = AsyncNotifierProvider<DiscoverSearchResultsNotifier, SearchResult>(DiscoverSearchResultsNotifier.new);
final homeSearchResultsProvider = AsyncNotifierProvider<HomeSearchResultsNotifier, SearchResult>(HomeSearchResultsNotifier.new);
