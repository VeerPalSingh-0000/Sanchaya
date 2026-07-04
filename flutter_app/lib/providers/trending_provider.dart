import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import 'service_providers.dart';

final trendingMoviesProvider = FutureProvider<List<Media>>((ref) async {
  final cacheService = ref.read(cacheServiceProvider);
  final cached = cacheService.getTrendingCache('movies');
  if (cached != null) {
    return (cached['data'] as List<dynamic>).map((e) => Media.fromJson(e)).toList();
  }

  final tmdbService = ref.read(tmdbServiceProvider);
  final movies = await tmdbService.getTrending(mediaType: 'movie', timeWindow: 'day');
  
  await cacheService.setTrendingCache('movies', {'data': movies.map((e) => e.toJson()).toList()});
  return movies;
});

final trendingTVProvider = FutureProvider<List<Media>>((ref) async {
  final cacheService = ref.read(cacheServiceProvider);
  final cached = cacheService.getTrendingCache('tv');
  if (cached != null) {
    return (cached['data'] as List<dynamic>).map((e) => Media.fromJson(e)).toList();
  }

  final tmdbService = ref.read(tmdbServiceProvider);
  final tv = await tmdbService.getTrending(mediaType: 'tv', timeWindow: 'day');
  
  await cacheService.setTrendingCache('tv', {'data': tv.map((e) => e.toJson()).toList()});
  return tv;
});

final trendingAnimeProvider = FutureProvider<List<Media>>((ref) async {
  final cacheService = ref.read(cacheServiceProvider);
  final cached = cacheService.getTrendingCache('anime');
  if (cached != null) {
    return (cached['data'] as List<dynamic>).map((e) => Media.fromJson(e)).toList();
  }

  final anilistService = ref.read(anilistServiceProvider);
  final anime = await anilistService.getTrendingAnime();
  
  await cacheService.setTrendingCache('anime', {'data': anime.map((e) => e.toJson()).toList()});
  return anime;
});
