import type { Media, Genre, Season, SearchResult } from "@/types/media";
import arcData from '@/data/arc_data.json';

const ANILIST_ENDPOINT = "https://graphql.anilist.co";

// Internal AniList types (trimmed to what's needed)
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
  node: { name: string };
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
    startDate: {
      year: number | null;
      month: number | null;
      day: number | null;
    } | null;
  };
}
interface AniListStreamingEpisode {
  title: string | null;
  thumbnail: string | null;
  url: string | null;
}
interface AniListMedia {
  id: number;
  idMal: number | null;
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
  startDate: {
    year: number | null;
    month: number | null;
    day: number | null;
  } | null;
  endDate: {
    year: number | null;
    month: number | null;
    day: number | null;
  } | null;
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
  Page: { pageInfo: AniListPageInfo; media: AniListMedia[] };
}

// GraphQL fragments
const MEDIA_FRAGMENT = `
  fragment MediaFields on Media {
    id
    idMal
    title { romaji english native }
    description(asHtml: false)
    coverImage { extraLarge large medium color }
    bannerImage
    genres
    averageScore
    popularity
    format
    status
    episodes
    season
    seasonYear
    startDate { year month day }
    endDate { year month day }
    trailer { id site }
    nextAiringEpisode { episode airingAt }
  }
`;

const MEDIA_DETAIL_FRAGMENT = `
  fragment MediaDetailFields on Media {
    ...MediaFields
    studios { edges { isMain node { name } } }
    relations { edges { relationType node { id title { romaji english native } type format coverImage { extraLarge large medium color } bannerImage episodes averageScore } } }
    streamingEpisodes { title thumbnail url }
  }
  ${MEDIA_FRAGMENT}
`;

// GraphQL helper with retries
async function anilistFetch<T>(
  query: string,
  variables: Record<string, unknown> = {},
  retries = 3,
): Promise<T> {
  for (let i = 0; i < retries; i++) {
    try {
      const res = await fetch(ANILIST_ENDPOINT, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify({ query, variables }),
        next: { revalidate: 0 },
      });

      if (!res.ok) {
        if (res.status === 429) {
          const retryAfter = res.headers.get("Retry-After");
          const waitTime = retryAfter ? parseInt(retryAfter, 10) * 1000 : 2000;
          await new Promise((r) => setTimeout(r, waitTime));
          continue;
        }
        const text = await res.text();
        throw new Error(`AniList API error: ${res.status} - ${text}`);
      }

      const json = (await res.json()) as {
        data: T;
        errors?: { message: string }[];
      };
      if (json.errors?.length) throw new Error(json.errors[0].message);
      return json.data;
    } catch (err) {
      if (i === retries - 1) throw err;
      await new Promise((r) => setTimeout(r, 500 * Math.pow(2, i)));
    }
  }
  throw new Error("AniList fetch failed");
}

// Mappers & utilities
function genreStringToGenre(name: string): Genre {
  let hash = 0;
  for (let i = 0; i < name.length; i++)
    hash = ((hash << 5) - hash + name.charCodeAt(i)) | 0;
  return { id: Math.abs(hash), name };
}
function resolveTitle(title: AniListTitle): string {
  return title.english ?? title.romaji ?? title.native ?? "Unknown";
}
function formatDate(
  date?: {
    year: number | null;
    month: number | null;
    day: number | null;
  } | null,
): string | undefined {
  if (!date?.year) return undefined;
  const y = date.year;
  const m = date.month ? String(date.month).padStart(2, "0") : "01";
  const d = date.day ? String(date.day).padStart(2, "0") : "01";
  return `${y}-${m}-${d}`;
}
function stripHtml(text: string | null): string {
  if (!text) return "";
  return text
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<[^>]*>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .trim();
}
function mapAniListStatus(status: string | null): string {
  switch (status) {
    case "FINISHED":
      return "Ended";
    case "RELEASING":
      return "Airing";
    case "NOT_YET_RELEASED":
      return "Upcoming";
    case "CANCELLED":
      return "Cancelled";
    case "HIATUS":
      return "On Hiatus";
    default:
      return "Unknown";
  }
}
function buildTrailerUrl(
  trailer: { id: string; site: string } | null,
): string | undefined {
  if (!trailer) return undefined;
  if (trailer.site === "youtube")
    return `https://www.youtube.com/watch?v=${trailer.id}`;
  if (trailer.site === "dailymotion")
    return `https://www.dailymotion.com/video/${trailer.id}`;
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
    malId: anime.idMal ?? undefined,
    type: "anime",
    title,
    originalTitle: anime.title.native ?? undefined,
    overview: stripHtml(anime.description),
    posterUrl:
      anime.coverImage.extraLarge ??
      anime.coverImage.large ??
      "",
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

// Public API
export async function searchAnime(
  query: string,
  page = 1,
  perPage = 20,
): Promise<SearchResult> {
  const gql = `
    query SearchAnime($query: String!, $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo { total currentPage lastPage hasNextPage perPage }
        media(search: $query, type: ANIME, sort: SEARCH_MATCH) { ...MediaFields studios { edges { isMain node { name } } } }
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
    console.error("AniList searchAnime error:", error);
    return { results: [], totalResults: 0, totalPages: 0, page: 1 };
  }
}

export async function getAnimeDetails(id: string): Promise<Media | null> {
  const gql = `query GetAnimeDetails($id: Int!) { Media(id: $id, type: ANIME) { ...MediaDetailFields } } ${MEDIA_DETAIL_FRAGMENT}`;
  try {
    const numericId = parseInt(id.replace(/\D/g, ""), 10);
    const data = await anilistFetch<{ Media: AniListMedia }>(gql, {
      id: numericId,
    });
    return mapAniListToMedia(data.Media);
  } catch (error) {
    console.error(`AniList getAnimeDetails(${id}) error:`, error);
    return null;
  }
}

export async function getAnimeSeasons(id: string): Promise<Season[]> {
  const timelineNodeFragment = `fragment TimelineNode on Media { id idMal title { romaji english native } type format coverImage { extraLarge large medium color } bannerImage episodes averageScore startDate { year month day } }`;

  const gql = `${timelineNodeFragment} query GetTimelineNode($id: Int!) { Media(id: $id, type: ANIME) { ...TimelineNode relations { edges { relationType node { id type } } } } }`;

  const relationsQuery = `${timelineNodeFragment} query GetRelations($id_in: [Int]) { Page(page: 1, perPage: 50) { media(id_in: $id_in, type: ANIME) { ...TimelineNode relations { edges { relationType node { id type } } } } } }`;

  try {
    const numericId = parseInt(id.replace(/\D/g, ""), 10);
    const validRelationTypes = [
      "CURRENT",
      "SEQUEL",
      "PREQUEL",
      "SIDE_STORY",
      "PARENT",
      "ALTERNATIVE",
      "SPIN_OFF",
      "ADAPTATION",
      "SUMMARY",
    ];

    const allNodesMap = new Map<number, any>();
    const queue: { id: number; relType: string }[] = [];
    const visited = new Set<number>();

    const initialData = await anilistFetch<any>(gql, { id: numericId });
    const rootMedia = initialData.Media;
    if (!rootMedia) return [];

    allNodesMap.set(rootMedia.id, { ...rootMedia, relationType: "CURRENT" });
    visited.add(rootMedia.id);

    const initialRelations = rootMedia.relations?.edges || [];
    for (const edge of initialRelations) {
      if (
        edge.node.type === "ANIME" &&
        validRelationTypes.includes(edge.relationType) &&
        !visited.has(edge.node.id)
      ) {
        queue.push({ id: edge.node.id, relType: edge.relationType });
      }
    }

    while (queue.length > 0) {
      const batch = queue.splice(0, 50);
      const batchIds = batch.map((item) => item.id);
      batchIds.forEach((id) => visited.add(id));

      const batchData = await anilistFetch<any>(relationsQuery, {
        id_in: batchIds,
      });
      const mediaItems = batchData.Page?.media || [];

      for (const media of mediaItems) {
        const queuedItem = batch.find((b) => b.id === media.id);
        const actualRelation = queuedItem ? queuedItem.relType : "SEQUEL";

        if (!allNodesMap.has(media.id)) {
          allNodesMap.set(media.id, { ...media, relationType: actualRelation });
        }

        const relations = media.relations?.edges || [];
        for (const edge of relations) {
          if (
            edge.node.type === "ANIME" &&
            validRelationTypes.includes(edge.relationType) &&
            !visited.has(edge.node.id)
          ) {
            queue.push({ id: edge.node.id, relType: edge.relationType });
          }
        }
      }
    }

    const allMediaInTimeline = Array.from(allNodesMap.values());
    const validMedia = allMediaInTimeline.filter((node) =>
      validRelationTypes.includes(node.relationType),
    );

    const sortedMedia = validMedia.sort((a, b) => {
      const dateA = a.startDate?.year
        ? new Date(
            a.startDate.year,
            (a.startDate.month || 1) - 1,
            a.startDate.day || 1,
          ).getTime()
        : Infinity;
      const dateB = b.startDate?.year
        ? new Date(
            b.startDate.year,
            (b.startDate.month || 1) - 1,
            b.startDate.day || 1,
          ).getTime()
        : Infinity;
      if (dateA !== dateB) return dateA - dateB;
      return a.id - b.id;
    });

    return sortedMedia.map((node, index) => ({
      number: index + 1,
      name: resolveTitle(node.title),
      episodeCount: node.episodes ?? 0,
      overview:
        node.relationType === "CURRENT"
          ? "Current Series"
          : `${node.relationType.replace(/_/g, " ")} - ${resolveTitle(node.title)}`,
      posterUrl:
        node.coverImage.extraLarge ?? node.coverImage.large ?? undefined,
      airDate: undefined,
      mediaId: `anilist-${node.id}`,
      malId: node.idMal ?? undefined,
      mediaType: "anime",
      format: node.format,
      relationType: node.relationType,
    }));
  } catch (error) {
    console.error(`AniList getAnimeSeasons(${id}) error:`, error);
    return [];
  }
}

export async function getTrendingAnime(
  page = 1,
  perPage = 20,
): Promise<Media[]> {
  const gql = `query TrendingAnime($page: Int, $perPage: Int) { Page(page: $page, perPage: $perPage) { pageInfo { total currentPage lastPage hasNextPage perPage } media(type: ANIME, sort: TRENDING_DESC) { ...MediaFields studios { edges { isMain node { name } } } } } } ${MEDIA_FRAGMENT}`;
  try {
    const data = await anilistFetch<AniListPagedResponse>(gql, {
      page,
      perPage,
    });
    return data.Page.media.map(mapAniListToMedia);
  } catch (error) {
    console.error("AniList getTrendingAnime error:", error);
    return [];
  }
}

export async function discoverAnimeByGenres(
  genres: string[],
  page = 1,
  excludeIds: string[] = [],
): Promise<SearchResult> {
  const gql = `query DiscoverAnimeByGenres($genres: [String], $page: Int, $perPage: Int) { Page(page: $page, perPage: $perPage) { pageInfo { total currentPage lastPage hasNextPage perPage } media(type: ANIME, genre_in: $genres, sort: SCORE_DESC, isAdult: false, minimumTagRank: 50) { ...MediaFields studios { edges { isMain node { name } } } } } } ${MEDIA_FRAGMENT}`;
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
      .filter((m) => !excludeSet.has(m.id));
    return {
      results,
      totalResults: pageInfo.total,
      totalPages: pageInfo.lastPage,
      page: pageInfo.currentPage,
    };
  } catch (error) {
    console.error("AniList discoverAnimeByGenres error:", error);
    return { results: [], totalResults: 0, totalPages: 0, page: 1 };
  }
}

export async function getAnimeEpisodes(idMal: number | undefined): Promise<import('@/types/media').Episode[]> {
  if (!idMal) return [];
  try {
    let allEpisodes: any[] = [];
    let page = 1;
    let hasNextPage = true;
    
    // Fetch up to 30 pages (3000 episodes) to ensure long anime like One Piece are fully loaded
    while (hasNextPage && page <= 30) {
      const res = await fetch(`https://api.jikan.moe/v4/anime/${idMal}/episodes?page=${page}`, { next: { revalidate: 3600 } });
      if (!res.ok) {
        if (res.status === 429) {
          await new Promise(r => setTimeout(r, 1000));
          continue; // Retry on rate limit
        }
        break; // Stop on other errors
      }
      const json = await res.json();
      if (!json.data) break;
      
      allEpisodes = allEpisodes.concat(json.data);
      hasNextPage = json.pagination?.has_next_page || false;
      
      if (hasNextPage) {
        page++;
        // Delay to respect Jikan API rate limits (3 requests per second)
        await new Promise(r => setTimeout(r, 400));
      }
    }
    
    const animeArcs = arcData.find((a: any) => a.anime_id === idMal)?.arcs || [];
    
    return allEpisodes.map((ep: any) => {
      const arc: any = animeArcs.find((a: any) => ep.mal_id >= a.start && ep.mal_id <= a.end);
      return {
        number: ep.mal_id,
        name: ep.title,
        overview: ep.title_japanese || '',
        airDate: ep.aired,
        isFiller: ep.filler,
        isRecap: ep.recap,
        arcName: arc ? arc.name : undefined,
        sagaName: arc && arc.saga ? arc.saga : undefined,
      };
    });
  } catch (error) {
    console.error('getAnimeEpisodes failed for idMal:', idMal, error);
    return [];
  }
}
