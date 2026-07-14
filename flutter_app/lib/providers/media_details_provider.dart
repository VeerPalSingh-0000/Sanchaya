import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import 'service_providers.dart';

/// Normalizes a media ID to a clean, valid format.
/// Fixes: double prefixes (anilist-anilist-), season suffixes, empty IDs.
String normalizeMediaId(String rawId) {
  String id = rawId.trim();

  // Fix double prefixes: anilist-anilist-12345 → anilist-12345
  while (id.startsWith('anilist-anilist-')) {
    id = id.replaceFirst('anilist-', '');
  }
  while (id.startsWith('tmdb-movie-tmdb-movie-')) {
    id = id.replaceFirst('tmdb-movie-', '');
  }
  while (id.startsWith('tmdb-tv-tmdb-tv-')) {
    id = id.replaceFirst('tmdb-tv-', '');
  }

  // Strip season suffix: tmdb-tv-71446-season-1 → tmdb-tv-71446
  if (id.contains('-season-')) {
    id = id.split('-season-').first;
  }

  return id;
}

final mediaDetailsProvider = FutureProvider.family<Media?, String>((ref, rawId) async {
  final id = normalizeMediaId(rawId);

  // Skip empty or invalid IDs
  if (id.isEmpty || id == 'tmdb-movie-' || id == 'tmdb-tv-' || id == 'anilist-') {
    debugPrint('[MediaDetails] Skipping invalid ID: "$rawId"');
    return null;
  }

  final cacheService = ref.read(cacheServiceProvider);
  final cacheKey = 'media_detail_$id';
  final cached = cacheService.getMediaDetailsCache(cacheKey);
  
  if (cached != null) {
    return Media.fromJson(cached);
  }

  Media? media;
  List<Season>? seasons;
  bool isAnime = false;

  final tmdbService = ref.read(tmdbServiceProvider);
  final anilistService = ref.read(anilistServiceProvider);

  try {
    if (id.startsWith('anilist-')) {

      isAnime = true;
      media = await anilistService.getAnimeDetails(id);
      seasons = await anilistService.getAnimeSeasons(id);
    } else if (id.startsWith('tmdb-tv-')) {
      media = await tmdbService.getTVDetails(id);
      
      if (media != null && media.originCountry == 'JP' && media.genres.any((g) => g.name == 'Animation')) {
        isAnime = true;
        try {
          final animeMatch = await anilistService.searchAnime(media.originalTitle ?? media.title, 1, 1);
          if (animeMatch.results.isNotEmpty) {
            seasons = await anilistService.getAnimeSeasons(animeMatch.results.first.externalId);
            final malId = animeMatch.results.first.malId;
            media = Media(
              id: media.id,
              externalId: media.externalId,
              malId: malId ?? media.malId,
              type: media.type,
              title: media.title,
              originalTitle: media.originalTitle,
              originCountry: media.originCountry,
              overview: media.overview,
              posterUrl: media.posterUrl,
              backdropUrl: media.backdropUrl,
              genres: media.genres,
              rating: media.rating,
              voteCount: media.voteCount,
              releaseDate: media.releaseDate,
              status: media.status,
              seasons: media.seasons,
              totalEpisodes: media.totalEpisodes,
              studios: media.studios,
              trailer: media.trailer,
              franchiseId: media.franchiseId,
              franchiseTitle: media.franchiseTitle,
              franchisePosterUrl: media.franchisePosterUrl,
            );
          }
        } catch (e) {
          debugPrint('[MediaDetails] Error fetching Anilist info for TMDB Anime TV $id: $e');
        }
      }

      if ((!isAnime || seasons == null || seasons.isEmpty) && media?.seasons != null && media!.seasons!.isNotEmpty) {
        final sortedSeasons = List<Season>.from(media.seasons!)
          ..sort((a, b) {
            if (a.number == 0) return 1;
            if (b.number == 0) return -1;
            return a.number.compareTo(b.number);
          });
        
        try {
          final firstSeason = await tmdbService.getTVSeasonDetails(id, sortedSeasons.first.number);
          if (firstSeason != null) {
            seasons = [firstSeason, ...sortedSeasons.skip(1)];
          } else {
            seasons = sortedSeasons;
          }
        } catch (e) {
          seasons = sortedSeasons;
        }
      }

    } else {
      media = await tmdbService.getMovieDetails(id);
      
      if (media != null && media.originCountry == 'JP' && media.genres.any((g) => g.name == 'Animation')) {
        isAnime = true;
        try {
          final animeMatch = await anilistService.searchAnime(media.originalTitle ?? media.title, 1, 1);
          if (animeMatch.results.isNotEmpty) {
            seasons = await anilistService.getAnimeSeasons(animeMatch.results.first.externalId);
            final malId = animeMatch.results.first.malId;
            media = Media(
              id: media.id,
              externalId: media.externalId,
              malId: malId ?? media.malId,
              type: media.type,
              title: media.title,
              originalTitle: media.originalTitle,
              originCountry: media.originCountry,
              overview: media.overview,
              posterUrl: media.posterUrl,
              backdropUrl: media.backdropUrl,
              genres: media.genres,
              rating: media.rating,
              voteCount: media.voteCount,
              releaseDate: media.releaseDate,
              status: media.status,
              seasons: media.seasons,
              totalEpisodes: media.totalEpisodes,
              studios: media.studios,
              trailer: media.trailer,
              franchiseId: media.franchiseId,
              franchiseTitle: media.franchiseTitle,
              franchisePosterUrl: media.franchisePosterUrl,
            );
          }
        } catch (e) {
          debugPrint('[MediaDetails] Error fetching Anilist info for TMDB Anime $id: $e');
        }
      } else if (media != null && media.franchiseId != null && media.franchiseId!.startsWith('tmdb-collection-')) {
        try {
          final collectionMedia = await tmdbService.getCollection(media.franchiseId!);
          seasons = collectionMedia.asMap().entries.map((e) => Season(
            number: e.key + 1,
            name: e.value.title,
            episodeCount: 1,
            overview: e.value.overview,
            posterUrl: e.value.posterUrl,
            airDate: e.value.releaseDate,
            mediaId: e.value.id,
            mediaType: MediaType.movie,
          )).toList();
        } catch (e) {
          debugPrint('[MediaDetails] Error fetching TMDB collection for $id: $e');
        }
      }
    }

    if (media != null) {
      String? franchiseId = media.franchiseId;
      String? franchiseTitle = media.franchiseTitle;
      String? franchisePosterUrl = media.franchisePosterUrl;

      if (seasons != null && seasons.isNotEmpty && (isAnime || media.type == MediaType.anime)) {
        franchiseId = seasons.first.mediaId ?? media.id;
        franchiseTitle = seasons.first.name;
        franchisePosterUrl = seasons.first.posterUrl ?? media.posterUrl;
      }

      media = Media(
        id: media.id,
        externalId: media.externalId,
        malId: media.malId,
        type: media.type,
        title: media.title,
        originalTitle: media.originalTitle,
        originCountry: media.originCountry,
        overview: media.overview,
        posterUrl: media.posterUrl,
        backdropUrl: media.backdropUrl,
        genres: media.genres,
        rating: media.rating,
        voteCount: media.voteCount,
        releaseDate: media.releaseDate,
        status: media.status,
        seasons: seasons ?? media.seasons,
        totalEpisodes: media.totalEpisodes,
        studios: media.studios,
        trailer: media.trailer,
        franchiseId: franchiseId,
        franchiseTitle: franchiseTitle,
        franchisePosterUrl: franchisePosterUrl,
      );
      
      await cacheService.setMediaDetailsCache(cacheKey, media.toJson());
    }
  } catch (e, st) {
    debugPrint('[MediaDetails] Error fetching details for $id: $e');
    debugPrint(st.toString());
    rethrow;
  }

  return media;
});
