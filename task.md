# Media Tracker — Task List

## Phase 1: Foundation & API Integration
- [x] **Setup & Configuration**
  - [x] Configure `tailwind.config.ts` with all Stitch design tokens (OLED palette, typography, spacing, glass panels).
  - [x] Update `src/styles/globals.css` to import Tailwind directives and global `.glass-panel`, `.shimmer` utilities.
  - [x] Update `src/app/layout.tsx` to include the Material Symbols font link.
- [x] **Component Migration**
  - [x] Rewrite `Navbar.tsx` to include the desktop top nav and the mobile bottom nav using tailwind.
  - [x] Delete or ignore `Navbar.module.css`.
  - [x] Create `HeroCarousel.tsx` mimicking the Stitch trending carousel.
  - [x] Rewrite `MediaCard.tsx` completely to match the new `glass-panel` hover overlay layout.
  - [x] Rewrite `MediaGrid.tsx` to use `grid-cols-2 md:grid-cols-5` layout patterns.
  - [x] Rewrite `MediaRow.tsx` to adopt the new responsive horizontal scroll layout.
- [x] **Page Migration**
  - [x] `src/app/page.tsx`: Integrate the new `HeroCarousel` and apply full OLED background animations and styling.
  - [x] `src/app/discover/DiscoverClient.tsx`: Implement the Bento grid layout for the featured item and category pills.
  - [x] `src/app/watchlist/page.tsx`: Apply the new header layout, stats, and view/filter toggles.
  - [x] `src/app/recommendations/RecommendationsClient.tsx`: Add the gradient header, shimmer loading states, and new `MediaRow`.
  - [x] `src/app/settings/page.tsx`: Implement the premium slide-out/list style panel for settings with glassmorphic sections.

## Phase 2: Database & Watchlist (Supabase)
- [x] Set up Supabase project & get connection string
- [x] Create Prisma schema with User, WatchlistItem models
- [x] Run Prisma migrations
- [x] Set up NextAuth.js with GitHub & Google providers
- [x] Build Watchlist API routes (CRUD)
- [x] Build Watchlist page with filtering & status management
- [x] Add "Add to Watchlist" buttons on media cards/detail pages

## Phase 3: 3D Visuals & Premium UI
- [x] Set up React Three Fiber canvas & scene
- [x] Build 3D PosterCarousel for home page
- [x] Build FloatingGallery for watchlist
- [x] Add Framer Motion page transitions
- [x] Polish micro-animations (card hovers, loading states)
- [x] Add glassmorphism card effects
- [x] Responsive & mobile optimization

## Phase 4: Recommendation Engine
- [x] Implement genre extraction & weighting algorithm
- [x] Build TMDb discover integration
- [x] Build AniList genre-based discovery
- [x] Create recommendation API route
- [x] Build Recommendations page with explanation UI
- [x] Add "Refresh" and "Add to Watchlist" actions
