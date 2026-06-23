import type { Media, Genre, Season, Episode, SearchResult } from '@/types/media';

// ─── Constants ──────────────────────────────────────────────────────────────

const BASE_URL = 'https://api.tmdb.org/3';
const IMAGE_BASE = 'https://image.tmdb.org/t/p/';

export const IMAGE_SIZES = {
  poster: {
    small: 'w185',
    medium: 'w342',
    large: 'w500',
    original: 'original',
  },
  backdrop: {
    small: 'w300',
    medium: 'w780',
    large: 'w1280',
    original: 'original',
  },
  still: {
    small: 'w185',
    medium: 'w300',
    large: 'w500',
    original: 'original',
  },
} as const;

// ─── TMDb Response Types (internal) ─────────────────────────────────────────

interface TMDbGenre {
  id: number;
  name: string;
}

interface TMDbMovie {
  id: number;
  title: string;
  original_title?: string;
  overview: string;
  poster_path: string | null;
  backdrop_path: string | null;
  origin_country?: string[];
  genre_ids?: number[];
  genres?: TMDbGenre[];
  vote_average: number;
  vote_count: number;
  release_date?: string;
  status?: string;
  runtime?: number;
  production_companies?: { name: string }[];
  videos?: {
    results: { type: string; site: string; key: string }[];
  };
  belongs_to_collection?: {
    id: number;
    name: string;
    poster_path: string | null;
    backdrop_path: string | null;
  } | null;
}

interface TMDbTV {
  id: number;
  name: string;
  original_name?: string;
  overview: string;
  poster_path: string | null;
  backdrop_path: string | null;
  origin_country?: string[];
  genre_ids?: number[];
  genres?: TMDbGenre[];
  vote_average: number;
  vote_count: number;
  first_air_date?: string;
  status?: string;
  number_of_seasons?: number;
  number_of_episodes?: number;
  seasons?: TMDbSeason[];
  production_companies?: { name: string }[];
  networks?: { name: string }[];
  videos?: {
    results: { type: string; site: string; key: string }[];
  };
}

interface TMDbSeason {
  season_number: number;
  name: string;
  episode_count: number;
  overview: string;
  poster_path: string | null;
  air_date: string | null;
}

interface TMDbEpisode {
  episode_number: number;
  name: string;
  overview: string;
  air_date: string | null;
  still_path: string | null;
  runtime: number | null;
  vote_average: number;
}

interface TMDbSeasonDetail {
  season_number: number;
  name: string;
  overview: string;
  poster_path: string | null;
  air_date: string | null;
  episodes: TMDbEpisode[];
}

interface TMDbMultiResult {
  id: number;
  media_type: 'movie' | 'tv' | 'person';
  // Movie fields
  title?: string;
  original_title?: string;
  release_date?: string;
  // TV fields
  name?: string;
  original_name?: string;
  first_air_date?: string;
  // Shared fields
  overview?: string;
  poster_path: string | null;
  backdrop_path: string | null;
  origin_country?: string[];
  genre_ids?: number[];
  vote_average: number;
  vote_count: number;
}

interface TMDbPagedResponse<T> {
  results: T[];
  total_results: number;
  total_pages: number;
  page: number;
}

// ─── Genre Map (TMDb genre_ids → names) ─────────────────────────────────────

const TMDB_GENRE_MAP: Record<number, string> = {
  28: 'Action', 12: 'Adventure', 16: 'Animation', 35: 'Comedy',
  80: 'Crime', 99: 'Documentary', 18: 'Drama', 10751: 'Family',
  14: 'Fantasy', 36: 'History', 27: 'Horror', 10402: 'Music',
  9648: 'Mystery', 10749: 'Romance', 878: 'Science Fiction',
  10770: 'TV Movie', 53: 'Thriller', 10752: 'War', 37: 'Western',
  // TV-specific
  10759: 'Action & Adventure', 10762: 'Kids', 10763: 'News',
  10764: 'Reality', 10765: 'Sci-Fi & Fantasy', 10766: 'Soap',
  10767: 'Talk', 10768: 'War & Politics',
};

export function getTmdbGenreIdByName(name: string): number | undefined {
  const entry = Object.entries(TMDB_GENRE_MAP).find(
    ([_, value]) => value.toLowerCase() === name.toLowerCase()
  );
  return entry ? parseInt(entry[0], 10) : undefined;
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function getApiKey(): string {
  const key = process.env.TMDB_API_KEY;
  if (!key) {
    throw new Error('TMDB_API_KEY environment variable is not set');
  }
  return key;
}

export function getImageUrl(
  path: string | null,
  size: string = IMAGE_SIZES.poster.medium,
): string {
  if (!path) return '/placeholder-poster.png';
  return `${IMAGE_BASE}${size}${path}`;
}

function genreIdsToGenres(ids: number[] | undefined): Genre[] {
  if (!ids) return [];
  return ids.map((id) => ({
    id,
    name: TMDB_GENRE_MAP[id] ?? 'Unknown',
  }));
}

function findTrailerKey(
  videos?: { results: { type: string; site: string; key: string }[] },
): string | undefined {
  if (!videos?.results?.length) return undefined;
  const trailer = videos.results.find(
    (v) => v.type === 'Trailer' && v.site === 'YouTube',
  );
  const teaser = videos.results.find(
    (v) => v.type === 'Teaser' && v.site === 'YouTube',
  );
  const chosen = trailer ?? teaser;
  return chosen ? `https://www.youtube.com/watch?v=${chosen.key}` : undefined;
}

async function tmdbFetch<T>(
  endpoint: string,
  params: Record<string, string> = {},
  retries: number = 5
): Promise<T> {
  const apiKey = getApiKey();
  const url = new URL(`${BASE_URL}${endpoint}`);
  url.searchParams.set('api_key', apiKey);
  url.searchParams.set('language', 'en-US');
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value);
  }

  for (let i = 0; i < retries; i++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout

      const res = await fetch(url.toString(), {
        next: { revalidate: 0 }, // bust cache for development
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!res.ok) {
        throw new Error(`TMDb API error: ${res.status} ${res.statusText}`);
      }

      return await res.json() as Promise<T>;
    } catch (error) {
      if (i === retries - 1) throw error;
      const err = error as Error;
      console.warn(`TMDb fetch attempt ${i + 1} failed for ${endpoint}. Retrying... [${err.name}: ${err.message}]`);
      // Exponential backoff with jitter to prevent thundering herd
      const jitter = Math.random() * 300;
      await new Promise(resolve => setTimeout(resolve, 500 * Math.pow(2, i) + jitter));
    }
  }
  
  throw new Error('TMDb fetch failed after retries');
}

// ─── Mappers ────────────────────────────────────────────────────────────────

function mapMovieToMedia(movie: TMDbMovie): Media {
  const genres: Genre[] =
    movie.genres?.map((g) => ({ id: g.id, name: g.name })) ??
    genreIdsToGenres(movie.genre_ids);

  return {
    id: `tmdb-movie-${movie.id}`,
    externalId: String(movie.id),
    type: 'movie',
    title: movie.title,
    originalTitle: movie.original_title,
    originCountry: movie.origin_country?.[0],
    overview: movie.overview ?? '',
    posterUrl: getImageUrl(movie.poster_path),
    backdropUrl: movie.backdrop_path
      ? getImageUrl(movie.backdrop_path, IMAGE_SIZES.backdrop.large)
      : undefined,
    genres,
    rating: Math.round(movie.vote_average * 10) / 10,
    voteCount: movie.vote_count,
    releaseDate: movie.release_date,
    status: movie.status ?? 'Released',
    studios: movie.production_companies?.map((c) => c.name),
    trailer: findTrailerKey(movie.videos),
    franchiseId: movie.belongs_to_collection ? `tmdb-collection-${movie.belongs_to_collection.id}` : undefined,
    franchiseTitle: movie.belongs_to_collection ? movie.belongs_to_collection.name : undefined,
    franchisePosterUrl: movie.belongs_to_collection ? getImageUrl(movie.belongs_to_collection.poster_path) : undefined,
  };
}

function mapTVToMedia(tv: TMDbTV): Media {
  const genres: Genre[] =
    tv.genres?.map((g) => ({ id: g.id, name: g.name })) ??
    genreIdsToGenres(tv.genre_ids);

  const seasons: Season[] | undefined = tv.seasons?.map((s) => ({
    number: s.season_number,
    name: s.name,
    episodeCount: s.episode_count,
    overview: s.overview ?? '',
    posterUrl: s.poster_path
      ? getImageUrl(s.poster_path, IMAGE_SIZES.poster.medium)
      : undefined,
    airDate: s.air_date ?? undefined,
  }));

  return {
    id: `tmdb-tv-${tv.id}`,
    externalId: String(tv.id),
    type: 'series',
    title: tv.name,
    originalTitle: tv.original_name,
    originCountry: tv.origin_country?.[0],
    overview: tv.overview ?? '',
    posterUrl: getImageUrl(tv.poster_path),
    backdropUrl: tv.backdrop_path
      ? getImageUrl(tv.backdrop_path, IMAGE_SIZES.backdrop.large)
      : undefined,
    genres,
    rating: Math.round(tv.vote_average * 10) / 10,
    voteCount: tv.vote_count,
    releaseDate: tv.first_air_date,
    status: tv.status ?? 'Unknown',
    seasons,
    totalEpisodes: tv.number_of_episodes,
    studios: [
      ...(tv.production_companies?.map((c) => c.name) ?? []),
      ...(tv.networks?.map((n) => n.name) ?? []),
    ],
    trailer: findTrailerKey(tv.videos),
  };
}

function mapMultiResultToMedia(item: TMDbMultiResult): Media | null {
  if (item.media_type === 'person') return null;

  const genres = genreIdsToGenres(item.genre_ids);

  if (item.media_type === 'movie') {
    return {
      id: `tmdb-movie-${item.id}`,
      externalId: String(item.id),
      type: 'movie',
      title: item.title ?? 'Unknown',
      originalTitle: item.original_title,
      originCountry: item.origin_country?.[0],
      overview: item.overview ?? '',
      posterUrl: getImageUrl(item.poster_path),
      backdropUrl: item.backdrop_path
        ? getImageUrl(item.backdrop_path, IMAGE_SIZES.backdrop.large)
        : undefined,
      genres,
      rating: Math.round(item.vote_average * 10) / 10,
      voteCount: item.vote_count,
      releaseDate: item.release_date,
      status: 'Released',
    };
  }

  return {
    id: `tmdb-tv-${item.id}`,
    externalId: String(item.id),
    type: 'series',
    title: item.name ?? 'Unknown',
    originalTitle: item.original_name,
    originCountry: item.origin_country?.[0],
    overview: item.overview ?? '',
    posterUrl: getImageUrl(item.poster_path),
    backdropUrl: item.backdrop_path
      ? getImageUrl(item.backdrop_path, IMAGE_SIZES.backdrop.large)
      : undefined,
    genres,
    rating: Math.round(item.vote_average * 10) / 10,
    voteCount: item.vote_count,
    releaseDate: item.first_air_date,
    status: 'Unknown',
  };
}

function mapSeasonDetail(detail: TMDbSeasonDetail): Season {
  return {
    number: detail.season_number,
    name: detail.name,
    episodeCount: detail.episodes.length,
    overview: detail.overview ?? '',
    posterUrl: detail.poster_path
      ? getImageUrl(detail.poster_path, IMAGE_SIZES.poster.medium)
      : undefined,
    airDate: detail.air_date ?? undefined,
    episodes: detail.episodes.map(mapEpisodeDetail),
  };
}

function mapEpisodeDetail(ep: TMDbEpisode): Episode {
  return {
    number: ep.episode_number,
    name: ep.name,
    overview: ep.overview ?? '',
    airDate: ep.air_date ?? undefined,
    stillUrl: ep.still_path
      ? getImageUrl(ep.still_path, IMAGE_SIZES.still.medium)
      : undefined,
    runtime: ep.runtime ?? undefined,
    rating: ep.vote_average
      ? Math.round(ep.vote_average * 10) / 10
      : undefined,
  };
}

// ─── Public API ─────────────────────────────────────────────────────────────

/**
 * Search across movies and TV shows simultaneously.
 */
export async function searchMulti(
  query: string,
  page: number = 1,
): Promise<SearchResult> {
  try {
    const data = await tmdbFetch<TMDbPagedResponse<TMDbMultiResult>>(
      '/search/multi',
      { query, page: String(page) },
    );

    const results = data.results
      .map(mapMultiResultToMedia)
      .filter((m): m is Media => m !== null);

    return {
      results,
      totalResults: data.total_results,
      totalPages: data.total_pages,
      page: data.page,
    };
  } catch (error) {
    console.error('TMDb searchMulti error:', error);
    return { results: [], totalResults: 0, totalPages: 0, page: 1 };
  }
}

/**
 * Search movies only.
 */
export async function searchMovies(
  query: string,
  page: number = 1,
): Promise<SearchResult> {
  try {
    const data = await tmdbFetch<TMDbPagedResponse<TMDbMovie>>(
      '/search/movie',
      { query, page: String(page) },
    );

    return {
      results: data.results.map(mapMovieToMedia),
      totalResults: data.total_results,
      totalPages: data.total_pages,
      page: data.page,
    };
  } catch (error) {
    console.error('TMDb searchMovies error:', error);
    return { results: [], totalResults: 0, totalPages: 0, page: 1 };
  }
}

/**
 * Search TV shows only.
 */
export async function searchTV(
  query: string,
  page: number = 1,
): Promise<SearchResult> {
  try {
    const data = await tmdbFetch<TMDbPagedResponse<TMDbTV>>('/search/tv', {
      query,
      page: String(page),
    });

    return {
      results: data.results.map(mapTVToMedia),
      totalResults: data.total_results,
      totalPages: data.total_pages,
      page: data.page,
    };
  } catch (error) {
    console.error('TMDb searchTV error:', error);
    return { results: [], totalResults: 0, totalPages: 0, page: 1 };
  }
}

/**
 * Get full movie details including videos and production companies.
 */
export async function getMovieDetails(id: string): Promise<Media | null> {
  const cleanId = id.replace('tmdb-movie-', '');
  try {
    const movie = await tmdbFetch<TMDbMovie>(`/movie/${cleanId}`, {
      append_to_response: 'videos',
    });
    return mapMovieToMedia(movie);
  } catch (error) {
    console.error(`TMDb getMovieDetails(${cleanId}) error:`, error);
    return null;
  }
}

/**
 * Get full TV show details including seasons, videos, and networks.
 */
export async function getTVDetails(id: string): Promise<Media | null> {
  const cleanId = id.replace('tmdb-tv-', '');
  try {
    const tv = await tmdbFetch<TMDbTV>(`/tv/${cleanId}`, {
      append_to_response: 'videos',
    });
    return mapTVToMedia(tv);
  } catch (error) {
    console.error(`TMDb getTVDetails(${cleanId}) error:`, error);
    return null;
  }
}

/**
 * Get full season details with all episodes.
 */
export async function getTVSeasonDetails(
  tvId: string,
  seasonNumber: number,
): Promise<Season | null> {
  const cleanId = tvId.replace('tmdb-tv-', '');
  try {
    const detail = await tmdbFetch<TMDbSeasonDetail>(
      `/tv/${cleanId}/season/${seasonNumber}`,
    );
    return mapSeasonDetail(detail);
  } catch (error) {
    console.error(
      `TMDb getTVSeasonDetails(${cleanId}, ${seasonNumber}) error:`,
      error,
    );
    return null;
  }
}

/**
 * Get trending movies, TV shows, or both.
 */
export async function getTrending(
  mediaType: 'movie' | 'tv' | 'all' = 'all',
  timeWindow: 'day' | 'week' = 'week',
  page: number = 1
): Promise<Media[]> {
  try {
    const data = await tmdbFetch<TMDbPagedResponse<TMDbMultiResult>>(
      `/trending/${mediaType}/${timeWindow}`,
      { page: String(page) }
    );

    // For 'movie' or 'tv' specific calls, TMDb doesn't include media_type in each result
    return data.results
      .map((item) => {
        const enriched = {
          ...item,
          media_type: item.media_type ?? (mediaType as 'movie' | 'tv'),
        };
        return mapMultiResultToMedia(enriched);
      })
      .filter((m): m is Media => m !== null);
  } catch (error) {
    console.error('TMDb getTrending error:', error);
    return [];
  }
}

/**
 * Discover movies or TV shows by genre IDs. Useful for generating recommendations.
 */
export async function discoverByGenres(
  mediaType: 'movie' | 'tv',
  genreIds: number[],
  page: number = 1,
  excludeIds: string[] = [],
): Promise<SearchResult> {
  try {
    const endpoint = mediaType === 'movie' ? '/discover/movie' : '/discover/tv';

    const data = await tmdbFetch<TMDbPagedResponse<TMDbMovie & TMDbTV>>(
      endpoint,
      {
        with_genres: genreIds.join(','),
        sort_by: 'vote_average.desc',
        'vote_count.gte': '100',
        page: String(page),
      },
    );

    const excludeSet = new Set(excludeIds);

    const results = data.results
      .map((item) => {
        if (mediaType === 'movie') {
          return mapMovieToMedia(item as TMDbMovie);
        }
        return mapTVToMedia(item as TMDbTV);
      })
      .filter((m) => !excludeSet.has(m.externalId));

    return {
      results,
      totalResults: data.total_results,
      totalPages: data.total_pages,
      page: data.page,
    };
  } catch (error) {
    console.error('TMDb discoverByGenres error:', error);
    return { results: [], totalResults: 0, totalPages: 0, page: 1 };
  }
}
