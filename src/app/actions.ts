'use server';

import { searchMulti, searchMovies, searchTV } from '@/lib/tmdb';
import { searchAnime } from '@/lib/anilist';
import type { Media, MediaFilter } from '@/types/media';

export async function performSearch(query: string, type: MediaFilter): Promise<Media[]> {
  if (!query || !query.trim()) {
    return [];
  }

  let results: Media[] = [];

  try {
    if (type === 'all') {
      // In 'all', we might want to prioritize TMDB but still fetch Anime.
      // Promise.allSettled prevents one failing from crashing both.
      const [tmdbRes, animeRes] = await Promise.allSettled([
        searchMulti(query),
        searchAnime(query),
      ]);
      
      const tmdbResults = tmdbRes.status === 'fulfilled' ? tmdbRes.value.results : [];
      const anilistResults = animeRes.status === 'fulfilled' ? animeRes.value.results : [];

      // Actively filter out TMDB results that are Japanese Anime
      // so we exclusively use the superior AniList data for anime
      const filteredTmdb = tmdbResults.filter((media) => {
        // TMDB TV shows usually have originCountry. TMDB Movies might not in searchMulti.
        // We filter out anything that is an Animation from Japan, OR anything with 'anime' in original language/country if possible.
        // Since searchMulti lacks full details for movies, we filter out any TMDB item where genre is Animation and original language is ja.
        const isTmdbAnime =
          (media.originCountry === 'JP' || (media as any).original_language === 'ja' || (media.originalTitle && media.originalTitle.match(/[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff]/))) &&
          (media.genres ?? []).some((g) => g.name === 'Animation' || g.id === 16);
        return !isTmdbAnime;
      });

      results = [...filteredTmdb, ...anilistResults];
    } else if (type === 'movie') {
      const res = await searchMovies(query);
      results = res.results;
    } else if (type === 'series') {
      const res = await searchTV(query);
      results = res.results;
    } else if (type === 'anime') {
      const res = await searchAnime(query);
      results = res.results;
    }
    
    // Optional: Sort by rating or popularity
    results.sort((a, b) => (b.rating || 0) - (a.rating || 0));
    
  } catch (error) {
    console.error('Search error:', error);
  }

  return results.slice(0, 10); // Return top 10 results for the dropdown
}

export async function getFranchiseMetadata(media: Media): Promise<{
  franchiseId?: string;
  franchiseTitle?: string;
  franchisePosterUrl?: string;
}> {
  if (media.franchiseId) {
    return {
      franchiseId: media.franchiseId,
      franchiseTitle: media.franchiseTitle,
      franchisePosterUrl: media.franchisePosterUrl,
    };
  }

  try {
    if (media.type === 'anime' || media.id.startsWith('anilist-')) {
      const { getAnimeSeasons } = await import('@/lib/anilist');
      const seasons = await getAnimeSeasons(media.externalId);
      if (seasons && seasons.length > 0) {
        const tvItem = seasons.find(t => t.format === 'TV');
        const rootItem = tvItem || seasons[0];
        return {
          franchiseId: rootItem.mediaId || String(media.id),
          franchiseTitle: rootItem.name,
          franchisePosterUrl: rootItem.posterUrl || media.posterUrl,
        };
      }
    } else if (media.type === 'movie' || media.id.startsWith('tmdb-movie-')) {
      const { getMovieDetails } = await import('@/lib/tmdb');
      const details = await getMovieDetails(media.externalId);
      if (details?.franchiseId) {
        return {
          franchiseId: details.franchiseId,
          franchiseTitle: details.franchiseTitle,
          franchisePosterUrl: details.franchisePosterUrl,
        };
      }
    }
  } catch (error) {
    console.error('Failed to fetch franchise metadata:', error);
  }

  return {};
}

export async function getEntireFranchiseMedia(media: Media): Promise<Media[]> {
  const results: Media[] = [];
  try {
    if (media.type === 'anime' || media.id.startsWith('anilist-')) {
      const { getAnimeSeasons } = await import('@/lib/anilist');
      const seasons = await getAnimeSeasons(media.externalId);
      if (seasons && seasons.length > 0) {
        const rootItem = seasons.find((t: any) => t.format === 'TV') || seasons[0];
        const franchiseId = rootItem.mediaId || String(media.id);
        const franchiseTitle = rootItem.name;
        const franchisePosterUrl = rootItem.posterUrl || media.posterUrl;
        
        return seasons.map((s: any) => ({
          id: s.mediaId,
          externalId: String(s.mediaId).replace('anilist-', ''),
          type: 'anime',
          title: s.name,
          posterUrl: s.posterUrl || media.posterUrl,
          backdropUrl: media.backdropUrl,
          rating: media.rating, 
          voteCount: 0,
          overview: '',
          status: 'released',
          totalEpisodes: undefined, 
          genres: media.genres,
          franchiseId,
          franchiseTitle,
          franchisePosterUrl,
        }));
      }
    } else if (media.type === 'movie' || media.id.startsWith('tmdb-movie-')) {
      const { getMovieDetails, getCollection } = await import('@/lib/tmdb');
      const details = await getMovieDetails(media.externalId);
      if (details?.franchiseId) {
        const cleanCollectionId = String(details.franchiseId).replace('tmdb-collection-', '');
        const collection = await getCollection(cleanCollectionId);
        if (collection && collection.parts) {
          return collection.parts.map((p: any) => ({
            id: `tmdb-movie-${p.id}`,
            externalId: String(p.id),
            type: 'movie',
            title: p.title || p.name,
            posterUrl: p.poster_path ? `https://image.tmdb.org/t/p/w500${p.poster_path}` : '',
            backdropUrl: p.backdrop_path ? `https://image.tmdb.org/t/p/w1280${p.backdrop_path}` : '',
            rating: p.vote_average ? p.vote_average * 10 : 0,
            voteCount: 0,
            overview: p.overview || '',
            status: 'released',
            genres: [],
            franchiseId: details.franchiseId,
            franchiseTitle: details.franchiseTitle,
            franchisePosterUrl: details.franchisePosterUrl,
          }));
        }
      }
    }
  } catch (error) {
    console.error('Failed to get entire franchise media:', error);
  }
  return results;
}
