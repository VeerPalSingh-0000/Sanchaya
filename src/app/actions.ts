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

      results = [...tmdbResults, ...anilistResults];
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
