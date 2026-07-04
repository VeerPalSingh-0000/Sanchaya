import 'media.dart';

enum Reaction { love, good, bad }

Reaction reactionFromString(String value) {
  switch (value.toUpperCase()) {
    case 'LOVE':
      return Reaction.love;
    case 'GOOD':
      return Reaction.good;
    case 'BAD':
      return Reaction.bad;
    default:
      throw Exception('Unknown Reaction: $value');
  }
}

String reactionToString(Reaction reaction) {
  switch (reaction) {
    case Reaction.love:
      return 'LOVE';
    case Reaction.good:
      return 'GOOD';
    case Reaction.bad:
      return 'BAD';
  }
}

class WatchlistItem {
  final String id;
  final String externalId;
  final MediaType mediaType;
  final String title;
  final String posterUrl;
  final String? backdropUrl;
  final List<Genre> genres;
  final double rating;
  final WatchStatus status;
  final int? progress;
  final int? totalEpisodes;
  final DateTime addedAt;
  final DateTime updatedAt;
  final String? franchiseId;
  final String? franchiseTitle;
  final String? franchisePosterUrl;
  final String? releaseDate;
  final Reaction? reaction;

  WatchlistItem({
    required this.id,
    required this.externalId,
    required this.mediaType,
    required this.title,
    required this.posterUrl,
    this.backdropUrl,
    required this.genres,
    required this.rating,
    required this.status,
    this.progress,
    this.totalEpisodes,
    required this.addedAt,
    required this.updatedAt,
    this.franchiseId,
    this.franchiseTitle,
    this.franchisePosterUrl,
    this.releaseDate,
    this.reaction,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] as String,
      externalId: json['mediaId'] as String,
      mediaType: mediaTypeFromString(json['mediaType'] as String),
      title: json['title'] as String,
      posterUrl: json['posterPath'] as String? ?? '',
      backdropUrl: null, // Not in DB
      genres: [], // Not in DB
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      status: watchStatusFromString(json['status'] as String),
      progress: json['progress'] as int?,
      totalEpisodes: json['totalEpisodes'] as int?,
      addedAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      franchiseId: json['franchiseId'] as String?,
      franchiseTitle: json['franchiseTitle'] as String?,
      franchisePosterUrl: json['franchisePosterUrl'] as String?,
      releaseDate: json['releaseDate'] as String?,
      reaction: json['reaction'] != null
          ? reactionFromString(json['reaction'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'mediaId': externalId,
      'mediaType': mediaTypeToString(mediaType),
      'title': title,
      'posterPath': posterUrl,
      'status': watchStatusToString(status),
      'rating': rating.toInt(), // Prisma expects Int?
      if (progress != null) 'progress': progress,
      if (totalEpisodes != null) 'totalEpisodes': totalEpisodes,
      'createdAt': addedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (franchiseId != null) 'franchiseId': franchiseId,
      if (franchiseTitle != null) 'franchiseTitle': franchiseTitle,
      if (franchisePosterUrl != null) 'franchisePosterUrl': franchisePosterUrl,
      if (releaseDate != null) 'releaseDate': releaseDate,
      if (reaction != null) 'reaction': reactionToString(reaction!),
    };
  }

  WatchlistItem copyWith({
    String? id,
    String? externalId,
    MediaType? mediaType,
    String? title,
    String? posterUrl,
    String? backdropUrl,
    List<Genre>? genres,
    double? rating,
    WatchStatus? status,
    int? progress,
    int? totalEpisodes,
    DateTime? addedAt,
    DateTime? updatedAt,
    String? franchiseId,
    String? franchiseTitle,
    String? franchisePosterUrl,
    String? releaseDate,
    Reaction? reaction,
  }) {
    return WatchlistItem(
      id: id ?? this.id,
      externalId: externalId ?? this.externalId,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      genres: genres ?? this.genres,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      franchiseId: franchiseId ?? this.franchiseId,
      franchiseTitle: franchiseTitle ?? this.franchiseTitle,
      franchisePosterUrl: franchisePosterUrl ?? this.franchisePosterUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      reaction: reaction ?? this.reaction,
    );
  }
}
