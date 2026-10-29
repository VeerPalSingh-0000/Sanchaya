'use server';

import { getTrending, discoverByGenres } from '@/lib/tmdb';
import { getTrendingAnime, discoverAnimeByGenres } from '@/lib/anilist';
import type { Media } from '@/types/media';

export type MediaTypeFilter = 'all' | 'movie' | 'series' | 'anime';
export type FilterCategory = 'all' | 'action' | 'adventure' | 'drama' | 'romance' | 'comedy' | 'scifi' | 'fantasy';

const TMDB_GENRES = {
  action: 28,
  adventure: 12,
  drama: 18,
  romance: 10749,
  comedy: 35,
  scifi: 878,
  fantasy: 14,
};

const TMDB_TV_GENRES = {
  action: 10759,
  adventure: 10759,
  drama: 18,
  romance: 10749,
  comedy: 35,
  scifi: 10765,
  fantasy: 10765,
};

const ANILIST_GENRES = {
  action: 'Action',
  adventure: 'Adventure',
  drama: 'Drama',
  romance: 'Romance',
  comedy: 'Comedy',
  scifi: 'Sci-Fi',
  fantasy: 'Fantasy',
};

export async function fetchDiscoverData(
  page: number,
  mediaType: MediaTypeFilter,
  category: FilterCategory
): Promise<Media[]> {
  try {
    const promises: Promise<Media[]>[] = [];

    const fetchMovie = async () => {
      let res: Media[] = [];
      if (category === 'all') {
        res = await getTrending('movie', 'week', page);
      } else {
        const searchRes = await discoverByGenres('movie', [TMDB_GENRES[category]], page);
        res = searchRes.results;
      }
      return res.map(item => ({ ...item, type: 'movie' as const }));
    };

    const fetchSeries = async () => {
      let res: Media[] = [];
      if (category === 'all') {
        res = await getTrending('tv', 'week', page);
      } else {
        const searchRes = await discoverByGenres('tv', [TMDB_TV_GENRES[category] || TMDB_GENRES[category]], page);
        res = searchRes.results;
      }
      return res.map(item => ({ ...item, type: 'series' as const }));
    };

    const fetchAnime = async () => {
      let res: Media[] = [];
      if (category === 'all') {
        res = await getTrendingAnime(page, 20);
      } else {
        const searchRes = await discoverAnimeByGenres([ANILIST_GENRES[category]], page);
        res = searchRes.results;
      }
      return res.map(item => ({ ...item, type: 'anime' as const }));
    };

    if (mediaType === 'all' || mediaType === 'movie') promises.push(fetchMovie());
    if (mediaType === 'all' || mediaType === 'series') promises.push(fetchSeries());
    if (mediaType === 'all' || mediaType === 'anime') promises.push(fetchAnime());

    const results = await Promise.allSettled(promises);
    let combinedItems: Media[] = [];

    results.forEach((res) => {
      if (res.status === 'fulfilled') {
        combinedItems = [...combinedItems, ...res.value];
      }
    });

    if (mediaType === 'all') {
      combinedItems.sort(() => Math.random() - 0.5);
    }

    return combinedItems;

  } catch (error) {
    console.error('Error in fetchDiscoverData:', error);
    return [];
  }
}
