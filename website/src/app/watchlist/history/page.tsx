'use client';

import { useWatchlist } from '@/lib/contexts/WatchlistContext';
import { useEffect, useState, useMemo } from 'react';
import Link from 'next/link';
import { ArrowLeft, Clock } from 'lucide-react';
import type { WatchlistItem } from '@/types/media';

export default function WatchHistoryPage() {
  const { watchlist, isLoading } = useWatchlist();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const historyGroups = useMemo(() => {
    // Filter for COMPLETED items or items with progress, then sort by updatedAt desc
    const historyItems = watchlist.filter(
      (item) => item.status === 'completed' || (item.progress && item.progress > 0)
    );
    
    historyItems.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());

    const grouped: Record<string, WatchlistItem[]> = {};
    const now = new Date();
    const todayStr = now.toDateString();
    const yesterdayStr = new Date(now.getTime() - 86400000).toDateString();

    for (const item of historyItems) {
      const date = new Date(item.updatedAt);
      const dateStr = date.toDateString();
      let groupKey = '';

      if (dateStr === todayStr) {
        groupKey = 'Today';
      } else if (dateStr === yesterdayStr) {
        groupKey = 'Yesterday';
      } else {
        groupKey = date.toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' });
      }

      if (!grouped[groupKey]) {
        grouped[groupKey] = [];
      }
      grouped[groupKey].push(item);
    }

    return grouped;
  }, [watchlist]);

  if (!mounted) {
    return <main className="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop pt-8 pb-32 min-h-screen" />;
  }

  return (
    <main className="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop pt-8 pb-32 min-h-screen slide-up">
      <header className="flex items-center gap-4 mb-8">
        <Link href="/settings" className="p-2 hover:bg-white/10 rounded-full transition-colors">
          <ArrowLeft className="w-6 h-6 text-on-surface" />
        </Link>
        <h1 className="font-display-xl-mobile md:font-display-xl text-[32px] md:text-[48px] text-on-surface tracking-tight font-bold">
          Watch History
        </h1>
      </header>

      {isLoading ? (
        <div className="flex flex-col items-center justify-center py-32 text-center fade-in">
          <div className="w-12 h-12 border-4 border-primary/20 border-t-primary rounded-full animate-spin mb-4" />
          <p className="font-body-md text-on-surface-variant animate-pulse">Loading history...</p>
        </div>
      ) : Object.keys(historyGroups).length === 0 ? (
        <div className="flex flex-col items-center justify-center py-24 text-center glass-panel rounded-2xl border border-white/5">
          <div className="w-20 h-20 bg-surface-container rounded-full flex items-center justify-center mb-6 border border-white/10 shadow-xl">
            <Clock className="w-10 h-10 text-primary" />
          </div>
          <h2 className="font-headline-lg-mobile md:font-headline-lg text-[24px] md:text-[32px] font-bold text-on-surface mb-4">
            No history found
          </h2>
          <p className="font-body-md text-on-surface-variant max-w-md mx-auto mb-8">
            Start watching movies, series, and anime to build your history.
          </p>
          <Link
            href="/discover"
            className="bg-primary text-surface font-bold py-3 px-8 rounded-full hover:bg-primary-container transition-colors shadow-[0_10px_20px_rgba(245,158,11,0.2)] active:scale-95"
          >
            Discover Media
          </Link>
        </div>
      ) : (
        <div className="flex flex-col gap-8 fade-in">
          {Object.entries(historyGroups).map(([date, items]) => (
            <div key={date} className="flex flex-col">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-2.5 h-2.5 bg-primary rounded-full shadow-[0_0_8px_rgba(245,158,11,0.5)]" />
                <h2 className="text-on-surface font-bold text-lg">{date}</h2>
              </div>
              
              <div className="ml-[5px] pl-6 border-l-2 border-white/10 flex flex-col gap-4">
                {items.map((item) => {
                  // Ensure proper path construction
                  const cleanExtId = String(item.externalId || item.id).replace(/tmdb-tv-|tmdb-movie-|anilist-/g, '');
                  const link = `/media/${item.mediaType}/${cleanExtId}`;
                  
                  return (
                    <Link key={item.id} href={link} className="block group">
                      <div className="flex items-center gap-4 p-3 rounded-xl hover:bg-white/5 border border-transparent hover:border-white/10 transition-all">
                        <div className="relative w-16 h-24 shrink-0 overflow-hidden rounded-lg bg-surface-container">
                          {item.posterUrl && (
                            <img
                              src={item.posterUrl}
                              alt={item.title}
                              className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                              loading="lazy"
                            />
                          )}
                        </div>
                        <div className="flex flex-col min-w-0 flex-1">
                          <h3 className="text-on-surface font-bold text-sm md:text-base truncate group-hover:text-primary transition-colors">
                            {item.title}
                          </h3>
                          <p className="text-on-surface-variant text-xs md:text-sm mt-1">
                            {item.status === 'completed' ? 'Completed' : `Watched Ep ${item.progress}`}
                          </p>
                        </div>
                        <div className="text-on-surface-variant/70 text-xs shrink-0 pl-2">
                          {new Date(item.updatedAt).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' })}
                        </div>
                      </div>
                    </Link>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
