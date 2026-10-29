

enum MediaType { movie, series, anime }

MediaType mediaTypeFromString(String value) {
  final normalized = value.toLowerCase().trim();
  switch (normalized) {
    case 'movie':
      return MediaType.movie;
    case 'series':
    case 'tv':
      return MediaType.series;
    case 'anime':
      return MediaType.anime;
    default:
      return MediaType.movie; // Safe fallback
  }
}

String mediaTypeToString(MediaType type) {
  switch (type) {
    case MediaType.movie:
      return 'movie';
    case MediaType.series:
      return 'tv'; // Changed to match Next.js website
    case MediaType.anime:
      return 'anime';
  }
}

enum MediaFilter { all, movie, series, anime }

enum WatchStatus { planToWatch, watching, completed, onHold, dropped }

WatchStatus watchStatusFromString(String value) {
  final normalized = value.toLowerCase().trim();
  switch (normalized) {
    case 'plan_to_watch':
    case 'plantowatch':
      return WatchStatus.planToWatch;
    case 'watching':
      return WatchStatus.watching;
    case 'completed':
    case 'copleted': // handle typo
      return WatchStatus.completed;
    case 'on_hold':
    case 'onhold':
      return WatchStatus.onHold;
    case 'dropped':
      return WatchStatus.dropped;
    default:
      return WatchStatus.planToWatch; // Safe fallback instead of throwing
  }
}

String watchStatusToString(WatchStatus status) {
  switch (status) {
    case WatchStatus.planToWatch:
      return 'plan_to_watch';
    case WatchStatus.watching:
      return 'watching';
    case WatchStatus.completed:
      return 'completed';
    case WatchStatus.onHold:
      return 'on_hold';
    case WatchStatus.dropped:
      return 'dropped';
  }
}

class Genre {
  final int id;
  final String name;

  Genre({
    required this.id,
    required this.name,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Media {
  final String id;
  final String externalId;
  final int? malId;
  final MediaType type;
  final String title;
  final String? originalTitle;
  final String? originCountry;
  final String overview;
  final String posterUrl;
  final String? backdropUrl;
  final List<Genre> genres;
  final double rating;
  final int voteCount;
  final String? releaseDate;
  final String status;
  final List<Season>? seasons;
  final int? totalEpisodes;
  final List<String>? studios;
  final String? trailer;
  final String? franchiseId;
  final String? franchiseTitle;
  final String? franchisePosterUrl;

  Media({
    required this.id,
    required this.externalId,
    this.malId,
    required this.type,
    required this.title,
    this.originalTitle,
    this.originCountry,
    required this.overview,
    required this.posterUrl,
    this.backdropUrl,
    required this.genres,
    required this.rating,
    required this.voteCount,
    this.releaseDate,
    required this.status,
    this.seasons,
    this.totalEpisodes,
    this.studios,
    this.trailer,
    this.franchiseId,
    this.franchiseTitle,
    this.franchisePosterUrl,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as String,
      externalId: json['externalId'] as String,
      malId: json['malId'] as int?,
      type: mediaTypeFromString(json['type'] as String),
      title: json['title'] as String,
      originalTitle: json['originalTitle'] as String?,
      originCountry: json['originCountry'] as String?,
      overview: json['overview'] as String,
      posterUrl: json['posterUrl'] as String,
      backdropUrl: json['backdropUrl'] as String?,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['voteCount'] as int? ?? 0,
      releaseDate: json['releaseDate'] as String?,
      status: json['status'] as String? ?? '',
      seasons: (json['seasons'] as List<dynamic>?)
          ?.map((e) => Season.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalEpisodes: json['totalEpisodes'] as int?,
      studios: (json['studios'] as List<dynamic>?)?.map((e) => e as String).toList(),
      trailer: json['trailer'] as String?,
      franchiseId: json['franchiseId'] as String?,
      franchiseTitle: json['franchiseTitle'] as String?,
      franchisePosterUrl: json['franchisePosterUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'externalId': externalId,
      if (malId != null) 'malId': malId,
      'type': mediaTypeToString(type),
      'title': title,
      if (originalTitle != null) 'originalTitle': originalTitle,
      if (originCountry != null) 'originCountry': originCountry,
      'overview': overview,
      'posterUrl': posterUrl,
      if (backdropUrl != null) 'backdropUrl': backdropUrl,
      'genres': genres.map((e) => e.toJson()).toList(),
      'rating': rating,
      'voteCount': voteCount,
      if (releaseDate != null) 'releaseDate': releaseDate,
      'status': status,
      if (seasons != null) 'seasons': seasons!.map((e) => e.toJson()).toList(),
      if (totalEpisodes != null) 'totalEpisodes': totalEpisodes,
      if (studios != null) 'studios': studios,
      if (trailer != null) 'trailer': trailer,
      if (franchiseId != null) 'franchiseId': franchiseId,
      if (franchiseTitle != null) 'franchiseTitle': franchiseTitle,
      if (franchisePosterUrl != null) 'franchisePosterUrl': franchisePosterUrl,
    };
  }
}

class Season {
  final int number;
  final String name;
  final int episodeCount;
  final String overview;
  final String? posterUrl;
  final String? airDate;
  final List<Episode>? episodes;
  final String? mediaId;
  final int? malId;
  final MediaType? mediaType;
  final String? format;
  final String? relationType;

  Season({
    required this.number,
    required this.name,
    required this.episodeCount,
    required this.overview,
    this.posterUrl,
    this.airDate,
    this.episodes,
    this.mediaId,
    this.malId,
    this.mediaType,
    this.format,
    this.relationType,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      number: json['number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      episodeCount: json['episodeCount'] as int? ?? 0,
      overview: json['overview'] as String? ?? '',
      posterUrl: json['posterUrl'] as String?,
      airDate: json['airDate'] as String?,
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaId: json['mediaId'] as String?,
      malId: json['malId'] as int?,
      mediaType: json['mediaType'] != null ? mediaTypeFromString(json['mediaType'] as String) : null,
      format: json['format'] as String?,
      relationType: json['relationType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'episodeCount': episodeCount,
      'overview': overview,
      if (posterUrl != null) 'posterUrl': posterUrl,
      if (airDate != null) 'airDate': airDate,
      if (episodes != null) 'episodes': episodes!.map((e) => e.toJson()).toList(),
      if (mediaId != null) 'mediaId': mediaId,
      if (malId != null) 'malId': malId,
      if (mediaType != null) 'mediaType': mediaTypeToString(mediaType!),
      if (format != null) 'format': format,
      if (relationType != null) 'relationType': relationType,
    };
  }
}

class StoryArc {
  final String name;
  final int start;
  final int end;
  final String? saga;

  StoryArc({
    required this.name,
    required this.start,
    required this.end,
    this.saga,
  });

  factory StoryArc.fromJson(Map<String, dynamic> json) {
    return StoryArc(
      name: json['name'] as String,
      start: json['start'] as int,
      end: json['end'] as int,
      saga: json['saga'] as String?,
    );
  }
}

class Episode {
  final int number;
  final String name;
  final String overview;
  final String? airDate;
  final String? stillUrl;
  final int? runtime;
  final double? rating;
  final bool? isFiller;
  final bool? isRecap;
  final String? arcName;
  final String? sagaName;

  Episode({
    required this.number,
    required this.name,
    required this.overview,
    this.airDate,
    this.stillUrl,
    this.runtime,
    this.rating,
    this.isFiller,
    this.isRecap,
    this.arcName,
    this.sagaName,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      number: json['number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      airDate: json['airDate'] as String?,
      stillUrl: json['stillUrl'] as String?,
      runtime: json['runtime'] as int?,
      rating: (json['rating'] as num?)?.toDouble(),
      isFiller: json['isFiller'] as bool?,
      isRecap: json['isRecap'] as bool?,
      arcName: json['arcName'] as String?,
      sagaName: json['sagaName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'overview': overview,
      if (airDate != null) 'airDate': airDate,
      if (stillUrl != null) 'stillUrl': stillUrl,
      if (runtime != null) 'runtime': runtime,
      if (rating != null) 'rating': rating,
      if (isFiller != null) 'isFiller': isFiller,
      if (isRecap != null) 'isRecap': isRecap,
      if (arcName != null) 'arcName': arcName,
      if (sagaName != null) 'sagaName': sagaName,
    };
  }
}
