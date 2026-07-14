import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/watchlist_item.dart';
import '../models/media.dart';
import 'service_providers.dart';
import 'auth_provider.dart';

String _generateCuid() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rnd = Random.secure();
  return 'c${List.generate(24, (index) => chars[rnd.nextInt(chars.length)]).join('')}';
}

class WatchlistNotifier extends AsyncNotifier<List<WatchlistItem>> {
  @override
  Future<List<WatchlistItem>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final supabaseService = ref.watch(supabaseServiceProvider);
    final prismaUserId = await supabaseService.getOrCreatePrismaUserId(user);
    return await supabaseService.getWatchlist(prismaUserId);
  }

  Future<void> refresh() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final prismaUserId = await supabaseService.getOrCreatePrismaUserId(user);
      final result = await supabaseService.getWatchlist(prismaUserId);
      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addOrUpdate(WatchlistItem item) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Optimistic update
    final previousState = state.value ?? [];
    final existingIndex = previousState.indexWhere(
      (e) => e.externalId == item.externalId && e.mediaType == item.mediaType,
    );

    final newState = List<WatchlistItem>.from(previousState);
    if (existingIndex >= 0) {
      newState[existingIndex] = item;
    } else {
      newState.insert(0, item);
    }
    state = AsyncData(newState);

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final prismaUserId = await supabaseService.getOrCreatePrismaUserId(user);
      await supabaseService.addToWatchlist(prismaUserId, item);
    } catch (e) {
      // Revert on error
      state = AsyncData(previousState);
      rethrow;
    }
  }

  Future<void> remove(String externalId, MediaType mediaType) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final previousState = state.value ?? [];
    final newState = previousState
        .where((e) => !(e.externalId == externalId && e.mediaType == mediaType))
        .toList();
    state = AsyncData(newState);

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final prismaUserId = await supabaseService.getOrCreatePrismaUserId(user);
      await supabaseService.removeFromWatchlist(
        prismaUserId,
        externalId,
        mediaTypeToString(mediaType),
      );
    } catch (e) {
      state = AsyncData(previousState);
      rethrow;
    }
  }

  Future<void> addMediaToWatchlist(Media media, WatchStatus status) async {
    Media mediaToAdd = media;

    if (mediaToAdd.franchiseId == null) {
      if (mediaToAdd.type == MediaType.movie) {
        final tmdb = ref.read(tmdbServiceProvider);
        final details = await tmdb.getMovieDetails(mediaToAdd.externalId);
        if (details != null && details.franchiseId != null) {
          mediaToAdd = details;
        }
      } else if (mediaToAdd.type == MediaType.anime) {
        final anilist = ref.read(anilistServiceProvider);
        final seasons = await anilist.getAnimeSeasons(mediaToAdd.externalId);
        if (seasons.isNotEmpty) {
          final rootItem =
              seasons.where((s) => s.format == 'TV').firstOrNull ??
              seasons.first;
          mediaToAdd = Media(
            id: mediaToAdd.id,
            externalId: mediaToAdd.externalId,
            type: MediaType.anime,
            title: mediaToAdd.title,
            originalTitle: mediaToAdd.originalTitle,
            originCountry: mediaToAdd.originCountry,
            overview: mediaToAdd.overview,
            posterUrl: mediaToAdd.posterUrl,
            backdropUrl: mediaToAdd.backdropUrl,
            genres: mediaToAdd.genres,
            rating: mediaToAdd.rating,
            voteCount: mediaToAdd.voteCount,
            releaseDate: mediaToAdd.releaseDate,
            status: mediaToAdd.status,
            totalEpisodes: mediaToAdd.totalEpisodes,
            franchiseId: rootItem.mediaId ?? mediaToAdd.id,
            franchiseTitle: rootItem.name,
            franchisePosterUrl: rootItem.posterUrl ?? mediaToAdd.posterUrl,
          );
        }
      }
    }

    final newItem = WatchlistItem(
      id: _generateCuid(),
      externalId:
          mediaToAdd.id, // Use full ID (e.g. tmdb-movie-1234) to match Next.js
      mediaType: mediaToAdd.type,
      title: mediaToAdd.title,
      posterUrl: mediaToAdd.posterUrl,
      backdropUrl: mediaToAdd.backdropUrl,
      genres: mediaToAdd.genres,
      rating: mediaToAdd.rating,
      status: status,
      addedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalEpisodes: mediaToAdd.totalEpisodes,
      franchiseId: mediaToAdd.franchiseId,
      franchiseTitle: mediaToAdd.franchiseTitle,
      franchisePosterUrl: mediaToAdd.franchisePosterUrl,
      releaseDate: mediaToAdd.releaseDate,
    );

    await addOrUpdate(newItem);
  }

  Future<void> updateStatus(WatchlistItem item, WatchStatus status) async {
    final updatedItem = item.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    await addOrUpdate(updatedItem);
  }

  Future<void> updateStatusWithPropagation(
    Media currentMedia,
    WatchStatus status,
    List<Season>? franchiseTimeline,
  ) async {
    var existingItem = getItem(currentMedia.id, currentMedia.type);
    if (existingItem != null) {
      await updateStatus(existingItem, status);
    } else {
      await addMediaToWatchlist(currentMedia, status);
    }

    if (franchiseTimeline == null || franchiseTimeline.isEmpty) return;

    final currentIndex = franchiseTimeline.indexWhere((s) {
      final cleanId = (s.mediaId ?? currentMedia.externalId)
          .replaceAll('anilist-', '')
          .replaceAll('tmdb-movie-', '')
          .replaceAll('tmdb-tv-', '');
      return cleanId == currentMedia.externalId.replaceAll('anilist-', '').replaceAll('tmdb-movie-', '').replaceAll('tmdb-tv-', '');
    });

    if (currentIndex == -1) return;

    if (status == WatchStatus.completed) {
      // Mark previous main story items as completed
      for (int i = currentIndex - 1; i >= 0; i--) {
        await _propagateStatusToArc(franchiseTimeline[i], currentMedia, WatchStatus.completed);
      }
    }
  }

  Future<void> _propagateStatusToArc(Season arc, Media parentMedia, WatchStatus status) async {
    // Only propagate to main story items for anime
    if (parentMedia.type == MediaType.anime) {
      final isMainStory = arc.relationType != 'SPIN_OFF' &&
          arc.relationType != 'SIDE_STORY' &&
          arc.relationType != 'CHARACTER' &&
          arc.relationType != 'SUMMARY' &&
          arc.relationType != 'ALTERNATIVE' &&
          arc.relationType != 'OTHER';
      if (!isMainStory) return;
    }

    final cleanMediaId = (arc.mediaId ?? parentMedia.externalId)
        .replaceAll('anilist-', '')
        .replaceAll('tmdb-movie-', '')
        .replaceAll('tmdb-tv-', '');
    final targetType = arc.mediaType ?? parentMedia.type;
    final isAnime = parentMedia.type == MediaType.anime;
    final prefix = isAnime
        ? 'anilist-'
        : (targetType == MediaType.movie ? 'tmdb-movie-' : 'tmdb-tv-');
    final targetId = '$prefix$cleanMediaId';

    final existing = getItem(targetId, targetType);
    if (existing != null) {
      if (existing.status != status) {
        await updateStatus(existing, status);
      }
    } else {
      final pseudoMedia = Media(
        id: targetId,
        externalId: cleanMediaId,
        type: targetType,
        title: arc.name.isNotEmpty ? arc.name : parentMedia.title,
        overview: arc.overview,
        posterUrl: arc.posterUrl ?? parentMedia.posterUrl,
        genres: parentMedia.genres,
        rating: 0.0,
        voteCount: 0,
        status: 'Airing',
        franchiseId: parentMedia.franchiseId,
        franchiseTitle: parentMedia.franchiseTitle ?? parentMedia.title,
        franchisePosterUrl:
            parentMedia.franchisePosterUrl ?? parentMedia.posterUrl,
        releaseDate: arc.airDate ?? parentMedia.releaseDate,
      );
      await addMediaToWatchlist(pseudoMedia, status);
    }
  }

  Future<void> updateReaction(WatchlistItem item, Reaction? reaction) async {
    final updatedItem = item.copyWith(
      reaction: reaction,
      updatedAt: DateTime.now(),
    );
    await addOrUpdate(updatedItem);
  }

  Future<void> updateProgress(WatchlistItem item, int progress) async {
    final updatedItem = item.copyWith(
      progress: progress,
      updatedAt: DateTime.now(),
    );
    await addOrUpdate(updatedItem);
  }

  bool isInWatchlist(String mediaId, MediaType mediaType) {
    return state.value?.any(
          (e) => e.externalId == mediaId && e.mediaType == mediaType,
        ) ??
        false;
  }

  WatchlistItem? getItem(String mediaId, MediaType mediaType) {
    return state.value
        ?.where((e) => e.externalId == mediaId && e.mediaType == mediaType)
        .firstOrNull;
  }

  // --- Advanced Franchise Logic ---

  List<WatchlistItem> getFranchiseItems(Media media) {
    final list = state.value ?? [];
    return list
        .where(
          (item) =>
              (media.franchiseId != null &&
                  item.franchiseId == media.franchiseId) ||
              (item.externalId == media.id && item.mediaType == media.type),
        )
        .toList();
  }

  WatchStatus getAggregateStatus(Media media) {
    final items = getFranchiseItems(media);
    if (items.isEmpty) return WatchStatus.planToWatch;

    if (items.any((i) => i.status == WatchStatus.watching)) {
      return WatchStatus.watching;
    } else if (items.every((i) => i.status == WatchStatus.completed)) {
      return WatchStatus.completed;
    } else if (items.any((i) => i.status == WatchStatus.planToWatch)) {
      return WatchStatus.planToWatch;
    } else if (items.any((i) => i.status == WatchStatus.onHold)) {
      return WatchStatus.onHold;
    } else {
      return WatchStatus.dropped;
    }
  }

  bool isAdded(Media media) {
    return getFranchiseItems(media).isNotEmpty;
  }

  Future<void> bulkUpdateFranchise(
    List<Media> franchiseMedia,
    WatchStatus status,
  ) async {
    for (final m in franchiseMedia) {
      final existing = getItem(m.id, m.type);
      if (existing != null) {
        await updateStatus(existing, status);
      } else {
        final newItem = WatchlistItem(
          id: _generateCuid(),
          externalId: m.id, // Use full ID
          mediaType: m.type,
          title: m.title,
          posterUrl: m.posterUrl,
          backdropUrl: m.backdropUrl,
          genres: m.genres,
          rating: m.rating,
          status: status,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          totalEpisodes: m.totalEpisodes,
          franchiseId: m.franchiseId,
          franchiseTitle: m.franchiseTitle,
          franchisePosterUrl: m.franchisePosterUrl,
          releaseDate: m.releaseDate,
        );
        await addOrUpdate(newItem);
      }
    }
  }

  Future<void> bulkRemoveFranchise(List<WatchlistItem> items) async {
    for (final item in items) {
      await remove(item.externalId, item.mediaType);
    }
  }
}

final watchlistProvider =
    AsyncNotifierProvider<WatchlistNotifier, List<WatchlistItem>>(
      WatchlistNotifier.new,
    );
