import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import '../models/watchlist_item.dart';
import '../models/search_result.dart';
import 'service_providers.dart';
import 'watchlist_provider.dart';

class RecommendationResult {
  final Media media;
  final List<String> matchedGenres;
  final int matchScore;
  final String reason;

  RecommendationResult({
    required this.media,
    required this.matchedGenres,
    required this.matchScore,
    required this.reason,
  });
}

class RecommendationsData {
  final List<RecommendationResult> results;
  final List<String> topGenres;

  RecommendationsData({required this.results, required this.topGenres});
}

final recommendationsProvider = FutureProvider<RecommendationsData>((ref) async {
  final watchlistAsync = ref.watch(watchlistProvider);
  if (!watchlistAsync.hasValue || watchlistAsync.value == null) {
    return RecommendationsData(results: [], topGenres: []);
  }

  final allItems = watchlistAsync.value!;
  
  if (allItems.isEmpty) {
    // Return trending if no watchlist
    final tmdbService = ref.read(tmdbServiceProvider);
    final anilistService = ref.read(anilistServiceProvider);
    
    final movies = await tmdbService.getTrending(mediaType: 'movie');
    final series = await tmdbService.getTrending(mediaType: 'tv');
    final anime = await anilistService.getTrendingAnime();
    
    final fallbackResults = [...movies.take(5), ...series.take(5), ...anime.take(5)].map((m) => RecommendationResult(
      media: m,
      matchedGenres: [],
      matchScore: 0,
      reason: 'Trending now',
    )).toList();
    fallbackResults.shuffle();
    
    return RecommendationsData(results: fallbackResults, topGenres: []);
  }
  
  final seedItems = allItems.where((item) => item.reaction == Reaction.love || item.reaction == Reaction.good || item.status == WatchStatus.completed || item.rating >= 7)
    .where((item) => item.reaction != Reaction.bad).take(10).toList();
    
  final badItems = allItems.where((item) => item.reaction == Reaction.bad).take(5).toList();
  
  final itemsToFetch = seedItems.isNotEmpty ? seedItems : allItems.where((item) => item.reaction != Reaction.bad).take(10).toList();
  
  if (itemsToFetch.isEmpty) {
    return RecommendationsData(results: [], topGenres: []);
  }
  
  final tmdbService = ref.read(tmdbServiceProvider);
  final anilistService = ref.read(anilistServiceProvider);
  
  final detailPromises = itemsToFetch.map((item) async {
    if (item.mediaType == MediaType.movie) return await tmdbService.getMovieDetails('tmdb-movie-${item.externalId}');
    if (item.mediaType == MediaType.series) return await tmdbService.getTVDetails('tmdb-tv-${item.externalId}');
    if (item.mediaType == MediaType.anime) return await anilistService.getAnimeDetails('anilist-${item.externalId}');
    return null;
  });
  
  final detailedMediaRaw = await Future.wait(detailPromises);
  final detailedMedia = detailedMediaRaw.whereType<Media>().toList();
  
  final badDetailPromises = badItems.map((item) async {
    if (item.mediaType == MediaType.movie) return await tmdbService.getMovieDetails('tmdb-movie-${item.externalId}');
    if (item.mediaType == MediaType.series) return await tmdbService.getTVDetails('tmdb-tv-${item.externalId}');
    if (item.mediaType == MediaType.anime) return await anilistService.getAnimeDetails('anilist-${item.externalId}');
    return null;
  });
  
  final badDetailedMediaRaw = await Future.wait(badDetailPromises);
  final badDetailedMedia = badDetailedMediaRaw.whereType<Media>().toList();
  
  final genreWeights = <String, int>{};
  
  for (var media in detailedMedia) {
    final dbItem = itemsToFetch.where((i) => i.externalId == media.externalId).firstOrNull;
    int weight = (dbItem?.rating.toInt() ?? 0) > 0 ? dbItem!.rating.toInt() : 7;
    if (dbItem?.reaction == Reaction.love) weight = 15;
    if (dbItem?.reaction == Reaction.good) weight = 10;
    
    for (var genre in media.genres) {
      genreWeights[genre.name] = (genreWeights[genre.name] ?? 0) + weight;
    }
  }
  
  for (var media in badDetailedMedia) {
    for (var genre in media.genres) {
      genreWeights[genre.name] = (genreWeights[genre.name] ?? 0) - 10;
    }
  }
  
  final sortedGenres = genreWeights.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
  final topGenres = sortedGenres.take(4).map((e) => e.key).toList();
  
  if (topGenres.isEmpty) {
    return RecommendationsData(results: [], topGenres: []);
  }
  
  final tmdbGenreIds = topGenres.map((g) => tmdbService.getTmdbGenreIdByName(g)).whereType<int>().toList();
  
  final excludeIds = allItems.map((i) => i.externalId).toList();
  
  final movieCount = allItems.where((i) => i.mediaType == MediaType.movie).length;
  final seriesCount = allItems.where((i) => i.mediaType == MediaType.series).length;
  final animeCount = allItems.where((i) => i.mediaType == MediaType.anime).length;
  final totalItems = allItems.length;
  
  final movieRatio = movieCount / totalItems;
  final seriesRatio = seriesCount / totalItems;
  final animeRatio = animeCount / totalItems;
  
  final fetchPromises = <Future<SearchResult>>[];
  
  if (movieRatio > 0.1 || movieCount > 0) {
    fetchPromises.add(tmdbService.discoverByGenres('movie', tmdbGenreIds));
  }
  if (seriesRatio > 0.1 || seriesCount > 0) {
    fetchPromises.add(tmdbService.discoverByGenres('tv', tmdbGenreIds));
  }
  if (animeRatio > 0.1 || animeCount > 0) {
    fetchPromises.add(anilistService.discoverAnimeByGenres(topGenres));
  }
  
  if (fetchPromises.isEmpty) {
    fetchPromises.addAll([
      tmdbService.discoverByGenres('movie', tmdbGenreIds),
      tmdbService.discoverByGenres('tv', tmdbGenreIds),
      anilistService.discoverAnimeByGenres(topGenres),
    ]);
  }
  
  final searchResults = await Future.wait(fetchPromises);
  
  var recommendedMedia = <Media>[];
  for (var res in searchResults) {
    recommendedMedia.addAll(res.results.where((m) => !excludeIds.contains(m.externalId)));
  }
  
  final scoredResults = recommendedMedia.map((media) {
    final mediaGenreNames = media.genres.map((g) => g.name).toList();
    final matchedGenres = topGenres.where((g) => mediaGenreNames.contains(g)).toList();
    final matchScore = matchedGenres.length * 10 + (media.rating.toInt());
    
    final reason = matchedGenres.isNotEmpty ? 'Because you enjoy ${matchedGenres.join(' and ')}' : 'Recommended based on your watchlist';
    return RecommendationResult(
      media: media,
      matchedGenres: matchedGenres,
      matchScore: matchScore,
      reason: reason,
    );
  }).toList();
  
  final uniqueResults = <String, RecommendationResult>{};
  for (var res in scoredResults) {
    if (!uniqueResults.containsKey(res.media.externalId)) {
      uniqueResults[res.media.externalId] = res;
    }
  }
  
  final finalResults = uniqueResults.values.toList()..sort((a, b) => b.matchScore.compareTo(a.matchScore));
  
  return RecommendationsData(
    results: finalResults.take(60).toList(),
    topGenres: topGenres,
  );
});
