import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import 'service_providers.dart';

class MediaDetailArgs {
  final String id;
  final MediaType type;

  MediaDetailArgs(this.id, this.type);

  @override
  bool operator ==(Object other) => identical(this, other) || other is MediaDetailArgs && runtimeType == other.runtimeType && id == other.id && type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}

final mediaDetailProvider = FutureProvider.family<Media?, MediaDetailArgs>((ref, args) async {
  final cacheService = ref.read(cacheServiceProvider);
  final cacheKey = '\${args.type.name}_\${args.id}';
  final cached = cacheService.getMediaDetailsCache(cacheKey);
  
  if (cached != null) {
    return Media.fromJson(cached);
  }

  Media? media;
  if (args.type == MediaType.movie) {
    final tmdbService = ref.read(tmdbServiceProvider);
    media = await tmdbService.getMovieDetails(args.id);
  } else if (args.type == MediaType.series) {
    final tmdbService = ref.read(tmdbServiceProvider);
    media = await tmdbService.getTVDetails(args.id);
  } else if (args.type == MediaType.anime) {
    final anilistService = ref.read(anilistServiceProvider);
    media = await anilistService.getAnimeDetails(args.id);
    
    // Also fetch seasons (franchise timeline) for anime
    if (media != null) {
      final seasons = await anilistService.getAnimeSeasons(args.id);
      media = Media(
        id: media.id,
        externalId: media.externalId,
        malId: media.malId,
        type: media.type,
        title: media.title,
        originalTitle: media.originalTitle,
        overview: media.overview,
        posterUrl: media.posterUrl,
        backdropUrl: media.backdropUrl,
        genres: media.genres,
        rating: media.rating,
        voteCount: media.voteCount,
        releaseDate: media.releaseDate,
        status: media.status,
        seasons: seasons,
        totalEpisodes: media.totalEpisodes,
        studios: media.studios,
        trailer: media.trailer,
      );
    }
  }

  if (media != null) {
    await cacheService.setMediaDetailsCache(cacheKey, media.toJson());
  }
  
  return media;
});
