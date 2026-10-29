import 'media.dart';

class SearchResult {
  final List<Media> results;
  final int totalResults;
  final int totalPages;
  final int page;

  SearchResult({
    required this.results,
    required this.totalResults,
    required this.totalPages,
    required this.page,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => Media.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalResults: json['totalResults'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.map((e) => e.toJson()).toList(),
      'totalResults': totalResults,
      'totalPages': totalPages,
      'page': page,
    };
  }
}

class RecommendationResult {
  final Media media;
  final List<String> matchedGenres;
  final double matchScore;
  final String reason;

  RecommendationResult({
    required this.media,
    required this.matchedGenres,
    required this.matchScore,
    required this.reason,
  });

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    return RecommendationResult(
      media: Media.fromJson(json['media'] as Map<String, dynamic>),
      matchedGenres: (json['matchedGenres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'media': media.toJson(),
      'matchedGenres': matchedGenres,
      'matchScore': matchScore,
      'reason': reason,
    };
  }
}
