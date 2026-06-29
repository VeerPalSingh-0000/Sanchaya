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
  malId?: number;
  type: MediaType;
  title: string;
  originalTitle?: string;
  originCountry?: string;
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
  franchiseId?: string;
  franchiseTitle?: string;
  franchisePosterUrl?: string;
}

export interface Season {
  number: number;
  name: string;
  episodeCount: number;
  overview: string;
  posterUrl?: string;
  airDate?: string;
  episodes?: Episode[];
  mediaId?: string;
  malId?: number;
  mediaType?: MediaType;
  format?: string;
  relationType?: string;
}

export interface Episode {
  number: number;
  name: string;
  overview: string;
  airDate?: string;
  stillUrl?: string;
  runtime?: number;
  rating?: number;
  isFiller?: boolean;
  isRecap?: boolean;
  arcName?: string;
  sagaName?: string;
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
  franchiseId?: string;
  franchiseTitle?: string;
  franchisePosterUrl?: string;
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
