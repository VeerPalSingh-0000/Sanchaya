import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tmdb_service.dart';
import '../services/anilist_service.dart';
import '../services/supabase_service.dart';
import '../services/cache_service.dart';

final tmdbServiceProvider = Provider<TmdbService>((ref) {
  return TmdbService();
});

final anilistServiceProvider = Provider<AnilistService>((ref) {
  return AnilistService();
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});
