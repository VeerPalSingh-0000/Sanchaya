import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';

final franchiseTimelineProvider = FutureProvider.family<List<Season>, Media>((ref, media) async {
  if (media.seasons != null && media.seasons!.isNotEmpty) {
    if (media.type == MediaType.series) {
      final properSeasons = media.seasons!.where((s) => s.number > 0).toList();
      if (properSeasons.isNotEmpty) return properSeasons;
    }
    return media.seasons!;
  }
  return [];
});
