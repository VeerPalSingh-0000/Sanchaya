import { getAnimeEpisodes } from '@/lib/anilist';
import EpisodeDropdown from './EpisodeDropdown';

export default async function EpisodesLoader({ malId, isAnime }: { malId: number, isAnime: boolean }) {
  const episodes = await getAnimeEpisodes(malId);
  
  if (!episodes || episodes.length === 0) {
    return null;
  }
  
  return <EpisodeDropdown episodes={episodes} isAnime={isAnime} />;
}
