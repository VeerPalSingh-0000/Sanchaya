"use client";

import { useWatchlist } from "@/lib/contexts/WatchlistContext";
import MediaCard from "@/components/media/MediaCard";
import FranchiseCard from "@/components/media/FranchiseCard";
import Link from "next/link";
import { useEffect, useState, useMemo } from "react";
import type { WatchStatus, WatchlistItem } from "@/types/media";
import { getWatchlistFranchiseGroupings, FranchiseGroup } from "./actions";

// Define our display union type
type DisplayItem = 
  | { type: 'single'; item: WatchlistItem }
  | { type: 'franchise'; group: FranchiseGroup; items: WatchlistItem[] };

export default function WatchlistPage() {
  const { watchlist } = useWatchlist();
  const [mounted, setMounted] = useState(false);
  const [filter, setFilter] = useState<WatchStatus | "all">("all");
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
    const missingIds = itemsToMigrate.map(i => String(i.externalId));
    getWatchlistFranchiseGroupings(missingIds).then(newGroups => {
      itemsToMigrate.forEach(item => {
        const group = newGroups.find(g => g.memberIds.includes(String(item.externalId)));
        if (group) {
          // Trigger a silent background update to POST the new franchise data permanently
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
          }).then(() => {
            // Force a hard reload to fetch the new DB state and rerender groups!
            window.location.reload();
          });
        }
      });
      setIsMigrating(false);
    }).catch(() => setIsMigrating(false));
  }, [watchlist, mounted]);

  const filteredWatchlist = useMemo(() => {
    if (filter === "all") return watchlist;
    return watchlist.filter((item) => item.status === filter);
  }, [watchlist, filter]);

  const displayItems = useMemo(() => {
    const list: DisplayItem[] = [];
    const groupedIds = new Set<string>();

    // 1. Group natively using database fields
    const franchiseMap = new Map<string, { title: string, posterUrl: string, items: WatchlistItem[] }>();

    filteredWatchlist.forEach(item => {
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

    // 2. Map groups into display cards
    franchiseMap.forEach((data, franchiseId) => {
      if (data.items.length > 0) {
        list.push({
          type: 'franchise',
          group: { rootId: franchiseId, rootTitle: data.title, rootPosterUrl: data.posterUrl, memberIds: data.items.map(i => String(i.externalId)) },
          items: data.items
        });
      }
    });

    // 3. Add remaining un-grouped or single items
    filteredWatchlist.forEach(item => {
      // If it has no franchiseId, we put it in the single pile
      if (!groupedIds.has(item.id)) {
        list.push({ type: 'single', item });
      }
    });

    // Sort by most recently added
    return list.sort((a, b) => {
      const timeA = a.type === 'single' ? new Date(a.item.addedAt).getTime() : Math.max(...a.items.map(i => new Date(i.addedAt).getTime()));
      const timeB = b.type === 'single' ? new Date(b.item.addedAt).getTime() : Math.max(...b.items.map(i => new Date(i.addedAt).getTime()));
      return timeB - timeA;
    });

  }, [filteredWatchlist]);

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
            {watchlist.length} items saved •{" "}
            {watchlist.filter((i) => i.status === "completed").length} completed
            {isMigrating && <span className="ml-2 w-4 h-4 border-2 border-primary border-t-transparent rounded-full animate-spin"></span>}
          </p>
        </div>

        {watchlist.length > 0 && (
          <div className="flex flex-col sm:flex-row items-center gap-4">
            {/* Filters */}
            <div className="flex space-x-2 overflow-x-auto no-scrollbar w-full sm:w-auto pb-1 sm:pb-0">
              {["all", "plan_to_watch", "watching", "completed", "dropped"].map(
                (f) => (
                  <button
                    key={f}
                    className={`px-4 py-2 rounded-full font-label-sm text-[12px] whitespace-nowrap transition-all active:scale-95 border ${
                      filter === f
                        ? "bg-primary text-background border-primary font-bold shadow-[0_5px_15px_rgba(245,158,11,0.2)]"
                        : "bg-surface-container/40 backdrop-blur-lg border-white/10 text-on-surface-variant hover:text-on-surface hover:bg-white/10"
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

      {watchlist.length > 0 ? (
        displayItems.length > 0 ? (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 md:gap-gutter fade-in">
            {displayItems.map((display, i) => {
              if (display.type === 'franchise') {
                return (
                  <div key={`franchise-${display.group.rootId}`}>
                    <FranchiseCard
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
            <span className="material-symbols-outlined text-6xl text-on-surface-variant opacity-50 mb-4">
              filter_list_off
            </span>
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
            <span
              className="material-symbols-outlined text-[40px] text-primary"
              style={{ fontVariationSettings: "'FILL' 1" }}
            >
              subscriptions
            </span>
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
