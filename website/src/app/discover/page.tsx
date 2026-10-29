import { getTrending } from '@/lib/tmdb';
import { getTrendingAnime } from '@/lib/anilist';
import DiscoverClient from './DiscoverClient';
import type { Metadata } from 'next';

import type { Media } from '@/types/media';

export const metadata: Metadata = {
  title: 'Discover | Sanchaya',
  description: 'Discover new movies, series, and anime in an immersive bento layout.',
};

export default async function DiscoverPage() {
  let trendingMovies: Media[] = [];
  let trendingTV: Media[] = [];
  let trendingAnime: Media[] = [];
  
  try {
    const results = await Promise.allSettled([
      getTrending('movie', 'week'),
      getTrending('tv', 'week'),
      getTrendingAnime(1, 30),
    ]);

    if (results[0].status === 'fulfilled') trendingMovies = results[0].value;
    if (results[1].status === 'fulfilled') trendingTV = results[1].value;
    if (results[2].status === 'fulfilled') trendingAnime = results[2].value;
  } catch (error) {
    console.error('Error fetching data for discover:', error);
  }

  // Combine lists and label type properly
  const combinedItems = [
    ...trendingMovies.map(item => ({ ...item, type: 'movie' as const })),
    ...trendingTV.map(item => ({ ...item, type: 'series' as const })),
    ...trendingAnime.map(item => ({ ...item, type: 'anime' as const }))
  ];

  return (
    <DiscoverClient items={combinedItems} />
  );
}
