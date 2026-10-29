# Sanchaya (Media Tracker) - Comprehensive Specification Document

This document outlines the complete, minute-by-minute feature set, architecture, data models, and UI/UX patterns of the **Sanchaya** (Media Tracker) platform. It is designed to be easily parsed by both humans and AI agents to perfectly replicate or extend the platform into native Android, iOS, or Desktop applications.

## 1. Product Overview
Sanchaya is a centralized hub for tracking, discovering, and rating Movies, TV Series, and Anime. It unifies the typically fragmented experience of tracking Western media and Japanese anime by seamlessly integrating both the TMDB and AniList APIs into a unified interface.

## 2. Tech Stack & Architecture
- **Web Application:** Next.js (App Router), React, Tailwind CSS, Framer Motion, NextAuth.js, Prisma (PostgreSQL).
- **Mobile Application:** Flutter, Riverpod (State Management), Supabase (PostgreSQL), Dio (Networking).
- **Database:** PostgreSQL (shared across platforms).
- **APIs Used:** 
  - TMDB (The Movie Database) - For Movies and Western TV Shows.
  - AniList (GraphQL) - For Anime, accurate anime seasons, and relations.

## 3. Data Models & Schemas

### 3.1 Database Schema (Prisma / Supabase)
- **User:** `id`, `name`, `email`, `image`, `createdAt`, `updatedAt` (NextAuth/Supabase Auth standard).
- **WatchlistItem:**
  - `id` (CUID), `userId`
  - `mediaId`: Unique external ID (e.g., `tmdb-movie-123`, `tmdb-tv-456`, `anilist-789`).
  - `mediaType`: `movie`, `series`, `anime`.
  - `title`, `posterPath`, `releaseDate`
  - `status`: `PLAN_TO_WATCH`, `WATCHING`, `COMPLETED`, `ON_HOLD`, `DROPPED`.
  - `rating`: User score out of 10.
  - `progress`: Number of episodes watched.
  - `totalEpisodes`: Total episodes available.
  - `reaction`: `LOVE`, `GOOD`, `BAD` (Quick emotional reactions).
  - `franchiseId`, `franchiseTitle`, `franchisePosterUrl`: Used to group related media (like Anime Seasons or Movie Collections) into a single folder.
  - **Constraint:** Unique `[userId, mediaId, mediaType]`

### 3.2 Client-Side Models (TypeScript / Dart)
- **MediaType:** Enum (`movie`, `series`, `anime`).
- **WatchStatus:** Enum (`plan_to_watch`, `watching`, `completed`, `on_hold`, `dropped`).
- **Genre:** `id`, `name`.
- **Season:** `number`, `name`, `episodeCount`, `overview`, `posterUrl`, `airDate`, `episodes`, `mediaId`, `malId`, `format`, `relationType` (Used heavily for Anime timelines).
- **Episode:** `number`, `name`, `overview`, `airDate`, `stillUrl`, `runtime`, `rating`.
- **Media:** Unified model representing a show/movie containing `id`, `externalId`, `title`, `overview`, `posterUrl`, `backdropUrl`, `genres`, `rating`, `voteCount`, `status`, `seasons`, `totalEpisodes`, `trailer`, and `franchise` metadata.

## 4. Core Features & Screens

### 4.1 Authentication & Profile
- **Web:** Magic Link or OAuth (Google, GitHub) via NextAuth.
- **Mobile:** Supabase Auth with standard email/password or OAuth.
- **Profile UI:** Custom Profile App Bar displaying user avatar, name, and total watchlist statistics.

### 4.2 Home / Landing Screen
- **Hero Carousel:** A wide, cinematic carousel showing Trending media. Prioritizes `backdropUrl` over posters for a landscape cinematic look. Auto-scrolls, with scale and blur effects on non-centered items.
- **Trending Sections:** Horizontal scrollable rows for "Trending Movies", "Trending Series", and "Trending Anime".
- **Dynamic Greeting:** Greets the user based on time of day (Good Morning/Evening).
- **Continue Watching:** A dedicated row showing items currently marked as `WATCHING` from the user's watchlist, allowing quick access to update progress.

### 4.3 Discover Screen
- **Genre Filters:** A pill-row or grid of genres (Action, Adventure, Fantasy, etc.).
- **Infinite Scrolling:** Automatically loads more items as the user scrolls.
- **Media Grid:** Displays `MediaCard` components in a responsive grid structure.

### 4.4 Search Functionality
- **Unified Search:** A single search bar that queries TMDb (Multi-search) and AniList simultaneously.
- **Debounced Input:** Prevents API spam by waiting for the user to stop typing.
- **Categorized Results:** Search results visually indicate if they are an Anime, Movie, or Series via floating badges on the corner of the posters.

### 4.5 Media Details Screen (The Core Experience)
When a user clicks on a media card, they are taken to the Details screen.
- **Cinematic Header (BeautifulOverview):** A large backdrop image that fades into the background using gradients. The poster image overlaps this gradient.
- **Title & Metadata:** Displays Title, Genres (as chips), Release Year, Total Episodes, Rating (with a Star icon), and Status (Airing/Released).
- **Trailer Integration:** A "Play Trailer" button that links out to YouTube.
- **Overview:** Expandable/collapsible text description of the media.
- **Watchlist Action Bottom Sheet:** 
  - A prominent "Add to Watchlist" button. 
  - If added, it opens a Bottom Sheet / Modal allowing the user to:
    - Change `WatchStatus` (Plan to Watch, Watching, Completed, etc.).
    - Update Episode Progress via an `EpisodeTrackerWidget` (+ / - buttons).
    - Leave a `ReactionSelector` (Heart, Thumbs Up, Thumbs Down).
- **Seasons & Episodes (TV/Anime):** 
  - **TMDb:** Displays seasons sequentially.
  - **AniList (Franchise Timeline):** A revolutionary feature that maps an anime's complex timeline (Prequels, Sequels, Spin-offs). It queries AniList's graph to build a chronological watch order and groups them under a single `franchiseId`.

### 4.6 Watchlist Screen
- **Grid Layout:** Displays the user's saved items in a responsive grid.
- **Filter Pills:** Allows filtering by "All", "Plan to Watch", "Watching", "Completed", etc.
- **Search within Watchlist:** A local search bar to filter saved items by title.
- **Franchise Grouping (Smart Folders):** If a user adds multiple seasons of the same Anime (which have the same `franchiseId`), they are visually grouped into a single `FranchiseCard`. Clicking the card opens the group.
- **Progress Badges:** Items in the watchlist display a progress bar overlay or a "EP X/Y" badge directly on the poster if they are currently being watched.
- **Deduplication Logic:** The app normalizes IDs (stripping `tmdb-tv-`, `anilist-`) to prevent legacy duplicate entries from appearing twice on the screen.

## 5. UI/UX Design System & Micro-Interactions

### 5.1 The Aesthetic
- **Glassmorphism:** Extensive use of translucent backgrounds with background-blur (`backdrop-blur-md`, `bg-white/5` or `bg-surface/50`) to create a premium, modern feel.
- **Dark Theme:** A deep, rich dark mode tailored with primary accent colors (often a vibrant amber or primary brand color).
- **Typography:** Modern sans-serif fonts for a clean look. 

### 5.2 Micro-Interactions
- **Hover Effects:** Posters gently scale up (`scale-110`) on hover.
- **Shimmer Loading:** Skeleton screens (`MediaCardSkeleton`, `shimmer_card.dart`) display a sweeping gradient animation while data is fetching.
- **Framer Motion / Flutter Animations:** Spring physics are used when cards enter the screen or when modals pop up to give the app a natural, bouncy, and responsive feel.
- **Badges:** Small uppercase tracking-spaced badges (e.g., `ANIME`, `SERIES`) float over posters to quickly convey media type.

## 6. Logic & Integration Quirks (For AI Agents)

When an AI builds this into a new platform (e.g., Kotlin Android, Swift iOS, Electron Desktop), they MUST respect these logic rules:
1. **The AniList vs TMDb Split:** Movies and Western TV use TMDb. Japanese Anime uses AniList. This must be determined aggressively (e.g., checking `originCountry == 'JP'` and genres for 'Animation').
2. **Franchise ID Generation:** For Anime, when a show is fetched, you must query its `relations` node to find the root/parent show. Use that root's ID as the `franchiseId`. This ensures Season 1, 2, and 3 all map to the same smart folder in the Watchlist.
3. **Database Upserts:** Always use an `upsert` or `ON CONFLICT` strategy when saving to the Watchlist to ensure the unique constraint `[userId, mediaId, mediaType]` is respected.
4. **Optimistic UI:** When updating Episode Progress or Status, immediately update the local state before the network call completes to ensure the UI feels instantly responsive. Rollback on failure.
