"use client";

import { useWatchlist } from "@/lib/contexts/WatchlistContext";
import MediaCard from "@/components/media/MediaCard";
import FranchiseCard from "@/components/media/FranchiseCard";
import Link from "next/link";
import { useEffect, useState, useMemo } from "react";
import { PlaySquare, Search, X } from "lucide-react";
import type { WatchStatus, WatchlistItem } from "@/types/media";
import { getWatchlistFranchiseGroupings, FranchiseGroup } from "./actions";

// Define our display union type
type DisplayItem = 
  | { type: 'single'; item: WatchlistItem }
  | { type: 'franchise'; group: FranchiseGroup; items: WatchlistItem[] };

const FILTER_TABS: { value: WatchStatus | "all"; label: string }[] = [
  { value: "all", label: "All Items" },
  { value: "watching", label: "Watching" },
  { value: "plan_to_watch", label: "Plan to Watch" },
  { value: "on_hold", label: "On Hold" },
  { value: "completed", label: "Completed" },
  { value: "dropped", label: "Dropped" },
];

export default function WatchlistPage() {
  const { watchlist, isLoading } = useWatchlist();
  const [mounted, setMounted] = useState(false);
  const [filter, setFilter] = useState<WatchStatus | "all">("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [isMigrating, setIsMigrating] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Fallback auto-migration for old items
  useEffect(() => {
    if (!mounted) return;
    const itemsToMigrate = watchlist.filter(i => i.mediaType === 'anime' && !i.franchiseId);
    if (itemsToMigrate.length === 0) return;

    setIsMigrating(true);
    const missingIds = itemsToMigrate.map(i => String(i.externalId).replace(/anilist-/g, ''));
    getWatchlistFranchiseGroupings(missingIds).then(newGroups => {
      const updatePromises: Promise<any>[] = [];
      
      itemsToMigrate.forEach(item => {
        const cleanExtId = String(item.externalId).replace(/anilist-/g, '');
        const group = newGroups.find(g => g.memberIds.includes(cleanExtId));
        if (group) {
          // Queue a silent background update to POST the new franchise data permanently
          updatePromises.push(
            fetch('/api/watchlist', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                mediaId: String(item.externalId),
                mediaType: item.mediaType,
                title: item.title,
                posterPath: item.posterUrl,
                status: item.status.toUpperCase(),
                franchiseId: group.rootId,
                franchiseTitle: group.rootTitle,
                franchisePosterUrl: group.rootPosterUrl,
              })
            })
          );
        }
      });

      if (updatePromises.length > 0) {
        Promise.all(updatePromises).then(() => {
          const attempts = parseInt(sessionStorage.getItem('sanchaya_migration_attempts') || '0');
          if (attempts < 3) {
            sessionStorage.setItem('sanchaya_migration_attempts', String(attempts + 1));
            window.location.reload();
          } else {
            setIsMigrating(false);
            console.error("Migration failed after 3 attempts. Stopping loop.");
          }
        });
      } else {
        setIsMigrating(false);
      }
    }).catch(() => setIsMigrating(false));
  }, [watchlist, mounted]);

  const allGroups = useMemo(() => {
    const list: (DisplayItem & { aggregateStatus: WatchStatus })[] = [];
    const groupedIds = new Set<string>();

    const franchiseMap = new Map<string, { title: string, posterUrl: string, items: WatchlistItem[] }>();

    // Deduplicate watchlist to prevent duplicate posters from legacy vs new IDs
    const uniqueWatchlist: WatchlistItem[] = [];
    const seenKeys = new Map<string, number>();

    watchlist.forEach(item => {
      const extId = item.externalId || item.id;
      const cleanExtId = String(extId).replace(/^(tmdb-tv-|tmdb-movie-|anilist-)+/g, '');
      const key = `${cleanExtId}-${item.mediaType}`;
      
      if (!seenKeys.has(key)) {
        seenKeys.set(key, uniqueWatchlist.length);
        uniqueWatchlist.push(item);
      } else {
        const prevIdx = seenKeys.get(key)!;
        const prev = uniqueWatchlist[prevIdx];
        const timePrev = new Date(prev.updatedAt || prev.addedAt).getTime();
        const timeNew = new Date(item.updatedAt || item.addedAt).getTime();
        if (timeNew > timePrev) {
          uniqueWatchlist[prevIdx] = item;
        }
      }
    });

    uniqueWatchlist.forEach(item => {
      if (item.franchiseId) {
        if (!franchiseMap.has(item.franchiseId)) {
          franchiseMap.set(item.franchiseId, {
             title: item.franchiseTitle || item.title,
             posterUrl: item.franchisePosterUrl || item.posterUrl,
             items: []
          });
        }
        const fGroup = franchiseMap.get(item.franchiseId)!;
        const normTitle = (item.title || '').trim().toLowerCase();
        const extId = String(item.externalId || item.id);
        const cleanExtId = extId.replace(/^(tmdb-tv-|tmdb-movie-|anilist-)+/g, '');

        // Check if an existing item represents the same part/season
        const existingIdx = fGroup.items.findIndex(existing => {
          const exExtId = String(existing.externalId || existing.id);
          const exClean = exExtId.replace(/^(tmdb-tv-|tmdb-movie-|anilist-)+/g, '');
          if (cleanExtId && exClean && cleanExtId === exClean) return true;
          const exNorm = (existing.title || '').trim().toLowerCase();
          return normTitle && exNorm && normTitle === exNorm;
        });

        if (existingIdx !== -1) {
          const existing = fGroup.items[existingIdx];
          // If the new item is anime and existing is series/movie, prefer anime
          if (item.mediaType === 'anime' && existing.mediaType !== 'anime') {
            fGroup.items[existingIdx] = item;
          } else if (existing.mediaType === 'anime' && item.mediaType !== 'anime') {
            // Keep existing anime item
          } else {
            const timeExisting = new Date(existing.updatedAt || existing.addedAt).getTime();
            const timeNew = new Date(item.updatedAt || item.addedAt).getTime();
            if (timeNew >= timeExisting) {
              fGroup.items[existingIdx] = item;
            }
          }
        } else {
          fGroup.items.push(item);
        }
        groupedIds.add(item.id);
      }
    });

    franchiseMap.forEach((data, franchiseId) => {
      if (data.items.length > 0) {
        // Sort items in chronological watch order
        data.items.sort((a, b) => {
          const timeA = a.releaseDate ? new Date(a.releaseDate).getTime() : NaN;
          const timeB = b.releaseDate ? new Date(b.releaseDate).getTime() : NaN;
          if (!isNaN(timeA) && !isNaN(timeB) && timeA !== timeB) {
            return timeA - timeB;
          }

          const cleanRootId = (franchiseId || '').replace(/^(anilist-|tmdb-movie-|tmdb-tv-)+/, '');
          const aClean = String(a.externalId || a.id).replace(/^(anilist-|tmdb-movie-|tmdb-tv-)+/, '');
          const bClean = String(b.externalId || b.id).replace(/^(anilist-|tmdb-movie-|tmdb-tv-)+/, '');
          if (cleanRootId) {
            if (aClean === cleanRootId) return -1;
            if (bClean === cleanRootId) return 1;
          }

          const aSeasonMatch = String(a.externalId || a.id).match(/-season-(\d+)/);
          const bSeasonMatch = String(b.externalId || b.id).match(/-season-(\d+)/);
          if (aSeasonMatch && bSeasonMatch) {
            const sDiff = parseInt(aSeasonMatch[1], 10) - parseInt(bSeasonMatch[1], 10);
            if (sDiff !== 0) return sDiff;
          }

          const aId = parseInt(aClean, 10);
          const bId = parseInt(bClean, 10);
          if (!isNaN(aId) && !isNaN(bId) && aId !== bId) {
            return aId - bId;
          }

          return a.title.localeCompare(b.title, undefined, { numeric: true, sensitivity: 'base' });
        });

        // Compute aggregate status across the entire franchise
        // Priority: watching > on_hold > completed > plan_to_watch > dropped
        let aggregateStatus: WatchStatus = 'plan_to_watch';
        
        if (data.items.some(i => i.status === 'watching')) {
          aggregateStatus = 'watching';
        } else if (data.items.some(i => i.status === 'on_hold')) {
          aggregateStatus = 'on_hold';
        } else if (data.items.every(i => i.status === 'completed')) {
          aggregateStatus = 'completed';
        } else if (data.items.some(i => i.status === 'plan_to_watch')) {
          aggregateStatus = 'plan_to_watch';
        } else {
          aggregateStatus = 'dropped';
        }

        // Pick the active item in watch order for default title/poster
        const watchingItem = data.items.find(i => i.status === 'watching');
        const onHoldItem = data.items.find(i => i.status === 'on_hold');
        const firstUncompletedItem = data.items.find(i => i.status !== 'completed' && i.status !== 'dropped');
        const activeItem = watchingItem || onHoldItem || firstUncompletedItem || data.items[0];

        const bestPoster = (activeItem?.posterUrl && activeItem.posterUrl !== 'null')
          ? activeItem.posterUrl
          : (data.posterUrl || data.items[0]?.posterUrl);
        const bestTitle = (activeItem?.title && activeItem.title !== 'Unknown')
          ? activeItem.title
          : (data.title || data.items[0]?.title);

        list.push({
          type: 'franchise',
          group: { rootId: franchiseId, rootTitle: bestTitle, rootPosterUrl: bestPoster, memberIds: data.items.map(i => String(i.externalId)) },
          items: data.items,
          aggregateStatus
        });
      }
    });

    uniqueWatchlist.forEach(item => {
      if (!groupedIds.has(item.id)) {
        list.push({ type: 'single', item, aggregateStatus: item.status });
      }
    });

    // Default chronological order: most recently added/updated items first
    return list.sort((a, b) => {
      const timeA = a.type === 'single' ? new Date(a.item.updatedAt || a.item.addedAt).getTime() : Math.max(...a.items.map(i => new Date(i.updatedAt || i.addedAt).getTime()));
      const timeB = b.type === 'single' ? new Date(b.item.updatedAt || b.item.addedAt).getTime() : Math.max(...b.items.map(i => new Date(i.updatedAt || i.addedAt).getTime()));
      return timeB - timeA;
    });
  }, [watchlist]);

  // Live item counts per status tab
  const statusCounts = useMemo(() => {
    const counts: Record<WatchStatus | "all", number> = {
      all: allGroups.length,
      plan_to_watch: 0,
      watching: 0,
      on_hold: 0,
      completed: 0,
      dropped: 0,
    };

    allGroups.forEach(group => {
      const status = group.aggregateStatus;
      if (counts[status] !== undefined) {
        counts[status]++;
      }
    });

    return counts;
  }, [allGroups]);

  // Filtered display items (no complex sorting dropdown, natural newest-first order)
  const displayItems = useMemo(() => {
    let filtered = allGroups;
    
    if (filter !== "all") {
      filtered = filtered.filter((group) => {
        if (group.type === "single") {
          return group.item.status === filter;
        }
        return group.aggregateStatus === filter || group.items.some((i) => i.status === filter);
      });
    }
    
    if (searchQuery.trim() !== "") {
      const q = searchQuery.toLowerCase();
      filtered = filtered.filter((display) => {
        if (display.type === "single") {
          return display.item.title.toLowerCase().includes(q);
        } else {
          return (
            display.group.rootTitle.toLowerCase().includes(q) ||
            display.items.some((i) => i.title.toLowerCase().includes(q))
          );
        }
      });
    }
    
    return filtered;
  }, [allGroups, filter, searchQuery]);

  if (!mounted) {
    return (
      <main className="max-w-container-max mx-auto px-4 sm:px-6 md:px-8 lg:px-12 pt-8 pb-32 min-h-screen" />
    ); 
  }

  return (
    <main className="max-w-container-max mx-auto px-4 sm:px-6 md:px-8 lg:px-12 pt-6 sm:pt-8 pb-32 flex flex-col gap-6 sm:gap-8 slide-up">
      {/* Page Title & Stats */}
      <header className="flex flex-col gap-5">
        <div>
          <h1 className="text-3xl sm:text-4xl md:text-5xl font-black text-white tracking-tight font-display">
            My Watchlist
          </h1>
          <div className="flex items-center gap-2 sm:gap-2.5 flex-wrap mt-2.5">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-white/5 border border-white/10 text-slate-300">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-400" />
              {allGroups.length} {allGroups.length === 1 ? 'Title' : 'Titles'}
            </span>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-white/5 border border-white/10 text-slate-300">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
              {statusCounts.watching} Watching
            </span>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-white/5 border border-white/10 text-slate-300">
              <span className="w-1.5 h-1.5 rounded-full bg-blue-400" />
              {statusCounts.completed} Completed
            </span>
            {isMigrating && (
              <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-amber-400/10 border border-amber-400/20 text-amber-300">
                <span className="w-3 h-3 border-2 border-amber-400 border-t-transparent rounded-full animate-spin" />
                Syncing franchises...
              </span>
            )}
          </div>
        </div>

        {/* Responsive Toolbar: Filter Tabs & Search Bar */}
        {watchlist.length > 0 && (
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 sm:gap-4 pt-1">
            {/* Filter Tabs (Horizontally scrollable on mobile, compact on desktop) */}
            <div className="w-full md:w-auto overflow-x-auto no-scrollbar -mx-4 px-4 md:mx-0 md:px-0">
              <div className="inline-flex items-center gap-1 p-1 bg-slate-900/65 backdrop-blur-2xl border border-white/10 rounded-full shadow-inner min-w-max">
                {FILTER_TABS.map((tab) => {
                  const isActive = filter === tab.value;
                  const count = statusCounts[tab.value] ?? 0;

                  return (
                    <button
                      key={tab.value}
                      type="button"
                      onClick={() => setFilter(tab.value)}
                      className={`flex items-center gap-2 px-3.5 sm:px-4 py-2 rounded-full text-xs sm:text-sm font-semibold whitespace-nowrap transition-all duration-200 select-none cursor-pointer ${
                        isActive
                          ? "bg-amber-400 text-slate-950 shadow-md shadow-amber-400/25 scale-[1.02]"
                          : "text-slate-400 hover:text-white hover:bg-white/5"
                      }`}
                    >
                      <span>{tab.label}</span>
                      <span
                        className={`px-1.5 py-0.5 rounded-full text-[11px] font-bold leading-none ${
                          isActive
                            ? "bg-slate-950/20 text-slate-950"
                            : "bg-white/10 text-slate-400"
                        }`}
                      >
                        {count}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Search Bar */}
            <div className="relative w-full md:w-64 lg:w-72 shrink-0">
              <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                <Search className="h-4 w-4" />
              </div>
              <input
                type="text"
                placeholder="Search watchlist..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full h-11 bg-slate-900/65 backdrop-blur-2xl border border-white/10 hover:border-white/20 focus:border-amber-400/60 focus:ring-2 focus:ring-amber-400/20 rounded-full pl-10 pr-10 text-sm text-white placeholder:text-slate-500 shadow-inner transition-all outline-none"
              />
              {searchQuery && (
                <button
                  type="button"
                  onClick={() => setSearchQuery("")}
                  className="absolute inset-y-0 right-0 pr-3.5 flex items-center text-slate-400 hover:text-white transition-colors cursor-pointer"
                  aria-label="Clear search"
                >
                  <X className="h-4 w-4" />
                </button>
              )}
            </div>
          </div>
        )}
      </header>

      {/* Grid or Empty State */}
      {isLoading ? (
        <div className="flex flex-col items-center justify-center py-32 text-center fade-in">
          <div className="w-12 h-12 border-4 border-amber-400/20 border-t-amber-400 rounded-full animate-spin mb-4" />
          <p className="text-sm font-medium text-slate-400 animate-pulse">Loading your watchlist...</p>
        </div>
      ) : watchlist.length > 0 ? (
        displayItems.length > 0 ? (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3.5 sm:gap-5 md:gap-6 fade-in">
            {displayItems.map((display, i) => {
              if (display.type === 'franchise') {
                return (
                  <div key={`franchise-${display.group.rootId}`}>
                    <FranchiseCard
                      rootId={display.group.rootId}
                      rootTitle={display.group.rootTitle}
                      rootPosterUrl={display.group.rootPosterUrl}
                      items={display.items}
                      currentFilter={filter}
                    />
                  </div>
                );
              } else {
                return (
                  <div key={`single-${display.item.id}`}>
                    <MediaCard media={display.item as any} index={i} />
                  </div>
                );
              }
            })}
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center py-20 text-center bg-slate-900/40 backdrop-blur-xl rounded-3xl border border-white/10 p-8">
            <div className="w-16 h-16 rounded-full bg-white/5 border border-white/10 flex items-center justify-center mb-4 text-slate-400">
              <Search className="w-8 h-8 opacity-60" />
            </div>
            <h2 className="text-xl sm:text-2xl font-bold text-white mb-2">
              {searchQuery ? `No results for "${searchQuery}"` : "No titles in this section"}
            </h2>
            <p className="text-sm text-slate-400 max-w-sm mb-6">
              {searchQuery
                ? "Try searching with a different term or keyword."
                : "No media currently matches the selected status filter."}
            </p>
            {searchQuery ? (
              <button
                type="button"
                onClick={() => setSearchQuery("")}
                className="px-5 py-2.5 rounded-full bg-white/10 hover:bg-white/15 text-white text-xs font-semibold transition-colors cursor-pointer"
              >
                Clear Search
              </button>
            ) : (
              <button
                type="button"
                onClick={() => setFilter("all")}
                className="px-5 py-2.5 rounded-full bg-amber-400 hover:bg-amber-300 text-slate-950 text-xs font-bold transition-colors cursor-pointer shadow-lg shadow-amber-400/20"
              >
                View All Items
              </button>
            )}
          </div>
        )
      ) : (
        <div className="flex flex-col items-center justify-center py-24 text-center bg-slate-900/40 backdrop-blur-xl rounded-3xl border border-white/10 p-8">
          <div className="w-20 h-20 bg-amber-400/15 border border-amber-400/30 rounded-full flex items-center justify-center mb-6 shadow-xl text-amber-400">
            <PlaySquare className="w-10 h-10" />
          </div>
          <h2 className="text-2xl sm:text-3xl font-bold text-white mb-3">
            Your watchlist is empty
          </h2>
          <p className="text-sm text-slate-400 max-w-md mx-auto mb-8 leading-relaxed">
            Start adding anime, movies, and series to your watchlist to track what you&apos;re watching and plan ahead.
          </p>
          <Link
            href="/discover"
            className="bg-amber-400 hover:bg-amber-300 text-slate-950 font-bold py-3 px-8 rounded-full transition-all shadow-[0_10px_25px_rgba(245,158,11,0.25)] active:scale-95 text-sm"
          >
            Discover Media
          </Link>
        </div>
      )}
    </main>
  );
}
