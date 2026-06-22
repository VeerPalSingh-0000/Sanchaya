import type { Media, Genre, Season, SearchResult } from '@/types/media';

// ─── Constants ──────────────────────────────────────────────────────────────

const ANILIST_ENDPOINT = 'https://graphql.anilist.co';

// ─── AniList Response Types (internal) ──────────────────────────────────────

interface AniListTitle {
  romaji: string | null;
  english: string | null;
  native: string | null;
}

interface AniListCoverImage {
  extraLarge: string | null;
  large: string | null;
  medium: string | null;
  color: string | null;
}

interface AniListStudio {
  isMain: boolean;
  node: {
    name: string;
  };
}

interface AniListRelation {
  relationType: string;
  node: {
    id: number;
    title: AniListTitle;
    type: string;
    format: string | null;
    coverImage: AniListCoverImage;
    bannerImage: string | null;
    episodes: number | null;
    averageScore: number | null;
    startDate: { year: number | null; month: number | null; day: number | null } | null;
  };
}

interface AniListStreamingEpisode {
  title: string | null;
  thumbnail: string | null;
  url: string | null;
}

interface AniListMedia {
  id: number;
  title: AniListTitle;
  description: string | null;
  coverImage: AniListCoverImage;
  bannerImage: string | null;
  genres: string[];
  averageScore: number | null;
  popularity: number;
  format: string | null;
  status: string | null;
  episodes: number | null;
  season: string | null;
  seasonYear: number | null;
  startDate: { year: number | null; month: number | null; day: number | null } | null;
  endDate: { year: number | null; month: number | null; day: number | null } | null;
  studios: { edges: AniListStudio[] } | null;
  relations: { edges: AniListRelation[] } | null;
  streamingEpisodes: AniListStreamingEpisode[] | null;
  trailer: { id: string; site: string } | null;
  nextAiringEpisode: { episode: number; airingAt: number } | null;
}

interface AniListPageInfo {
  total: number;
  currentPage: number;
  lastPage: number;
  hasNextPage: boolean;
  perPage: number;
}

interface AniListPagedResponse {
  Page: {
    pageInfo: AniListPageInfo;
    media: AniListMedia[];
  };
}

// ─── GraphQL Fragments ──────────────────────────────────────────────────────

const MEDIA_FRAGMENT = `
  fragment MediaFields on Media {
    id
    title {
      romaji
      english
      native
    }
    description(asHtml: false)
    coverImage {
      extraLarge
      large
      medium
      color
    }
    bannerImage
    genres
    averageScore
    popularity
    format
    status
    episodes
    season
    seasonYear
    startDate {
      year
      month
      day
    }
    endDate {
      year
      month
      day
    }
    trailer {
      id
      site
    }
    nextAiringEpisode {
      episode
      airingAt
    }
  }
`;

const MEDIA_DETAIL_FRAGMENT = `
  fragment MediaDetailFields on Media {
    ...MediaFields
    studios {
      edges {
        isMain
        node {
          name
        }
      }
    }
    relations {
      edges {
        relationType
        node {
          id
          title {
            romaji
            english
            native
          }
          type
          format
          coverImage {
            extraLarge
            large
            medium
            color
          }
          bannerImage
          episodes
          averageScore
        }
      }
    }
    streamingEpisodes {
      title
      thumbnail
      url
    }
  }
  ${MEDIA_FRAGMENT}
`;

// ─── GraphQL Helper ─────────────────────────────────────────────────────────

async function anilistFetch<T>(
  query: string,
  variables: Record<string, unknown> = {},
  retries: number = 3
): Promise<T> {
  for (let i = 0; i < retries; i++) {
    try {
      const res = await fetch(ANILIST_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify({ query, variables }),
        next: { revalidate: 0 },
      });

      if (!res.ok) {
        if (res.status === 429) {
          const retryAfter = res.headers.get('Retry-After');
          const waitTime = retryAfter ? parseInt(retryAfter, 10) * 1000 : 2000;
          console.warn(`AniList rate limited (429). Waiting ${waitTime}ms...`);
          await new Promise(resolve => setTimeout(resolve, waitTime));
          continue;
        }
        const text = await res.text();
        throw new Error(`AniList API error: ${res.status} - ${text}`);
      }

      const json = (await res.json()) as { data: T; errors?: { message: string }[] };

      if (json.errors?.length) {
        throw new Error(`AniList GraphQL error: ${json.errors[0].message}`);
      }

      return json.data;
    } catch (error) {
      if (i === retries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 500 * Math.pow(2, i)));
    }
  }
  throw new Error('AniList fetch failed after retries');
}

// ─── Mappers ────────────────────────────────────────────────────────────────

/**
 * AniList genres are strings, but our type system expects numeric IDs.
 * We generate a deterministic ID from the genre name so they're consistent.
 */
function genreStringToGenre(name: string): Genre {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = ((hash << 5) - hash + name.charCodeAt(i)) | 0;
  }
  return { id: Math.abs(hash), name };
}

function resolveTitle(title: AniListTitle): string {
  return title.english ?? title.romaji ?? title.native ?? 'Unknown';
}

function formatDate(
  date: { year: number | null; month: number | null; day: number | null } | null | undefined,
): string | undefined {
  if (!date?.year) return undefined;
  const y = date.year;
  const m = date.month ? String(date.month).padStart(2, '0') : '01';
  const d = date.day ? String(date.day).padStart(2, '0') : '01';
  return `${y}-${m}-${d}`;
}

function stripHtml(text: string | null): string {
  if (!text) return '';
  return text
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<[^>]*>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .trim();
}

function mapAniListStatus(status: string | null): string {
  switch (status) {
    case 'FINISHED':
      return 'Ended';
    case 'RELEASING':
      return 'Airing';
    case 'NOT_YET_RELEASED':
      return 'Upcoming';
    case 'CANCELLED':
      return 'Cancelled';
    case 'HIATUS':
      return 'On Hiatus';
    default:
      return 'Unknown';
  }
}

function buildTrailerUrl(
  trailer: { id: string; site: string } | null,
): string | undefined {
  if (!trailer) return undefined;
  if (trailer.site === 'youtube') {
    return `https://www.youtube.com/watch?v=${trailer.id}`;
  }
  if (trailer.site === 'dailymotion') {
    return `https://www.dailymotion.com/video/${trailer.id}`;
  }
  return undefined;
}

function mapAniListToMedia(anime: AniListMedia): Media {
  const title = resolveTitle(anime.title);
  const genres = anime.genres.map(genreStringToGenre);
  const studios = anime.studios?.edges
    .filter((e) => e.isMain)
    .map((e) => e.node.name);

  return {
    id: `anilist-${anime.id}`,
    externalId: String(anime.id),
    type: 'anime',
    title,
    originalTitle: anime.title.native ?? undefined,
    overview: stripHtml(anime.description),
    posterUrl: anime.coverImage.extraLarge ?? anime.coverImage.large ?? '/placeholder-poster.png',
    backdropUrl: anime.bannerImage ?? undefined,
    genres,
    rating: anime.averageScore ? Math.round(anime.averageScore) / 10 : 0,
    voteCount: anime.popularity,
    releaseDate: formatDate(anime.startDate),
    status: mapAniListStatus(anime.status),
    totalEpisodes: anime.episodes ?? undefined,
    studios: studios?.length ? studios : undefined,
    trailer: buildTrailerUrl(anime.trailer),
  };
}

// ─── Public API ─────────────────────────────────────────────────────────────

/**
 * Search anime by title.
 */
export async function searchAnime(
  query: string,
  page: number = 1,
  perPage: number = 20,
): Promise<SearchResult> {
  const gql = `
    query SearchAnime($query: String!, $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          total
          currentPage
          lastPage
          hasNextPage
          perPage
        }
        media(search: $query, type: ANIME, sort: SEARCH_MATCH) {
          ...MediaFields
          studios {
            edges {
              isMain
              node { name }
            }
          }
        }
      }
    }
    ${MEDIA_FRAGMENT}
  `;

  try {
    const data = await anilistFetch<AniListPagedResponse>(gql, {
      query,
      page,
      perPage,
    });

    const { pageInfo, media } = data.Page;

    return {
      results: media.map(mapAniListToMedia),
      totalResults: pageInfo.total,
      totalPages: pageInfo.lastPage,
      page: pageInfo.currentPage,
    };
  } catch (error) {
    console.error('AniList searchAnime error:', error);
    return { results: [], totalResults: 0, totalPages: 0, page: 1 };
  }
}

/**
 * Get full anime details including studios and related media.
 */
export async function getAnimeDetails(id: string): Promise<Media | null> {
  const gql = `
    query GetAnimeDetails($id: Int!) {
      Media(id: $id, type: ANIME) {
        ...MediaDetailFields
      }
    }
    ${MEDIA_DETAIL_FRAGMENT}
  `;

  try {
    const numericId = parseInt(id.replace(/\D/g, ''), 10);
    const data = await anilistFetch<{ Media: AniListMedia }>(gql, {
      id: numericId,
    });

    return mapAniListToMedia(data.Media);
  } catch (error) {
    console.error(`AniList getAnimeDetails(${id}) error:`, error);
    return null;
  }
}

/**
 * Get related seasons/sequels for an anime.
 * Returns a list of Seasons built from the related anime entries.
 */
export async function getAnimeSeasons(id: string): Promise<Season[]> {
  const timelineNodeFragment = `
    fragment TimelineNode on Media {
      id
      title {
        romaji
        english
        native
      }
      type
      format
      coverImage {
        extraLarge
        large
        medium
        color
      }
      bannerImage
      episodes
      averageScore
      startDate {
        year
        month
        day
      }
    }
  `;

  const gql = `
    ${timelineNodeFragment}

    query GetTimelineNode($id: Int!) {
      Media(id: $id, type: ANIME) {
        ...TimelineNode
        relations {
          edges {
            relationType
            node {
              id
              type
            }
          }
        }
      }
    }
  `;

  const relationsQuery = `
    ${timelineNodeFragment}
    query GetRelations($id_in: [Int]) {
      Page(page: 1, perPage: 50) {
        media(id_in: $id_in, type: ANIME) {
          ...TimelineNode
          relations {
            edges {
              relationType
              node {
                id
                type
              }
            }
          }
        }
      }
    }
  `;

  try {
    const numericId = parseInt(id.replace(/\D/g, ''), 10);
    
    const validRelationTypes = [
      'CURRENT', 'SEQUEL', 'PREQUEL', 'SIDE_STORY', 'PARENT', 'ALTERNATIVE', 'SPIN_OFF', 'ADAPTATION', 'SUMMARY'
    ];

    const allNodesMap = new Map<number, any>();
    const queue: number[] = [numericId];
    const visited = new Set<number>();

    // Initial fetch for the root node
    const initialData = await anilistFetch<any>(gql, { id: numericId });
    const rootMedia = initialData.Media;
    if (!rootMedia) return [];

    allNodesMap.set(rootMedia.id, { ...rootMedia, relationType: 'CURRENT' });
    visited.add(rootMedia.id);

    // Collect initial relations to queue
    const initialRelations = rootMedia.relations?.edges || [];
    for (const edge of initialRelations) {
      if (edge.node.type === 'ANIME' && validRelationTypes.includes(edge.relationType) && !visited.has(edge.node.id)) {
        queue.push(edge.node.id);
      }
    }

    // BFS loop to fetch the rest
    while (queue.length > 0) {
      const batchIds = queue.splice(0, 50); // Process up to 50 at a time
      batchIds.forEach(id => visited.add(id));
      
      const batchData = await anilistFetch<any>(relationsQuery, { id_in: batchIds });
      const mediaItems = batchData.Page?.media || [];
      
      for (const media of mediaItems) {
        // We don't have the exact relation type from the parent, so we just set it to a generic valid one or determine it
        // Actually, we can figure out relationType by looking at relations backwards, but for sorting, relationType isn't strictly necessary as long as it's valid.
        if (!allNodesMap.has(media.id)) {
          allNodesMap.set(media.id, { ...media, relationType: 'SEQUEL' });
        }
        
        const relations = media.relations?.edges || [];
        for (const edge of relations) {
          if (edge.node.type === 'ANIME' && validRelationTypes.includes(edge.relationType) && !visited.has(edge.node.id)) {
            queue.push(edge.node.id);
          }
        }
      }
    }

    const allMediaInTimeline = Array.from(allNodesMap.values());
    const validMedia = allMediaInTimeline.filter(node => validRelationTypes.includes(node.relationType));

    // Sort by release date (year -> month -> day)
    const sortedMedia = validMedia.sort((a, b) => {
      const dateA = a.startDate?.year ? new Date(a.startDate.year, (a.startDate.month || 1) - 1, a.startDate.day || 1).getTime() : Infinity;
      const dateB = b.startDate?.year ? new Date(b.startDate.year, (b.startDate.month || 1) - 1, b.startDate.day || 1).getTime() : Infinity;
      
      if (dateA !== dateB) return dateA - dateB;
      return a.id - b.id;
    });

    return sortedMedia.map((node, index) => ({
      number: index + 1,
      name: resolveTitle(node.title),
      episodeCount: node.episodes ?? 0,
      overview: node.relationType === 'CURRENT' 
        ? 'Current Series' 
        : `${node.relationType.replace(/_/g, ' ')} - ${resolveTitle(node.title)}`,
      posterUrl:
        node.coverImage.extraLarge ??
        node.coverImage.large ??
        undefined,
      airDate: undefined,
      mediaId: `anilist-${node.id}`,
      mediaType: 'anime',
    }));
  } catch (error) {
    console.error(`AniList getAnimeSeasons(${id}) error:`, error);
    return [];
  }
}

/**
 * Get currently trending anime.
 */
export async function getTrendingAnime(
  page: number = 1,
  perPage: number = 20,
): Promise<Media[]> {
  const gql = `
    query TrendingAnime($page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          total
          currentPage
          lastPage
          hasNextPage
          perPage
        }
        media(type: ANIME, sort: TRENDING_DESC) {
          ...MediaFields
          studios {
            edges {
              isMain
              node { name }
            }
          }
        }
      }
    }
    ${MEDIA_FRAGMENT}
  `;

  try {
    const data = await anilistFetch<AniListPagedResponse>(gql, {
      page,
      perPage,
    });

    return data.Page.media.map(mapAniListToMedia);
  } catch (error) {
    console.error('AniList getTrendingAnime error:', error);
    return [];
  }
}

/**
 * Discover anime by genre names. Useful for generating recommendations.
 */
export async function discoverAnimeByGenres(
  genres: string[],
  page: number = 1,
  excludeIds: string[] = [],
): Promise<SearchResult> {
  const gql = `
    query DiscoverAnimeByGenres($genres: [String], $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          total
          currentPage
          lastPage
          hasNextPage
          perPage
        }
        media(
          type: ANIME,
          genre_in: $genres,
          sort: SCORE_DESC,
          isAdult: false,
          minimumTagRank: 50
        ) {
          ...MediaFields
          studios {
            edges {
              isMain
              node { name }
            }
          }
        }
      }
    }
    ${MEDIA_FRAGMENT}
  `;

  try {
    const excludeSet = new Set(excludeIds);

    const data = await anilistFetch<AniListPagedResponse>(gql, {
      genres,
      page,
      perPage: 20,
    });

    const { pageInfo, media } = data.Page;

    const results = media
      .map(mapAniListToMedia)
      .filter((m) => !excludeSet.has(m.externalId));

    return {
      results,
      totalResults: pageInfo.total,
      totalPages: pageInfo.lastPage,
      page: pageInfo.currentPage,
    };
  } catch (error) {
    console.error('AniList discoverAnimeByGenres error:', error);
    return { results: [], totalResults: 0, totalPages: 0, page: 1 };
  }
}
