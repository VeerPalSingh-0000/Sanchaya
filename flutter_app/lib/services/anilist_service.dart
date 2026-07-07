import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/media.dart';
import '../models/search_result.dart';

class AnilistService {
  final Dio _dio = Dio();

  AnilistService() {
    _dio.options.baseUrl = Constants.anilistGraphqlUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  static const String mediaFragment = '''
    fragment MediaFields on Media {
      id
      idMal
      title { romaji english native }
      description(asHtml: false)
      coverImage { extraLarge large medium color }
      bannerImage
      genres
      averageScore
      popularity
      format
      status
      episodes
      season
      seasonYear
      startDate { year month day }
      endDate { year month day }
      trailer { id site }
      nextAiringEpisode { episode airingAt }
    }
  ''';

  static const String mediaDetailFragment =
      '''
    fragment MediaDetailFields on Media {
      ...MediaFields
      studios { edges { isMain node { name } } }
      relations { edges { relationType node { id title { romaji english native } type format coverImage { extraLarge large medium color } bannerImage episodes averageScore } } }
      streamingEpisodes { title thumbnail url }
    }
    $mediaFragment
  ''';

  Future<T> _fetch<T>(
    String query, {
    Map<String, dynamic>? variables,
    int retries = 3,
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await _dio.post(
          '',
          data: {'query': query, 'variables': variables ?? {}},
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('errors') && (data['errors'] as List).isNotEmpty) {
          throw Exception((data['errors'] as List)[0]['message']);
        }
        return data['data'] as T;
      } on DioException catch (e) {
        if (i == retries - 1) rethrow;
        if (e.response?.statusCode == 429) {
          final retryAfter = e.response?.headers.value('Retry-After');
          final waitTime = retryAfter != null
              ? int.parse(retryAfter) * 1000
              : 2000;
          await Future.delayed(Duration(milliseconds: waitTime));
          continue;
        }
        await Future.delayed(Duration(milliseconds: 500 * pow(2, i).toInt()));
      }
    }
    throw Exception('AniList fetch failed after retries');
  }

  Genre _genreStringToGenre(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = ((hash << 5) - hash + name.codeUnitAt(i)) | 0;
    }
    return Genre(id: hash.abs(), name: name);
  }

  String _resolveTitle(Map<String, dynamic>? title) {
    if (title == null) return 'Unknown';
    return (title['english'] as String?) ??
        (title['romaji'] as String?) ??
        (title['native'] as String?) ??
        'Unknown';
  }

  String? _formatDate(Map<String, dynamic>? date) {
    if (date == null || date['year'] == null) return null;
    final y = date['year'];
    final m = (date['month'] as int?)?.toString().padLeft(2, '0') ?? '01';
    final d = (date['day'] as int?)?.toString().padLeft(2, '0') ?? '01';
    return '$y-$m-$d';
  }

  String _stripHtml(String? text) {
    if (text == null || text.isEmpty) return '';
    return text
        .replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  String _mapAniListStatus(String? status) {
    switch (status) {
      case 'FINISHED':
        return 'Ended';
      case 'RELEASING':
        return 'Airing';
      case 'NOT_YET_RELEASED':
        return 'Upcoming';
      case 'CANCELLED':
        return 'Cancelled';
      case 'HIATUS':
        return 'On Hiatus';
      default:
        return 'Unknown';
    }
  }

  String? _buildTrailerUrl(Map<String, dynamic>? trailer) {
    if (trailer == null) return null;
    if (trailer['site'] == 'youtube')
      return 'https://www.youtube.com/watch?v=${trailer['id']}';
    if (trailer['site'] == 'dailymotion')
      return 'https://www.dailymotion.com/video/${trailer['id']}';
    return null;
  }

  String _proxyUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('https://wsrv.nl') || url.contains('anilist.co')) return url;
    return 'https://wsrv.nl/?url=$url';
  }

  Media _mapAniListToMedia(Map<String, dynamic> anime) {
    final title = _resolveTitle(anime['title'] as Map<String, dynamic>?);
    final rawGenres = anime['genres'] as List<dynamic>? ?? [];
    final genres = rawGenres
        .map((e) => _genreStringToGenre(e as String))
        .toList();

    List<String>? studiosList;
    final studiosEdges = anime['studios']?['edges'] as List<dynamic>?;
    if (studiosEdges != null) {
      studiosList = studiosEdges
          .where((e) => e['isMain'] == true)
          .map((e) => e['node']['name'] as String)
          .toList();
    }

    return Media(
      id: 'anilist-${anime['id']}',
      externalId: anime['id'].toString(),
      malId: anime['idMal'] as int?,
      type: MediaType.anime,
      title: title,
      originalTitle: anime['title']?['native'] as String?,
      overview: _stripHtml(anime['description'] as String?),
      posterUrl: _proxyUrl(
          (anime['coverImage']?['extraLarge'] as String?) ??
          (anime['coverImage']?['large'] as String?) ??
          ''),
      backdropUrl: anime['bannerImage'] != null ? _proxyUrl(anime['bannerImage'] as String?) : null,
      genres: genres,
      rating: ((anime['averageScore'] as num?)?.toDouble() ?? 0) / 10,
      voteCount: anime['popularity'] as int? ?? 0,
      releaseDate: _formatDate(anime['startDate'] as Map<String, dynamic>?),
      status: _mapAniListStatus(anime['status'] as String?),
      totalEpisodes: anime['episodes'] as int?,
      studios: studiosList?.isNotEmpty == true ? studiosList : null,
      trailer: _buildTrailerUrl(anime['trailer'] as Map<String, dynamic>?),
    );
  }

  Future<SearchResult> searchAnime(
    String query, [
    int page = 1,
    int perPage = 20,
  ]) async {
    final String gqlQuery =
        '''
      query SearchAnime(\$query: String!, \$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo { total currentPage lastPage hasNextPage perPage }
          media(search: \$query, type: ANIME, sort: SEARCH_MATCH) { ...MediaFields studios { edges { isMain node { name } } } }
        }
      }
      $mediaFragment
    ''';

    try {
      final data = await _fetch<Map<String, dynamic>>(
        gqlQuery,
        variables: {'query': query, 'page': page, 'perPage': perPage},
      );
      final pageData = data['Page'] as Map<String, dynamic>;
      final pageInfo = pageData['pageInfo'] as Map<String, dynamic>;
      final mediaList = pageData['media'] as List<dynamic>;

      return SearchResult(
        results: mediaList
            .map((e) => _mapAniListToMedia(e as Map<String, dynamic>))
            .toList(),
        totalResults: pageInfo['total'] as int? ?? 0,
        totalPages: pageInfo['lastPage'] as int? ?? 0,
        page: pageInfo['currentPage'] as int? ?? 1,
      );
    } catch (e) {
      return SearchResult(results: [], totalResults: 0, totalPages: 0, page: 1);
    }
  }

  Future<SearchResult> discoverAnimeByGenres(List<String> genres, [int page = 1, int perPage = 20]) async {
    final String gqlQuery =
        '''
      query DiscoverAnime(\$genres: [String], \$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo { total currentPage lastPage hasNextPage perPage }
          media(genre_in: \$genres, type: ANIME, sort: SCORE_DESC) { ...MediaFields studios { edges { isMain node { name } } } }
        }
      }
      $mediaFragment
    ''';

    try {
      final data = await _fetch<Map<String, dynamic>>(
        gqlQuery,
        variables: {'genres': genres, 'page': page, 'perPage': perPage},
      );
      final pageData = data['Page'] as Map<String, dynamic>;
      final pageInfo = pageData['pageInfo'] as Map<String, dynamic>;
      final mediaList = pageData['media'] as List<dynamic>;

      return SearchResult(
        results: mediaList
            .map((e) => _mapAniListToMedia(e as Map<String, dynamic>))
            .toList(),
        totalResults: pageInfo['total'] as int? ?? 0,
        totalPages: pageInfo['lastPage'] as int? ?? 0,
        page: pageInfo['currentPage'] as int? ?? 1,
      );
    } catch (e) {
      return SearchResult(results: [], totalResults: 0, totalPages: 0, page: 1);
    }
  }

  Future<Media?> getAnimeDetails(String id) async {
    final String gqlQuery =
        '''
      query GetAnimeDetails(\$id: Int!) { Media(id: \$id, type: ANIME) { ...MediaDetailFields } }
      $mediaDetailFragment
    ''';

    try {
      final numericId = int.parse(id.replaceAll(RegExp(r'\D'), ''));
      final data = await _fetch<Map<String, dynamic>>(
        gqlQuery,
        variables: {'id': numericId},
      );
      return _mapAniListToMedia(data['Media'] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<Media>> getTrendingAnime([int page = 1, int perPage = 20]) async {
    final String gqlQuery =
        '''
      query TrendingAnime(\$page: Int, \$perPage: Int) { 
        Page(page: \$page, perPage: \$perPage) { 
          pageInfo { total currentPage lastPage hasNextPage perPage } 
          media(type: ANIME, sort: TRENDING_DESC) { ...MediaFields studios { edges { isMain node { name } } } } 
        } 
      }
      $mediaFragment
    ''';

    try {
      final data = await _fetch<Map<String, dynamic>>(
        gqlQuery,
        variables: {'page': page, 'perPage': perPage},
      );
      final mediaList = data['Page']['media'] as List<dynamic>;
      return mediaList
          .map((e) => _mapAniListToMedia(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Season>> getAnimeSeasons(String id) async {
    const String timelineNodeFragment = '''
      fragment TimelineNode on Media { id idMal title { romaji english native } type format coverImage { extraLarge large medium color } bannerImage episodes averageScore startDate { year month day } }
    ''';

    const String gql =
        '''
      $timelineNodeFragment query GetTimelineNode(\$id: Int!) { Media(id: \$id, type: ANIME) { ...TimelineNode relations { edges { relationType node { id type } } } } }
    ''';

    const String relationsQuery =
        '''
      $timelineNodeFragment query GetRelations(\$id_in: [Int]) { Page(page: 1, perPage: 50) { media(id_in: \$id_in, type: ANIME) { ...TimelineNode relations { edges { relationType node { id type } } } } } }
    ''';

    try {
      final numericId = int.parse(id.replaceAll(RegExp(r'\D'), ''));
      final validRelationTypes = [
        "CURRENT",
        "SEQUEL",
        "PREQUEL",
        "SIDE_STORY",
        "PARENT",
        "ALTERNATIVE",
        "SPIN_OFF",
        "ADAPTATION",
        "SUMMARY",
        "COMPILATION",
        "CONTAINS",
        "SOURCE",
      ];

      final Map<int, Map<String, dynamic>> allNodesMap = {};
      final List<Map<String, dynamic>> queue = [];
      final Set<int> visited = {};

      final initialData = await _fetch<Map<String, dynamic>>(
        gql,
        variables: {'id': numericId},
      );
      final rootMedia = initialData['Media'] as Map<String, dynamic>?;
      if (rootMedia == null) return [];

      allNodesMap[rootMedia['id'] as int] = {
        ...rootMedia,
        'relationType': 'CURRENT',
      };
      visited.add(rootMedia['id'] as int);

      final initialRelations =
          rootMedia['relations']?['edges'] as List<dynamic>? ?? [];
      for (final edge in initialRelations) {
        final node = edge['node'] as Map<String, dynamic>;
        final relType = edge['relationType'] as String;
        if (node['type'] == 'ANIME' &&
            validRelationTypes.contains(relType) &&
            !visited.contains(node['id'])) {
          queue.add({'id': node['id'], 'relType': relType});
        }
      }

      while (queue.isNotEmpty) {
        final batch = queue.take(50).toList();
        queue.removeRange(0, batch.length);
        final batchIds = batch.map((e) => e['id'] as int).toList();
        visited.addAll(batchIds);

        final batchData = await _fetch<Map<String, dynamic>>(
          relationsQuery,
          variables: {'id_in': batchIds},
        );
        final mediaItems = batchData['Page']?['media'] as List<dynamic>? ?? [];

        for (final mediaRaw in mediaItems) {
          final media = mediaRaw as Map<String, dynamic>;
          final mId = media['id'] as int;
          final queuedItem = batch.where((b) => b['id'] == mId).firstOrNull;
          final actualRelation = queuedItem != null
              ? queuedItem['relType'] as String
              : 'SEQUEL';

          if (!allNodesMap.containsKey(mId)) {
            allNodesMap[mId] = {...media, 'relationType': actualRelation};
          }

          final relations = media['relations']?['edges'] as List<dynamic>? ?? [];
          for (final edge in relations) {
            final node = edge['node'] as Map<String, dynamic>;
            final relType = edge['relationType'] as String;
            if (node['type'] == 'ANIME' &&
                validRelationTypes.contains(relType) &&
                !visited.contains(node['id'])) {
              queue.add({'id': node['id'], 'relType': relType});
            }
          }
        }
      }

      final allMediaInTimeline = allNodesMap.values.toList();

      final nodesForRoot = List<Map<String, dynamic>>.from(allMediaInTimeline);
      nodesForRoot.sort((a, b) {
        final aIsTV = a['format'] == 'TV' ? 0 : 1;
        final bIsTV = b['format'] == 'TV' ? 0 : 1;
        if (aIsTV != bIsTV) return aIsTV.compareTo(bIsTV);

        final dateA = a['startDate']?['year'] != null
            ? DateTime(
                a['startDate']['year'] as int,
                a['startDate']['month'] as int? ?? 1,
                a['startDate']['day'] as int? ?? 1,
              ).millisecondsSinceEpoch
            : 9007199254740991;
        final dateB = b['startDate']?['year'] != null
            ? DateTime(
                b['startDate']['year'] as int,
                b['startDate']['month'] as int? ?? 1,
                b['startDate']['day'] as int? ?? 1,
              ).millisecondsSinceEpoch
            : 9007199254740991;
        if (dateA != dateB) return dateA.compareTo(dateB);
        return (a['id'] as int).compareTo(b['id'] as int);
      });

      if (nodesForRoot.isNotEmpty) {
        final rootNode = nodesForRoot.first;
        final newRelationMap = <int, String>{};
        newRelationMap[rootNode['id'] as int] = 'CURRENT';

        final memQueue = <int>[rootNode['id'] as int];
        final memVisited = <int>{rootNode['id'] as int};

        while (memQueue.isNotEmpty) {
          final currentId = memQueue.removeAt(0);
          final currentNode = allNodesMap[currentId];
          if (currentNode == null) continue;

          final relations = currentNode['relations']?['edges'] as List<dynamic>? ?? [];
          for (final edge in relations) {
            final node = edge['node'] as Map<String, dynamic>;
            final relType = edge['relationType'] as String;
            final nodeId = node['id'] as int;

            if (node['type'] == 'ANIME' &&
                validRelationTypes.contains(relType) &&
                !memVisited.contains(nodeId)) {
              memVisited.add(nodeId);
              newRelationMap[nodeId] = relType;
              memQueue.add(nodeId);
            }
          }
        }

        for (final node in allMediaInTimeline) {
          final nodeId = node['id'] as int;
          node['relationType'] = newRelationMap[nodeId] ?? 'SEQUEL';
        }
      }

      final validMedia = allMediaInTimeline
          .where(
            (node) =>
                validRelationTypes.contains(node['relationType'] as String),
          )
          .toList();

      validMedia.sort((a, b) {
        final dateA = a['startDate']?['year'] != null
            ? DateTime(
                a['startDate']['year'] as int,
                a['startDate']['month'] as int? ?? 1,
                a['startDate']['day'] as int? ?? 1,
              ).millisecondsSinceEpoch
            : 9007199254740991;
        final dateB = b['startDate']?['year'] != null
            ? DateTime(
                b['startDate']['year'] as int,
                b['startDate']['month'] as int? ?? 1,
                b['startDate']['day'] as int? ?? 1,
              ).millisecondsSinceEpoch
            : 9007199254740991;
        if (dateA != dateB) return dateA.compareTo(dateB);
        return (a['id'] as int).compareTo(b['id'] as int);
      });

      int index = 1;
      return validMedia.map((node) {
        final relType = node['relationType'] as String;
        return Season(
          number: index++,
          name: _resolveTitle(node['title'] as Map<String, dynamic>?),
          episodeCount: node['episodes'] as int? ?? 0,
          overview: relType == 'CURRENT'
              ? 'Current Series'
              : '${relType.replaceAll('_', ' ')} - ${_resolveTitle(node['title'] as Map<String, dynamic>?)}',
          posterUrl: _proxyUrl(
              (node['coverImage']?['extraLarge'] as String?) ??
              (node['coverImage']?['large'] as String?)),
          mediaId: 'anilist-${node['id']}',
          malId: node['idMal'] as int?,
          mediaType: MediaType.anime,
          format: node['format'] as String?,
          relationType: relType,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Episode>> getAnimeEpisodes(int idMal) async {
    if (idMal <= 0) return [];
    
    List<StoryArc> animeArcs = [];

    try {
      final String arcDataString = await rootBundle.loadString(
        'assets/data/arc_data.json',
      );
      final List<dynamic> arcDataJson = json.decode(arcDataString);
      final animeArcJson = arcDataJson.firstWhere(
        (a) => a['anime_id'] == idMal,
        orElse: () => null,
      );

      animeArcs =
          (animeArcJson?['arcs'] as List<dynamic>?)
              ?.map((a) => StoryArc.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [];
    } catch (e) {
      print('Failed to load arc_data.json: $e');
    }



    try {
      List<dynamic> allEpisodes = [];
      int page = 1;
      bool hasNextPage = true;

      while (hasNextPage && page <= 30) {
        // limit to 30 pages (3000 eps) max to support long anime like One Piece
        try {
          final response = await _dio.get(
            'https://api.jikan.moe/v4/anime/$idMal/episodes?page=$page',
          );
          final data = response.data['data'] as List<dynamic>?;
          if (data == null) break;

          allEpisodes.addAll(data);
          hasNextPage = response.data['pagination']?['has_next_page'] ?? false;

          if (hasNextPage) {
            page++;
            await Future.delayed(const Duration(milliseconds: 350));
          }
        } catch (e) {
          if (e is DioException && e.response?.statusCode == 429) {
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
          break;
        }
      }

      return allEpisodes.map((epData) {
        final epId = epData['mal_id'] as int? ?? 0;
        final arc = animeArcs.cast<StoryArc?>().firstWhere(
          (a) => a != null && epId >= a.start && epId <= a.end,
          orElse: () => null,
        );
        return Episode(
          number: epId,
          name: epData['title'] as String? ?? '',
          overview: epData['title_japanese'] as String? ?? '',
          airDate: epData['aired'] as String?,
          isFiller: epData['filler'] as bool? ?? false,
          isRecap: epData['recap'] as bool? ?? false,
          arcName: arc?.name,
          sagaName: arc?.saga,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
