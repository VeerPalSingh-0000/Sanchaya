"use client";

import { useWatchlist } from "@/lib/contexts/WatchlistContext";
import MediaCard from "@/components/media/MediaCard";
import FranchiseCard from "@/components/media/FranchiseCard";
import Link from "next/link";
import { useEffect, useState, useMemo } from "react";
import { ListFilter, PlaySquare, Search, X } from "lucide-react";
import type { WatchStatus, WatchlistItem } from "@/types/media";
import { getWatchlistFranchiseGroupings, FranchiseGroup } from "./actions";

// Define our display union type
type DisplayItem = 
  | { type: 'single'; item: WatchlistItem }
  | { type: 'franchise'; group: FranchiseGroup; items: WatchlistItem[] };

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

  // 1. Group natively using database fields without filtering
  const allGroups = useMemo(() => {
    const list: (DisplayItem & { aggregateStatus: WatchStatus })[] = [];
    const groupedIds = new Set<string>();

    const franchiseMap = new Map<string, { title: string, posterUrl: string, items: WatchlistItem[] }>();

    watchlist.forEach(item => {
      if (item.franchiseId) {
        if (!franchiseMap.has(item.franchiseId)) {
          franchiseMap.set(item.franchiseId, {
             title: item.franchiseTitle || item.title,
             posterUrl: item.franchisePosterUrl || item.posterUrl,
             items: []
          });
        }
        franchiseMap.get(item.franchiseId)!.items.push(item);
        groupedIds.add(item.id);
      }
    });

    franchiseMap.forEach((data, franchiseId) => {
      if (data.items.length > 0) {
        // Compute aggregate status
        // Compute aggregate status across the entire franchise
        let aggregateStatus: WatchStatus = 'plan_to_watch';
        
        if (data.items.some(i => i.status === 'watching')) {
          aggregateStatus = 'watching';
        } else if (data.items.every(i => i.status === 'completed')) {
          aggregateStatus = 'completed';
        } else if (data.items.some(i => i.status === 'plan_to_watch')) {
          aggregateStatus = 'plan_to_watch';
        } else if (data.items.some(i => i.status === 'on_hold')) {
          aggregateStatus = 'on_hold';
        } else {
          aggregateStatus = 'dropped';
        }

        list.push({
          type: 'franchise',
          group: { rootId: franchiseId, rootTitle: data.title, rootPosterUrl: data.posterUrl, memberIds: data.items.map(i => String(i.externalId)) },
          items: data.items,
          aggregateStatus
        });
      }
    });

    watchlist.forEach(item => {
      if (!groupedIds.has(item.id)) {
        list.push({ type: 'single', item, aggregateStatus: item.status });
      }
    });

    return list.sort((a, b) => {
      const timeA = a.type === 'single' ? new Date(a.item.addedAt).getTime() : Math.max(...a.items.map(i => new Date(i.addedAt).getTime()));
      const timeB = b.type === 'single' ? new Date(b.item.addedAt).getTime() : Math.max(...b.items.map(i => new Date(i.addedAt).getTime()));
      return timeB - timeA;
    });
  }, [watchlist]);

  const displayItems = useMemo(() => {
    let filtered = allGroups;
    
    if (filter !== "all") {
      filtered = filtered.filter((group) => group.aggregateStatus === filter);
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
      <main className="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop pt-8 pb-32 min-h-screen" />
    ); 
  }

  return (
    <main className="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop pt-8 pb-32 flex flex-col gap-8 slide-up">
      <header className="flex flex-col md:flex-row md:items-end justify-between gap-6">
        <div>
          <h1 className="font-display-xl-mobile text-[40px] md:font-display-xl md:text-[64px] text-on-surface tracking-tight font-bold">
            My Watchlist
          </h1>
          <p className="font-body-md text-on-surface-variant mt-2 text-[16px] flex items-center gap-2">
            {allGroups.length} items saved •{" "}
            {allGroups.filter((g) => g.aggregateStatus === "completed").length} completed
            {isMigrating && <span className="ml-2 w-4 h-4 border-2 border-primary border-t-transparent rounded-full animate-spin"></span>}
          </p>
        </div>

        {watchlist.length > 0 && (
          <div className="flex flex-col xl:flex-row items-center gap-4 w-full md:w-auto mt-4 md:mt-0">
            {/* Search Bar */}
            <div className="relative w-full xl:w-64 group">
              <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <Search className="h-4 w-4 text-on-surface-variant group-focus-within:text-primary transition-colors duration-300" />
              </div>
              <input
                type="text"
                placeholder="Search watchlist..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full bg-surface-container/40 backdrop-blur-xl border border-white/5 rounded-full py-2.5 pl-10 pr-10 text-[14px] text-on-surface placeholder:text-on-surface-variant/50 focus:outline-none focus:ring-1 focus:ring-primary/50 focus:bg-white/5 transition-all duration-300 shadow-inner"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery('')}
                  className="absolute inset-y-0 right-0 pr-4 flex items-center text-on-surface-variant hover:text-white transition-colors"
                >
                  <X className="h-4 w-4" />
                </button>
              )}
            </div>

            {/* Filters */}
            <div className="flex items-center p-1.5 bg-surface-container/40 backdrop-blur-xl border border-white/5 rounded-full overflow-x-auto no-scrollbar w-full xl:w-auto shadow-inner">
              {["all", "plan_to_watch", "watching", "on_hold", "completed", "dropped"].map(
                (f) => (
                  <button
                    key={f}
                    className={`px-5 py-2 rounded-full font-label-sm text-[13px] whitespace-nowrap transition-all duration-300 ease-out flex-shrink-0 ${
                      filter === f
                        ? "bg-primary text-background font-bold shadow-[0_4px_12px_rgba(245,158,11,0.25)] scale-100"
                        : "text-on-surface-variant hover:text-on-surface hover:bg-white/5 active:scale-95"
                    }`}
                    onClick={() => setFilter(f as WatchStatus | "all")}
                  >
                    {f === "all"
                      ? "All Items"
                      : f
                          .replace(/_/g, " ")
                          .replace(/\b\w/g, (l) => l.toUpperCase())}
                  </button>
                ),
              )}
            </div>
          </div>
        )}
      </header>

      {isLoading ? (
        <div className="flex flex-col items-center justify-center py-32 text-center fade-in">
          <div className="w-12 h-12 border-4 border-primary/20 border-t-primary rounded-full animate-spin mb-4" />
          <p className="font-body-md text-on-surface-variant animate-pulse">Loading your watchlist...</p>
        </div>
      ) : watchlist.length > 0 ? (
        displayItems.length > 0 ? (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 md:gap-gutter fade-in">
            {displayItems.map((display, i) => {
              if (display.type === 'franchise') {
                return (
                  <div key={`franchise-${display.group.rootId}`}>
                    <FranchiseCard
                      rootId={display.group.rootId}
                      rootTitle={display.group.rootTitle}
                      rootPosterUrl={display.group.rootPosterUrl}
                      items={display.items}
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
          <div className="flex flex-col items-center justify-center py-24 text-center glass-panel rounded-2xl border border-white/5">
            <ListFilter className="w-16 h-16 text-on-surface-variant opacity-50 mb-4" />
            <h2 className="font-headline-lg-mobile text-[24px] font-bold text-on-surface mb-2">
              No items match filter
            </h2>
            <p className="font-body-md text-on-surface-variant">
              Try selecting a different status filter.
            </p>
          </div>
        )
      ) : (
        <div className="flex flex-col items-center justify-center py-24 text-center glass-panel rounded-2xl border border-white/5">
          <div className="w-20 h-20 bg-surface-container rounded-full flex items-center justify-center mb-6 border border-white/10 shadow-xl">
            <PlaySquare className="w-10 h-10 text-primary" />
          </div>
          <h2 className="font-headline-lg-mobile md:font-headline-lg text-[24px] md:text-[32px] font-bold text-on-surface mb-4">
            Your watchlist is empty
          </h2>
          <p className="font-body-md text-on-surface-variant max-w-md mx-auto mb-8">
            Start adding movies, series, and anime to your watchlist to keep
            track of what you want to see.
          </p>
          <Link
            href="/discover"
            className="bg-primary text-surface font-bold py-3 px-8 rounded-full hover:bg-primary-container transition-colors shadow-[0_10px_20px_rgba(245,158,11,0.2)] active:scale-95"
          >
            Discover Media
          </Link>
        </div>
      )}
    </main>
  );
}
