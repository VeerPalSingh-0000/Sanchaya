# Sanchaya — Flutter Android App Implementation Plan

## Background & Goal

Convert the existing **Sanchaya** media tracker web app (Next.js + Prisma + Supabase) into a **proper native Flutter Android app**. The current web app tracks movies, TV series, and anime using TMDB and AniList APIs, with OAuth authentication (GitHub/Google), a PostgreSQL (Supabase) backend, and features like watchlist management, discover, recommendations, and detailed media pages with franchise grouping.

> [!NOTE]
> There is already a native Android app at [android-app/](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/android-app) — but it's just a **WebView wrapper** that loads `http://10.0.2.2:3000`. We will create a **fully native Flutter app** as a new project in `flutter-app/`.

---

## User Review Required

> [!IMPORTANT]
> **Flutter is NOT installed** on your system. Before I can write and run any Flutter code, you need to install Flutter. See [Phase 0 below](#phase-0-environment-setup-manual) for exact steps.

> [!IMPORTANT]
> **Architecture Decision — API Layer**: The current app uses Next.js server-side rendering and server actions. For Flutter, we have two choices:
> 1. **(Recommended) Direct API calls**: Flutter app calls TMDB/AniList/Supabase directly — no backend server needed, fully offline-capable caching.
> 2. **Keep the Next.js backend running**: Flutter calls your existing `/api/*` endpoints — requires the web server to always be running.
>
> **I recommend Option 1** since it makes the app fully independent and works without running the web server.

> [!WARNING]
> **Auth approach**: The web app uses NextAuth with GitHub/Google OAuth. For Flutter, we'll use **Supabase Auth** (since your DB is already on Supabase) with Google Sign-In. GitHub OAuth on mobile requires a custom URL scheme. We can support both, but Google is easier to set up first.

---

## Open Questions

1. **Do you want the Flutter app to share the same Supabase database** (so watchlist syncs between web and mobile), or should it be standalone with local storage only?
2. **Which auth providers do you want on mobile?** Google only, or both Google + GitHub?
3. **Do you want to keep the existing `android-app/` WebView**, or should we replace it entirely?
4. **Target minimum Android SDK?** I'll default to API 21 (Android 5.0) unless you prefer higher.

---

## Phase 0: Environment Setup (MANUAL)

These are steps **you** need to do before I can write/run code:

### Step 0.1 — Install Flutter SDK on Ubuntu Linux
You can install Flutter using the recommended Snap package:
1. Run the snap install command:
   ```bash
   sudo snap install flutter --classic
   ```
2. Initialize Flutter by running:
   ```bash
   flutter sdk-path
   ```
3. (Optional) Create an alias for Dart:
   ```bash
   sudo snap alias flutter.dart dart
   ```

### Step 0.2 — Android SDK Setup & Desktop Dependencies
1. Run `flutter doctor` and fix any issues it reports (accept licenses, etc.):
   ```bash
   flutter doctor --android-licenses
   ```
2. (Optional) Install Linux desktop development dependencies if you want to run/build for Linux desktop:
   ```bash
   sudo apt update
   sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev
   ```

### Step 0.3 — Verify
```bash
flutter doctor -v
```
All checkmarks should be green for **Flutter** and **Android toolchain**. Chrome/web and iOS are not needed.

---

## Phase 1: Project Scaffolding

### [NEW] `flutter-app/` — Flutter project

```
flutter-app/
├── android/                    # Android native project (auto-generated)
├── lib/
│   ├── main.dart               # App entry point
│   ├── app.dart                # MaterialApp with routing
│   ├── config/
│   │   ├── constants.dart      # API keys, base URLs
│   │   └── theme.dart          # Dark theme matching web app
│   ├── models/                 # Data models (Dart classes)
│   │   ├── media.dart          # Media, Genre, Season, Episode
│   │   ├── watchlist_item.dart # WatchlistItem
│   │   └── search_result.dart  # SearchResult, RecommendationResult
│   ├── services/               # API service layer
│   │   ├── tmdb_service.dart   # TMDB API calls
│   │   ├── anilist_service.dart# AniList GraphQL calls
│   │   ├── supabase_service.dart # Supabase auth + watchlist CRUD
│   │   └── cache_service.dart  # Local caching (Hive/SharedPrefs)
│   ├── providers/              # State management (Riverpod)
│   │   ├── auth_provider.dart
│   │   ├── watchlist_provider.dart
│   │   ├── trending_provider.dart
│   │   ├── search_provider.dart
│   │   └── media_detail_provider.dart
│   ├── screens/                # Full pages
│   │   ├── landing_screen.dart
│   │   ├── home_screen.dart
│   │   ├── search_screen.dart
│   │   ├── media_detail_screen.dart
│   │   ├── watchlist_screen.dart
│   │   ├── discover_screen.dart
│   │   ├── recommendations_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/                # Reusable UI components
│       ├── media_card.dart
│       ├── media_grid.dart
│       ├── hero_carousel.dart
│       ├── search_bar.dart
│       ├── watchlist_button.dart
│       ├── franchise_card.dart
│       ├── reaction_selector.dart
│       ├── skeleton_loader.dart
│       ├── bottom_nav_bar.dart
│       └── toast.dart
├── pubspec.yaml
└── README.md
```

### Dependencies (`pubspec.yaml`)

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `go_router` | Declarative routing |
| `dio` | HTTP client with interceptors |
| `cached_network_image` | Image loading + caching |
| `supabase_flutter` | Supabase auth + DB |
| `google_sign_in` | Google OAuth |
| `hive_flutter` | Local caching |
| `shimmer` | Skeleton loading effects |
| `carousel_slider` | Hero carousel |
| `flutter_animate` | Smooth animations |
| `google_fonts` | Inter/Outfit typography |
| `url_launcher` | Open trailers in browser |

---

## Phase 2: Models Layer

### [NEW] `lib/models/media.dart`
Port [media.ts](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/types/media.ts) to Dart:
- `enum MediaType { movie, series, anime }`
- `enum MediaFilter { all, movie, series, anime }`
- `enum WatchStatus { planToWatch, watching, completed, onHold, dropped }`
- `class Genre { final int id; final String name; }`
- `class Media { ... }` — all fields from the TS interface
- `class Season { ... }`
- `class Episode { ... }`
- JSON serialization with `fromJson` / `toJson` factory methods

### [NEW] `lib/models/watchlist_item.dart`
- `class WatchlistItem { ... }` — matches the Prisma schema [schema.prisma](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/prisma/schema.prisma) fields
- Includes `Reaction` enum: `love, good, bad`

### [NEW] `lib/models/search_result.dart`
- `class SearchResult { final List<Media> results; ... }`
- `class RecommendationResult { ... }`

---

## Phase 3: Services Layer (API Integration)

### [NEW] `lib/services/tmdb_service.dart`
Port the entire [tmdb.ts](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/lib/tmdb.ts) (716 lines):
- `TmdbService` class with all public methods:
  - `searchMulti(query)` → `SearchResult`
  - `searchMovies(query)` → `SearchResult`
  - `searchTV(query)` → `SearchResult`
  - `getMovieDetails(id)` → `Media?`
  - `getTVDetails(id)` → `Media?`
  - `getTVSeasonDetails(tvId, season)` → `Season?`
  - `getTrending(type, timeWindow)` → `List<Media>`
  - `discoverByGenres(type, genreIds)` → `SearchResult`
  - `getCollectionDetails(id)` → `List<Season>?`
  - `getCollection(id)` → raw collection data
- Same genre map, image URL builder, and response mappers
- Uses `Dio` with retry interceptor (exponential backoff matching web logic)
- API key stored in `constants.dart`

### [NEW] `lib/services/anilist_service.dart`
Port [anilist.ts](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/lib/anilist.ts) (522 lines):
- `AnilistService` class:
  - `searchAnime(query)` → `SearchResult`
  - `getAnimeDetails(id)` → `Media?`
  - `getAnimeSeasons(id)` → `List<Season>`
  - `getTrendingAnime(page, perPage)` → `List<Media>`
- GraphQL queries via Dio POST to `https://graphql.anilist.co`

### [NEW] `lib/services/supabase_service.dart`
Direct Supabase integration (replaces Next.js API routes):
- Auth: `signInWithGoogle()`, `signOut()`, `getCurrentUser()`
- Watchlist CRUD:
  - `getWatchlist(userId)` → `List<WatchlistItem>`
  - `addToWatchlist(item)` → upsert by `(userId, mediaId, mediaType)`
  - `updateWatchlistItem(id, fields)` → partial update
  - `removeFromWatchlist(userId, mediaId)` → delete
- Maps to the same `WatchlistItem` table in [schema.prisma](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/prisma/schema.prisma)

### [NEW] `lib/services/cache_service.dart`
- Hive-based local cache for:
  - Trending data (TTL: 1 hour)
  - Recently viewed media details (TTL: 24 hours)
  - Search results (TTL: 30 minutes)

---

## Phase 4: State Management (Riverpod Providers)

### [NEW] `lib/providers/auth_provider.dart`
- `authStateProvider` — streams Supabase auth state changes
- `currentUserProvider` — derived provider for user data
- Login/logout actions

### [NEW] `lib/providers/watchlist_provider.dart`
Port the logic from [WatchlistContext.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/lib/contexts/WatchlistContext.tsx):
- `watchlistProvider` — `AsyncNotifier<List<WatchlistItem>>`
- Methods: `add`, `remove`, `updateStatus`, `updateProgress`, `updateReaction`, `isInWatchlist`
- Optimistic UI updates matching the web app's pattern

### [NEW] `lib/providers/trending_provider.dart`
- `trendingMoviesProvider`, `trendingTVProvider`, `trendingAnimeProvider`
- Auto-refresh with caching

### [NEW] `lib/providers/search_provider.dart`
Port logic from [actions.ts](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/app/actions.ts):
- `searchQueryProvider` — text state
- `searchFilterProvider` — filter state
- `searchResultsProvider` — derived async with debouncing
- Same anime-deduplication logic (filter TMDB Japanese Animation when showing AniList)

### [NEW] `lib/providers/media_detail_provider.dart`
- `mediaDetailProvider(id, type)` — fetches full details with franchise metadata

---

## Phase 5: UI Screens

### Design System — [NEW] `lib/config/theme.dart`
Dark-mode-first Material 3 theme matching the web app:
- Background: `#0a0a0f` (deep black-blue)
- Surface: `#14141f`
- Primary: Purple/violet gradient accent
- Text: Off-white `#e8e8f0`
- Typography: Inter (via `google_fonts`)
- Rounded corners: 12-16px
- Card glass effect: semi-transparent surfaces with subtle borders

### Screen-by-Screen Breakdown

#### 5.1 — Landing Screen (Unauthenticated)
Port [LandingPage.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/components/landing/LandingPage.tsx):
- Hero section with app branding
- "Sign in with Google" button
- Feature highlights

#### 5.2 — Home Screen (Authenticated Dashboard)
Port [page.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/app/page.tsx):
- Search bar at the top
- Hero carousel with trending items
- Horizontal scrolling rows: Popular Movies, Popular Series, Popular Anime
- Pull-to-refresh
- Skeleton loading states

#### 5.3 — Search Screen
Port [SearchBar.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/components/media/SearchBar.tsx):
- Full-screen search with filter tabs (All, Movies, Series, Anime)
- Debounced live results
- Media cards in results grid

#### 5.4 — Media Detail Screen
Port [media/[type]/[id]/page.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/app/media/%5Btype%5D/%5Bid%5D/page.tsx):
- Backdrop image with gradient overlay
- Title, rating, genres, overview
- Watchlist button with status picker
- Franchise/collection timeline (for anime: [AnimeTimeline.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/app/media/%5Btype%5D/%5Bid%5D/AnimeTimeline.tsx))
- Season/episode expandable lists
- Trailer link

#### 5.5 — Watchlist Screen
Port [watchlist/page.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/app/watchlist/page.tsx):
- Status filter tabs: All, Plan to Watch, Watching, Completed, Dropped
- Media type filter: All, Movies, Series, Anime
- Grid/List view toggle
- Franchise grouping for anime
- Reaction badges (❤️ / 👍 / 👎)
- Progress tracking (e.g., 12/24 episodes)

#### 5.6 — Discover Screen
Port [discover/](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/app/discover):
- Genre-based discovery
- Grid of recommended content
- "Load more" pagination

#### 5.7 — Recommendations Screen
Port [recommendations/](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/app/recommendations):
- AI-style recommendations based on watchlist genres
- Match score indicators
- Reason tags

#### 5.8 — Settings Screen
Port [settings/page.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/app/settings/page.tsx):
- Account info
- Sign out
- Cache management
- App version

---

## Phase 6: Widgets (Reusable Components)

| Widget | Ports From | Description |
|--------|-----------|-------------|
| `MediaCard` | [MediaCard.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/components/media/MediaCard.tsx) | Poster card with title, rating, type badge |
| `MediaGrid` | [MediaGrid.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/components/media/MediaGrid.tsx) | Responsive grid/horizontal scroll layout |
| `HeroCarousel` | [HeroCarousel.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/components/media/HeroCarousel.tsx) | Full-width carousel with backdrop images |
| `WatchlistButton` | [WatchlistButton.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/components/media/WatchlistButton.tsx) | Add/update watchlist with status dropdown |
| `FranchiseCard` | [FranchiseCard.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/components/media/FranchiseCard.tsx) | Grouped franchise poster |
| `ReactionSelector` | [ReactionSelector.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/components/media/ReactionSelector.tsx) | Love/Good/Bad reaction picker |
| `BottomNavBar` | New | Bottom navigation (Home, Search, Watchlist, Settings) |
| `SkeletonLoader` | [Skeleton.tsx](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/components/ui/Skeleton.tsx) | Shimmer loading placeholders |

---

## Phase 7: Navigation & Routing

Using `go_router`:

```
/                   → Landing (if not logged in) or Home
/search             → Search screen
/media/:type/:id    → Media detail screen
/watchlist           → Watchlist screen
/discover            → Discover screen
/recommendations     → Recommendations screen
/settings            → Settings screen
```

Bottom navigation bar with 4 tabs: **Home**, **Search**, **Watchlist**, **Settings**

---

## Phase 8: Polish & Animations

- Page transition animations (slide/fade)
- Hero animations for media card → detail screen
- Shimmer skeleton loading on every data fetch
- Pull-to-refresh on scrollable screens
- Haptic feedback on watchlist actions
- Smooth gradient overlays on backdrop images
- Card hover-like press effects (scale + elevation)

---

## Phase 9: Build & Deploy

### Step 9.1 — App Icon & Splash
- Use `flutter_launcher_icons` to generate icons from the existing [favicon.ico](file:///c:/Users/Veer Pal Singh/Desktop/media-tracker/src/app/favicon.ico)
- Configure native splash screen

### Step 9.2 — Release Build
```powershell
cd flutter-app
flutter build apk --release
```

### Step 9.3 — Install on Device
```powershell
flutter install
```

---

## Implementation Order

| # | Phase | Estimated Effort | What I Build |
|---|-------|-----------------|--------------|
| 0 | Environment Setup | **You do this** | Install Flutter SDK |
| 1 | Project Scaffolding | ~15 min | `flutter create`, pubspec, folder structure |
| 2 | Models | ~20 min | All Dart data classes |
| 3 | Services | ~45 min | TMDB, AniList, Supabase services |
| 4 | Providers | ~30 min | Riverpod state management |
| 5 | UI Screens | ~2 hours | All 8 screens |
| 6 | Widgets | ~1 hour | All reusable components |
| 7 | Routing | ~15 min | GoRouter setup |
| 8 | Polish | ~30 min | Animations, transitions, loading states |
| 9 | Build | ~10 min | APK generation |

---

## Verification Plan

### Automated
```powershell
cd flutter-app
flutter analyze       # Static analysis (no errors)
flutter test          # Unit tests for services/providers
flutter build apk     # Successful APK build
```

### Manual
1. Run on emulator/device: `flutter run`
2. Test Google Sign-In flow
3. Test search across all media types
4. Test watchlist CRUD operations
5. Test media detail page with franchise timeline
6. Test offline caching behavior
7. Verify UI matches the dark theme of the web app
