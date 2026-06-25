'use server';

import { getAnimeSeasons } from '@/lib/anilist';

export interface FranchiseGroup {
  rootId: string;
  rootTitle: string;
  rootPosterUrl: string;
  memberIds: string[]; // All anime IDs that belong to this franchise
}

export async function getWatchlistFranchiseGroupings(animeIds: string[]): Promise<FranchiseGroup[]> {
  const groups: FranchiseGroup[] = [];
  const processedIds = new Set<string>();

  for (const id of animeIds) {
    if (processedIds.has(id)) continue;

    try {
      // getAnimeSeasons returns the full chronological timeline
      const timeline = await getAnimeSeasons(id);
      
      if (timeline && timeline.length > 0) {
        // Prioritize the earliest 'TV' format as the main story. Fallback to the earliest overall item.
        const tvItem = timeline.find(t => t.format === 'TV');
        const rootItem = tvItem || timeline[0];
        const memberIds = timeline.map(t => String(t.mediaId).replace('anilist-', '')).filter(Boolean) as string[];
        
        groups.push({
          rootId: String(rootItem.mediaId).startsWith('anilist-') ? String(rootItem.mediaId) : `anilist-${String(rootItem.mediaId).replace('anilist-', '') || id}`,
          rootTitle: rootItem.name,
          rootPosterUrl: rootItem.posterUrl || '',
          memberIds: memberIds
        });

        memberIds.forEach(mId => processedIds.add(mId));
      } else {
        // Fallback for items with no timeline/relations
        groups.push({
          rootId: `anilist-${id}`,
          rootTitle: "Unknown", // Will be replaced by client
          rootPosterUrl: "",
          memberIds: [id]
        });
        processedIds.add(id);
      }
    } catch (error) {
      console.error(`Failed to get timeline for ${id}:`, error);
    }
  }

  return groups;
}
