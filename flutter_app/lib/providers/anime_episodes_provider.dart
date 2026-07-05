import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import 'service_providers.dart';

final animeEpisodesProvider = FutureProvider.family<List<Episode>, int>((ref, malId) async {
  if (malId <= 0) return [];
  return ref.read(anilistServiceProvider).getAnimeEpisodes(malId);
});

