// ─── Media Types ────────────────────────────────────────────────────────────

export type MediaType = 'movie' | 'series' | 'anime';

export type MediaFilter = 'all' | MediaType;

export type WatchStatus =
  | 'plan_to_watch'
  | 'watching'
  | 'completed'
  | 'on_hold'
  | 'dropped';

// ─── Core Data Structures ───────────────────────────────────────────────────

export interface Genre {
  id: number;
  name: string;
}

export interface Media {
  id: string;
  externalId: string;
  type: MediaType;
  title: string;
  originalTitle?: string;
  overview: string;
  posterUrl: string;
  backdropUrl?: string;
  genres: Genre[];
  rating: number;
  voteCount: number;
  releaseDate?: string;
  status: string;
  seasons?: Season[];
  totalEpisodes?: number;
  studios?: string[];
  trailer?: string;
}

export interface Season {
  number: number;
  name: string;
  episodeCount: number;
  overview: string;
  posterUrl?: string;
  airDate?: string;
  episodes?: Episode[];
}

export interface Episode {
  number: number;
  name: string;
  overview: string;
  airDate?: string;
  stillUrl?: string;
  runtime?: number;
  rating?: number;
}

// ─── Watchlist ───────────────────────────────────────────────────────────────

export interface WatchlistItem {
  id: string;
  externalId: string;
  mediaType: MediaType;
  title: string;
  posterUrl: string;
  backdropUrl?: string;
  genres: Genre[];
  rating: number;
  status: WatchStatus;
  progress?: number;
  totalEpisodes?: number;
  addedAt: string;
  updatedAt: string;
}

// ─── Search & Recommendations ───────────────────────────────────────────────

export interface SearchResult {
  results: Media[];
  totalResults: number;
  totalPages: number;
  page: number;
}

export interface RecommendationResult {
  media: Media;
  matchedGenres: string[];
  matchScore: number;
  reason: string;
}
