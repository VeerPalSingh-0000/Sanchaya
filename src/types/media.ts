/** Supported media types in the tracker */
export type MediaType = 'movie' | 'series' | 'anime';

/** Possible watchlist statuses */
export type WatchlistStatus =
  | 'plan_to_watch'
  | 'watching'
  | 'completed'
  | 'on_hold'
  | 'dropped';

/** Genre representation */
export interface Genre {
  id: number;
  name: string;
}

/** Unified media item used across the entire app */
export interface Media {
  /** Internal DB id (optional for search results) */
  id?: string;
  /** External service id (TMDb or AniList) */
  externalId: string;
  /** Which type of media this is */
  type: MediaType;
  /** Display title */
  title: string;
  /** Original language title */
  originalTitle?: string;
  /** Overview / synopsis */
  overview?: string;
  /** Poster image path (relative for TMDb, absolute for AniList) */
  posterPath?: string;
  /** Backdrop image path */
  backdropPath?: string;
  /** Rating out of 10 */
  rating?: number;
  /** Total number of votes */
  voteCount?: number;
  /** Release date or first air date (ISO string) */
  releaseDate?: string;
  /** Year extracted for quick display */
  year?: number;
  /** Genre list */
  genres?: Genre[];
  /** Runtime in minutes (movies) or episode count (series/anime) */
  runtime?: number;
  /** Episode count for series/anime */
  episodeCount?: number;
  /** Season count for series */
  seasonCount?: number;
  /** Current airing status */
  status?: string;
  /** Data source */
  source?: 'tmdb' | 'anilist';
  /** User's personal watchlist status */
  watchlistStatus?: WatchlistStatus;
  /** User's personal rating (1-10) */
  userRating?: number;
}

/** Search results envelope */
export interface SearchResults {
  items: Media[];
  totalResults: number;
  page: number;
  totalPages: number;
}

/** Filter type for search/browse */
export type MediaFilter = 'all' | MediaType;
