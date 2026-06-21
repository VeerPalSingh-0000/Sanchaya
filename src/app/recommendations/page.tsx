import { getTrending } from '@/lib/tmdb';
import { getTrendingAnime } from '@/lib/anilist';
import RecommendationsClient from './RecommendationsClient';
import type { Metadata } from 'next';

import type { Media } from '@/types/media';

export const metadata: Metadata = {
  title: 'Recommendations | CINEVERSE',
  description: 'Personalized media recommendations based on your watchlist.',
};

export default async function RecommendationsPage() {
  // Fetch trending data to act as a base for recommendations
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
    console.error('Error fetching data for recommendations:', error);
  }

  return (
    <RecommendationsClient
      trendingMovies={trendingMovies}
      trendingSeries={trendingTV}
      trendingAnime={trendingAnime}
    />
  );
}
