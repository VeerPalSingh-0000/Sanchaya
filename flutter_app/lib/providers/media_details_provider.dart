import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import 'service_providers.dart';

final mediaDetailsProvider = FutureProvider.family<Media?, String>((ref, id) async {
  if (id.startsWith('anilist-')) {
    return ref.read(anilistServiceProvider).getAnimeDetails(id);
  } else if (id.startsWith('tmdb-tv-')) {
    return ref.read(tmdbServiceProvider).getTVDetails(id);
  } else {
    return ref.read(tmdbServiceProvider).getMovieDetails(id);
  }
});
