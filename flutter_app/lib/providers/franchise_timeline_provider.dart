import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import 'service_providers.dart';

final franchiseTimelineProvider = FutureProvider.family<List<Season>, Media>((ref, media) async {
  if (media.type == MediaType.anime) {
    if (!media.id.startsWith('anilist-')) return [];
    return ref.read(anilistServiceProvider).getAnimeSeasons(media.id);
  } else if (media.type == MediaType.series) {
    // For TV shows, seasons are already included in the media details!
    if (media.seasons != null && media.seasons!.isNotEmpty) {
      // Return proper seasons only (number > 0), or all if none
      final properSeasons = media.seasons!.where((s) => s.number > 0).toList();
      if (properSeasons.isNotEmpty) return properSeasons;
      return media.seasons!;
    }
    return [];
  } else if (media.type == MediaType.movie) {
    if (media.franchiseId != null && media.franchiseId!.startsWith('tmdb-collection-')) {
      final collection = await ref.read(tmdbServiceProvider).getCollectionDetails(media.franchiseId!);
      return collection ?? [];
    }
    return [];
  }
  
  return [];
});
