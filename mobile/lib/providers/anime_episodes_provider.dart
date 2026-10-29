import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import 'service_providers.dart';

final animeEpisodesProvider = FutureProvider.family<List<Episode>, int>((ref, malId) async {
  if (malId <= 0) return [];
  return ref.read(anilistServiceProvider).getAnimeEpisodes(malId);
});

final animeEpisodesByMediaProvider = FutureProvider.family<List<Episode>, Media>((ref, media) async {
  final malId = media.malId ??
      (media.id.startsWith('anilist-')
          ? int.tryParse(media.id.replaceFirst('anilist-', ''))
          : int.tryParse(media.externalId.replaceAll(RegExp(r'\D'), ''))) ?? 0;
  return ref.read(anilistServiceProvider).getAnimeEpisodes(malId, title: media.title);
});

