import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/media.dart';
import '../models/search_result.dart';

class TmdbService {
  final Dio _dio = Dio();

  TmdbService() {
    _dio.options.baseUrl = Constants.tmdbBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  static const Map<String, dynamic> imageSizes = {
    'poster': {
      'small': 'w185',
      'medium': 'w342',
      'large': 'w500',
      'original': 'original',
    },
    'backdrop': {
      'small': 'w300',
      'medium': 'w780',
      'large': 'w1280',
      'original': 'original',
    },
    'still': {
      'small': 'w185',
      'medium': 'w300',
      'large': 'w500',
      'original': 'original',
    },
  };

  static const Map<int, String> tmdbGenreMap = {
    28: 'Action', 12: 'Adventure', 16: 'Animation', 35: 'Comedy',
    80: 'Crime', 99: 'Documentary', 18: 'Drama', 10751: 'Family',
    14: 'Fantasy', 36: 'History', 27: 'Horror', 10402: 'Music',
    9648: 'Mystery', 10749: 'Romance', 878: 'Science Fiction',
    10770: 'TV Movie', 53: 'Thriller', 10752: 'War', 37: 'Western',
    10759: 'Action & Adventure', 10762: 'Kids', 10763: 'News',
    10764: 'Reality', 10765: 'Sci-Fi & Fantasy', 10766: 'Soap',
    10767: 'Talk', 10768: 'War & Politics',
  };

  int? getTmdbGenreIdByName(String name) {
    for (final entry in tmdbGenreMap.entries) {
      if (entry.value.toLowerCase() == name.toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }

  String getImageUrl(String? path, [String size = 'w342']) {
    if (path == null || path.isEmpty) return '';
    return '${Constants.tmdbImageBaseUrl}/$size$path';
  }

  List<Genre> _genreIdsToGenres(List<int>? ids) {
    if (ids == null) return [];
    return ids.map((id) => Genre(
      id: id,
      name: tmdbGenreMap[id] ?? 'Unknown',
    )).toList();
  }

  String? _findTrailerKey(List<dynamic>? results) {
    if (results == null || results.isEmpty) return null;
    
    final trailer = results.cast<Map<String, dynamic>>().cast<Map<String, dynamic>>().where(
      (v) => v['type'] == 'Trailer' && v['site'] == 'YouTube',
    ).firstOrNull;
    
    final teaser = results.cast<Map<String, dynamic>>().cast<Map<String, dynamic>>().where(
      (v) => v['type'] == 'Teaser' && v['site'] == 'YouTube',
    ).firstOrNull;
    
    final chosen = trailer ?? teaser;
    return chosen != null ? 'https://www.youtube.com/watch?v=${chosen['key']}' : null;
  }

  Future<T> _fetch<T>(String endpoint, {Map<String, dynamic>? params, int retries = 3}) async {
    final queryParams = {
      'api_key': Constants.tmdbApiKey,
      'language': 'en-US',
      ...?params,
    };

    for (int i = 0; i < retries; i++) {
      try {
        final response = await _dio.get<T>(endpoint, queryParameters: queryParams).timeout(const Duration(seconds: 10));
        return response.data as T;
      } on DioException catch (e) {
        if (i == retries - 1) rethrow;
        if (e.response?.statusCode == 404) rethrow;
        if (e.type == DioExceptionType.connectionError || 
            e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.unknown || 
            e.error.toString().contains('SocketException')) {
          rethrow; // Fail fast on no internet
        }
        
        final jitter = Random().nextDouble() * 300;
        final waitTime = (500 * pow(2, i)) + jitter;
        await Future.delayed(Duration(milliseconds: waitTime.toInt()));
      } catch (e) {
        if (i == retries - 1) rethrow;
        if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
          rethrow;
        }
        final jitter = Random().nextDouble() * 300;
        final waitTime = (500 * pow(2, i)) + jitter;
        await Future.delayed(Duration(milliseconds: waitTime.toInt()));
      }
    }
    throw Exception('TMDb fetch failed after retries');
  }

  Media _mapMovieToMedia(Map<String, dynamic> movie) {
    final rawGenres = movie['genres'] as List<dynamic>?;
    final genres = rawGenres != null
        ? rawGenres.map((g) => Genre(id: g['id'] as int, name: g['name'] as String)).toList()
        : _genreIdsToGenres((movie['genre_ids'] as List<dynamic>?)?.map((e) => e as int).toList());

    final collection = movie['belongs_to_collection'] as Map<String, dynamic>?;

    return Media(
      id: 'tmdb-movie-${movie['id']}',
      externalId: movie['id'].toString(),
      type: MediaType.movie,
      title: movie['title'] as String? ?? 'Unknown',
      originalTitle: movie['original_title'] as String?,
      originCountry: (movie['origin_country'] as List<dynamic>?)?.firstOrNull as String?,
      overview: movie['overview'] as String? ?? '',
      posterUrl: getImageUrl(movie['poster_path'] as String?),
      backdropUrl: movie['backdrop_path'] != null ? getImageUrl(movie['backdrop_path'] as String?, 'w1280') : null,
      genres: genres,
      rating: (double.tryParse(movie['vote_average']?.toString() ?? '') ?? 0) * 10 / 10,
      voteCount: int.tryParse(movie['vote_count']?.toString() ?? '') ?? 0,
      releaseDate: movie['release_date'] as String?,
      status: movie['status'] as String? ?? 'Released',
      studios: (movie['production_companies'] as List<dynamic>?)
          ?.map((c) => c['name']?.toString() ?? 'Unknown')
          .toList(),
      trailer: _findTrailerKey(movie['videos']?['results'] as List<dynamic>?),
      franchiseId: collection != null ? 'tmdb-collection-${collection['id']}' : null,
      franchiseTitle: collection != null ? collection['name'] as String? : null,
      franchisePosterUrl: collection != null ? getImageUrl(collection['poster_path'] as String?) : null,
    );
  }

  Media _mapTVToMedia(Map<String, dynamic> tv) {
    final rawGenres = tv['genres'] as List<dynamic>?;
    final genres = rawGenres != null
        ? rawGenres.map((g) => Genre(id: g['id'] as int, name: g['name'] as String)).toList()
        : _genreIdsToGenres((tv['genre_ids'] as List<dynamic>?)?.map((e) => e as int).toList());

    final rawSeasons = tv['seasons'] as List<dynamic>?;
    final seasons = rawSeasons?.map((s) => Season(
      number: int.tryParse(s['season_number']?.toString() ?? '') ?? 0,
      name: s['name'] as String? ?? '',
      episodeCount: int.tryParse(s['episode_count']?.toString() ?? '') ?? 0,
      overview: s['overview'] as String? ?? '',
      posterUrl: s['poster_path'] != null ? getImageUrl(s['poster_path'] as String?, 'w342') : null,
      airDate: s['air_date'] as String?,
      mediaId: '${tv['id']}-season-${s['season_number']}',
      mediaType: MediaType.series,
    )).toList();

    final studios = <String>[];
    studios.addAll((tv['production_companies'] as List<dynamic>?)?.map(
            (c) => c['name']?.toString() ?? 'Unknown',
          ) ?? []);
    studios.addAll(
      (tv['networks'] as List<dynamic>?)?.map((n) => n['name']?.toString() ?? 'Unknown') ?? [],
    );

    return Media(
      id: 'tmdb-tv-${tv['id']}',
      externalId: tv['id'].toString(),
      type: MediaType.series,
      title: tv['name'] as String? ?? 'Unknown',
      originalTitle: tv['original_name'] as String?,
      originCountry: (tv['origin_country'] as List<dynamic>?)?.firstOrNull as String?,
      overview: tv['overview'] as String? ?? '',
      posterUrl: getImageUrl(tv['poster_path'] as String?),
      backdropUrl: tv['backdrop_path'] != null ? getImageUrl(tv['backdrop_path'] as String?, 'w1280') : null,
      genres: genres,
      rating: (double.tryParse(tv['vote_average']?.toString() ?? '') ?? 0) * 10 / 10,
      voteCount: int.tryParse(tv['vote_count']?.toString() ?? '') ?? 0,
      releaseDate: tv['first_air_date'] as String?,
      status: tv['status'] as String? ?? 'Unknown',
      seasons: seasons,
      totalEpisodes: int.tryParse(tv['number_of_episodes']?.toString() ?? ''),
      studios: studios,
      trailer: _findTrailerKey(tv['videos']?['results'] as List<dynamic>?),
      franchiseId: 'tmdb-tv-${tv['id']}',
      franchiseTitle: tv['name'] as String? ?? 'Unknown',
      franchisePosterUrl: getImageUrl(tv['poster_path'] as String?),
    );
  }

  Media? _mapMultiResultToMedia(Map<String, dynamic> item) {
    if (item['media_type'] == 'person') return null;

    final genres = _genreIdsToGenres((item['genre_ids'] as List<dynamic>?)?.map((e) => e as int).toList());

    if (item['media_type'] == 'movie') {
      return Media(
        id: 'tmdb-movie-${item['id']}',
        externalId: item['id'].toString(),
        type: MediaType.movie,
        title: item['title'] as String? ?? 'Unknown',
        originalTitle: item['original_title'] as String?,
        originCountry: (item['origin_country'] as List<dynamic>?)?.firstOrNull as String?,
        overview: item['overview'] as String? ?? '',
        posterUrl: getImageUrl(item['poster_path'] as String?),
        backdropUrl: item['backdrop_path'] != null ? getImageUrl(item['backdrop_path'] as String?, 'w1280') : null,
        genres: genres,
        rating: (double.tryParse(item['vote_average']?.toString() ?? '') ?? 0) * 10 / 10,
        voteCount: int.tryParse(item['vote_count']?.toString() ?? '') ?? 0,
        releaseDate: item['release_date'] as String?,
        status: 'Released',
      );
    }

    return Media(
      id: 'tmdb-tv-${item['id']}',
      externalId: item['id'].toString(),
      type: MediaType.series,
      title: item['name'] as String? ?? 'Unknown',
      originalTitle: item['original_name'] as String?,
      originCountry: (item['origin_country'] as List<dynamic>?)?.firstOrNull as String?,
      overview: item['overview'] as String? ?? '',
      posterUrl: getImageUrl(item['poster_path'] as String?),
      backdropUrl: item['backdrop_path'] != null ? getImageUrl(item['backdrop_path'] as String?, 'w1280') : null,
      genres: genres,
      rating: (double.tryParse(item['vote_average']?.toString() ?? '') ?? 0) * 10 / 10,
      voteCount: int.tryParse(item['vote_count']?.toString() ?? '') ?? 0,
      releaseDate: item['first_air_date'] as String?,
      status: 'Unknown',
      franchiseId: 'tmdb-tv-${item['id']}',
      franchiseTitle: item['name'] as String? ?? 'Unknown',
      franchisePosterUrl: getImageUrl(item['poster_path'] as String?),
    );
  }

  Season _mapSeasonDetail(Map<String, dynamic> detail) {
    final episodes = (detail['episodes'] as List<dynamic>?)?.map((ep) => Episode(
      number: ep['episode_number'] as int? ?? 0,
      name: ep['name'] as String? ?? '',
      overview: ep['overview'] as String? ?? '',
      airDate: ep['air_date'] as String?,
      stillUrl: ep['still_path'] != null ? getImageUrl(ep['still_path'] as String?, 'w300') : null,
      runtime: ep['runtime'] as int?,
      rating: ((ep['vote_average'] as num?)?.toDouble() ?? 0) * 10 / 10,
    )).toList();

    return Season(
      number: detail['season_number'] as int? ?? 0,
      name: detail['name'] as String? ?? '',
      episodeCount: episodes?.length ?? 0,
      overview: detail['overview'] as String? ?? '',
      posterUrl: detail['poster_path'] != null ? getImageUrl(detail['poster_path'] as String?, 'w342') : null,
      airDate: detail['air_date'] as String?,
      episodes: episodes,
    );
  }



  Future<SearchResult> discoverByGenre(int genreId, [int page = 1]) async {
    try {
      final data = await _fetch<Map<String, dynamic>>('/discover/movie', params: {
        'with_genres': genreId,
        'page': page,
        'sort_by': 'popularity.desc',
      });
      final results = (data['results'] as List<dynamic>)
          .map((e) => _mapMovieToMedia(e as Map<String, dynamic>))
          .toList();
      return SearchResult(
        results: results,
        totalResults: data['total_results'] as int? ?? 0,
        totalPages: data['total_pages'] as int? ?? 0,
        page: data['page'] as int? ?? 1,
      );
    } catch (e) {
      return SearchResult(results: [], totalResults: 0, totalPages: 0, page: 1);
    }
  }

  Future<SearchResult> searchMulti(String query, [int page = 1]) async {
    try {
      final data = await _fetch<Map<String, dynamic>>('/search/multi', params: {'query': query, 'page': page});
      final results = (data['results'] as List<dynamic>)
          .map((e) => _mapMultiResultToMedia(e as Map<String, dynamic>))
          .where((m) => m != null)
          .cast<Media>()
          .toList();
      return SearchResult(
        results: results,
        totalResults: data['total_results'] as int? ?? 0,
        totalPages: data['total_pages'] as int? ?? 0,
        page: data['page'] as int? ?? 1,
      );
    } catch (e) {
      return SearchResult(results: [], totalResults: 0, totalPages: 0, page: 1);
    }
  }

  Future<SearchResult> searchMovies(String query, [int page = 1]) async {
    try {
      final data = await _fetch<Map<String, dynamic>>('/search/movie', params: {'query': query, 'page': page});
      final results = (data['results'] as List<dynamic>).map((e) => _mapMovieToMedia(e as Map<String, dynamic>)).toList();
      return SearchResult(
        results: results,
        totalResults: data['total_results'] as int? ?? 0,
        totalPages: data['total_pages'] as int? ?? 0,
        page: data['page'] as int? ?? 1,
      );
    } catch (e) {
      return SearchResult(results: [], totalResults: 0, totalPages: 0, page: 1);
    }
  }

  Future<SearchResult> searchTV(String query, [int page = 1]) async {
    try {
      final data = await _fetch<Map<String, dynamic>>('/search/tv', params: {'query': query, 'page': page});
      final results = (data['results'] as List<dynamic>).map((e) => _mapTVToMedia(e as Map<String, dynamic>)).toList();
      return SearchResult(
        results: results,
        totalResults: data['total_results'] as int? ?? 0,
        totalPages: data['total_pages'] as int? ?? 0,
        page: data['page'] as int? ?? 1,
      );
    } catch (e) {
      return SearchResult(results: [], totalResults: 0, totalPages: 0, page: 1);
    }
  }

  Future<Media?> getMovieDetails(String id) async {
    final cleanId = id.replaceAll('tmdb-movie-', '');
    try {
      final data = await _fetch<Map<String, dynamic>>('/movie/$cleanId', params: {'append_to_response': 'videos'});
      return _mapMovieToMedia(data);
    } catch (e, st) {
      debugPrint('[TMDB] getMovieDetails error: $e\n$st');
      rethrow;
    }
  }

  Future<List<Media>> getCollection(String id) async {
    final cleanId = id.replaceAll('tmdb-collection-', '');
    try {
      final data = await _fetch<Map<String, dynamic>>('/collection/$cleanId');
      final parts = data['parts'] as List<dynamic>?;
      if (parts == null) return [];
      
      final collectionId = 'tmdb-collection-${data['id']}';
      final collectionName = data['name'] as String?;
      final collectionPoster = getImageUrl(data['poster_path'] as String?);

      return parts.map((p) {
        final movie = _mapMovieToMedia(p as Map<String, dynamic>);
        return Media(
          id: movie.id,
          externalId: movie.externalId,
          type: MediaType.movie,
          title: movie.title,
          originalTitle: movie.originalTitle,
          originCountry: movie.originCountry,
          overview: movie.overview,
          posterUrl: movie.posterUrl,
          backdropUrl: movie.backdropUrl,
          genres: movie.genres,
          rating: movie.rating,
          voteCount: movie.voteCount,
          releaseDate: movie.releaseDate,
          status: movie.status,
          studios: movie.studios,
          trailer: movie.trailer,
          franchiseId: collectionId,
          franchiseTitle: collectionName,
          franchisePosterUrl: collectionPoster,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Media?> getTVDetails(String id) async {
    String cleanId = id.replaceAll('tmdb-tv-', '').replaceAll('tmdb-movie-', '');
    final match = RegExp(r'^(\d+)-season-(\d+)$').firstMatch(cleanId);
    String showId = cleanId;
    int? seasonNumber;

    if (match != null) {
      showId = match.group(1)!;
      seasonNumber = int.tryParse(match.group(2)!);
    }

    try {
      final data = await _fetch<Map<String, dynamic>>('/tv/$showId', params: {'append_to_response': 'videos'});
      final media = _mapTVToMedia(data);

      if (seasonNumber != null && media.seasons != null) {
        final season = media.seasons!.where((s) => s.number == seasonNumber).firstOrNull;
        if (season != null) {
          return Media(
            id: 'tmdb-tv-$showId-season-$seasonNumber',
            externalId: '$showId-season-$seasonNumber',
            type: MediaType.series,
            title: '${media.title}: ${season.name}',
            overview: season.overview.isNotEmpty ? season.overview : media.overview,
            posterUrl: season.posterUrl ?? media.posterUrl,
            genres: media.genres,
            rating: media.rating,
            voteCount: media.voteCount,
            status: media.status,
            totalEpisodes: season.episodeCount,
            franchiseId: 'tmdb-tv-$showId',
            franchiseTitle: media.title,
            franchisePosterUrl: media.posterUrl,
          );
        }
      }
      return media;
    } catch (e, st) {
      debugPrint('[TMDB] getTVDetails error: $e\n$st');
      rethrow;
    }
  }

  Future<Season?> getTVSeasonDetails(String tvId, int seasonNumber) async {
    final cleanId = tvId.replaceAll('tmdb-tv-', '');
    try {
      final data = await _fetch<Map<String, dynamic>>('/tv/$cleanId/season/$seasonNumber');
      return _mapSeasonDetail(data);
    } catch (e, st) {
      debugPrint('[TMDB] getTVSeasonDetails error: $e\n$st');
      rethrow;
    }
  }

  Future<List<Media>> getTrending({String mediaType = 'all', String timeWindow = 'week', int page = 1}) async {
    try {
      final data = await _fetch<Map<String, dynamic>>('/trending/$mediaType/$timeWindow', params: {'page': page});
      final results = (data['results'] as List<dynamic>).map((item) {
        final enriched = Map<String, dynamic>.from(item as Map<String, dynamic>);
        enriched['media_type'] ??= mediaType;
        return _mapMultiResultToMedia(enriched);
      }).where((m) => m != null).cast<Media>().toList();
      return results;
    } catch (e) {
      throw Exception('Failed to fetch trending media: $e');
    }
  }

  Future<List<Media>> getSimilar(String id, MediaType type) async {
    final cleanId = id.replaceAll(RegExp(r'tmdb-(movie|tv)-'), '');
    final isMovie = type == MediaType.movie;
    
    try {
      // 1. Fetch basic details to get language, genres, and release date
      final detailsEndpoint = isMovie ? '/movie/$cleanId' : '/tv/$cleanId';
      final detailsData = await _fetch<Map<String, dynamic>>(detailsEndpoint);
      
      final originalLang = detailsData['original_language'] as String?;
      final genres = detailsData['genres'] as List<dynamic>?;
      final releaseDateStr = isMovie
          ? detailsData['release_date'] as String?
          : detailsData['first_air_date'] as String?;
      
      final isNonEnglish = originalLang != null && originalLang != 'en';
      
      // Parse release year for era-based filtering
      int? releaseYear;
      if (releaseDateStr != null && releaseDateStr.length >= 4) {
        releaseYear = int.tryParse(releaseDateStr.substring(0, 4));
      }

      // 2. Try TMDB's /similar endpoint first — it uses content-based matching
      //    which is the best signal for finding genuinely similar titles.
      final simEndpoint = isMovie ? '/movie/$cleanId/similar' : '/tv/$cleanId/similar';
      try {
        final simData = await _fetch<Map<String, dynamic>>(simEndpoint);
        var simResults = (simData['results'] as List<dynamic>)
            .where((item) => item['id'].toString() != cleanId)
            .toList();
        
        // For non-English titles, prefer same-language results from /similar
        if (isNonEnglish && simResults.isNotEmpty) {
          final sameLangResults = simResults
              .where((item) => item['original_language'] == originalLang)
              .toList();
          // Use same-language results if we have enough (≥3), otherwise keep all
          if (sameLangResults.length >= 3) {
            simResults = sameLangResults;
          }
        }
        
        if (simResults.isNotEmpty) {
          return simResults
              .map((item) => isMovie
                  ? _mapMovieToMedia(item as Map<String, dynamic>)
                  : _mapTVToMedia(item as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('[TMDB] /similar failed for $cleanId, trying alternatives: $e');
      }
      
      // 3. For non-English titles, use discover with language + genre + era constraints.
      //    This avoids returning new blockbusters for old classics.
      if (isNonEnglish) {
        final genreIds = genres?.take(2).map((g) => g['id']).join('|') ?? '';
        final discoverEndpoint = isMovie ? '/discover/movie' : '/discover/tv';
        final params = <String, dynamic>{
          'with_original_language': originalLang,
          'sort_by': 'vote_average.desc',
          'vote_count.gte': 10,
        };
        if (genreIds.isNotEmpty) {
          params['with_genres'] = genreIds;
        }
        
        // Add era-based date window so old classics get similar-era recommendations
        if (releaseYear != null) {
          final currentYear = DateTime.now().year;
          // Wider window for older movies (±15yr), narrower for recent ones (±10yr)
          final yearSpan = releaseYear < (currentYear - 30) ? 15 : 10;
          final dateKey = isMovie ? 'primary_release_date' : 'first_air_date';
          params['$dateKey.gte'] = '${releaseYear - yearSpan}-01-01';
          params['$dateKey.lte'] = '${releaseYear + yearSpan}-12-31';
        }
        
        try {
          final discoverData = await _fetch<Map<String, dynamic>>(discoverEndpoint, params: params);
          final results = (discoverData['results'] as List<dynamic>)
              .where((item) => item['id'].toString() != cleanId)
              .map((item) => isMovie
                  ? _mapMovieToMedia(item as Map<String, dynamic>)
                  : _mapTVToMedia(item as Map<String, dynamic>))
              .toList();
              
          if (results.isNotEmpty) return results;
        } catch (e) {
          debugPrint('[TMDB] discover fallback failed for $cleanId: $e');
        }
      }
      
      // 4. Fallback to /recommendations endpoint
      final recEndpoint = isMovie ? '/movie/$cleanId/recommendations' : '/tv/$cleanId/recommendations';
      final recData = await _fetch<Map<String, dynamic>>(recEndpoint);
      var results = (recData['results'] as List<dynamic>)
          .where((item) => item['id'].toString() != cleanId)
          .toList();
      
      // For non-English, filter recommendations to same language
      if (isNonEnglish && results.isNotEmpty) {
        final sameLangResults = results
            .where((item) => item['original_language'] == originalLang)
            .toList();
        if (sameLangResults.isNotEmpty) {
          results = sameLangResults;
        }
      }
      
      return results
          .map((item) => isMovie
              ? _mapMovieToMedia(item as Map<String, dynamic>)
              : _mapTVToMedia(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[TMDB] getSimilar error: $e');
      return [];
    }
  }

  Future<SearchResult> discoverByGenres(String mediaType, List<int> genreIds, [int page = 1]) async {
    try {
      final endpoint = mediaType == 'movie' ? '/discover/movie' : '/discover/tv';
      final data = await _fetch<Map<String, dynamic>>(endpoint, params: {
        'with_genres': genreIds.join(','),
        'sort_by': 'vote_average.desc',
        'vote_count.gte': 100,
        'page': page,
      });

      final results = (data['results'] as List<dynamic>).map((item) {
        if (mediaType == 'movie') {
          return _mapMovieToMedia(item as Map<String, dynamic>);
        }
        return _mapTVToMedia(item as Map<String, dynamic>);
      }).toList();

      return SearchResult(
        results: results,
        totalResults: data['total_results'] as int? ?? 0,
        totalPages: data['total_pages'] as int? ?? 0,
        page: data['page'] as int? ?? 1,
      );
    } catch (e) {
      return SearchResult(results: [], totalResults: 0, totalPages: 0, page: 1);
    }
  }

  Future<List<Season>?> getCollectionDetails(String id) async {
    final cleanId = id.replaceAll('tmdb-collection-', '');
    try {
      final data = await _fetch<Map<String, dynamic>>('/collection/$cleanId');
      final parts = data['parts'] as List<dynamic>? ?? [];
      
      parts.sort((a, b) {
        final dateA = a['release_date'] as String?;
        final dateB = b['release_date'] as String?;
        final timeA = dateA != null && dateA.isNotEmpty ? DateTime.tryParse(dateA)?.millisecondsSinceEpoch : null;
        final timeB = dateB != null && dateB.isNotEmpty ? DateTime.tryParse(dateB)?.millisecondsSinceEpoch : null;
        final finalA = timeA ?? 9007199254740991; // JS MAX_SAFE_INTEGER approximation
        final finalB = timeB ?? 9007199254740991;
        return finalA.compareTo(finalB);
      });

      int index = 1;
      return parts.map((part) => Season(
        number: index++,
        name: part['title'] as String? ?? '',
        episodeCount: 0,
        overview: part['overview'] as String? ?? '',
        posterUrl: part['poster_path'] != null ? getImageUrl(part['poster_path'] as String?, 'w342') : null,
        airDate: part['release_date'] as String?,
        mediaId: 'tmdb-movie-${part['id']}',
        mediaType: MediaType.movie,
      )).toList();
    } catch (e) {
      return null;
    }
  }
}
