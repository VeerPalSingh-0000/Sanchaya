'use client';

import { useWatchlist } from '@/lib/contexts/WatchlistContext';
import MediaGrid from '@/components/media/MediaGrid';
import FloatingGallery from '@/components/3d/FloatingGallery';
import Link from 'next/link';
import { useEffect, useState, useMemo } from 'react';
import type { WatchStatus } from '@/types/media';

export default function WatchlistPage() {
  const { watchlist } = useWatchlist();
  const [mounted, setMounted] = useState(false);
  const [filter, setFilter] = useState<WatchStatus | 'all'>('all');
  const [viewMode, setViewMode] = useState<'grid' | '3d'>('grid');

  useEffect(() => {
    setMounted(true);
  }, []);

  const filteredWatchlist = useMemo(() => {
    if (filter === 'all') return watchlist;
    return watchlist.filter(item => item.status === filter);
  }, [watchlist, filter]);

  if (!mounted) {
    return <main className="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop pt-8 pb-32 min-h-screen" />; // Prevents hydration mismatch
  }

  return (
    <main className="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop pt-8 pb-32 flex flex-col gap-8 slide-up">
      <header className="flex flex-col md:flex-row md:items-end justify-between gap-6">
        <div>
          <h1 className="font-display-xl-mobile text-[40px] md:font-display-xl md:text-[64px] text-on-surface tracking-tight font-bold">
            My Watchlist
          </h1>
          <p className="font-body-md text-on-surface-variant mt-2 text-[16px]">
            {watchlist.length} items saved • {watchlist.filter(i => i.status === 'completed').length} completed
          </p>
        </div>
        
        {watchlist.length > 0 && (
          <div className="flex flex-col sm:flex-row items-center gap-4">
            {/* View Toggle */}
            <div className="flex p-1 bg-surface-container/40 backdrop-blur-md rounded-lg border border-white/10 w-full sm:w-auto">
              <button
                className={`flex-1 sm:flex-none flex items-center justify-center gap-2 px-4 py-2 rounded-md font-label-sm text-[12px] transition-colors ${viewMode === 'grid' ? 'bg-white/10 text-on-surface font-bold shadow-sm' : 'text-on-surface-variant hover:text-on-surface'}`}
                onClick={() => setViewMode('grid')}
              >
                <span className="material-symbols-outlined text-[18px]">grid_view</span>
                Grid
              </button>
              <button
                className={`flex-1 sm:flex-none flex items-center justify-center gap-2 px-4 py-2 rounded-md font-label-sm text-[12px] transition-colors ${viewMode === '3d' ? 'bg-white/10 text-on-surface font-bold shadow-sm' : 'text-on-surface-variant hover:text-on-surface'}`}
                onClick={() => setViewMode('3d')}
              >
                <span className="material-symbols-outlined text-[18px]">view_in_ar</span>
                3D
              </button>
            </div>
            
            {/* Filters */}
            <div className="flex space-x-2 overflow-x-auto no-scrollbar w-full sm:w-auto pb-1 sm:pb-0">
              {['all', 'plan_to_watch', 'watching', 'completed', 'dropped'].map((f) => (
                <button
                  key={f}
                  className={`px-4 py-2 rounded-full font-label-sm text-[12px] whitespace-nowrap transition-all active:scale-95 border ${
                    filter === f 
                      ? 'bg-primary text-background border-primary font-bold shadow-[0_5px_15px_rgba(245,158,11,0.2)]' 
                      : 'bg-surface-container/40 backdrop-blur-lg border-white/10 text-on-surface-variant hover:text-on-surface hover:bg-white/10'
                  }`}
                  onClick={() => setFilter(f as WatchStatus | 'all')}
                >
                  {f === 'all' ? 'All Items' : f.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                </button>
              ))}
            </div>
          </div>
        )}
      </header>

      {watchlist.length > 0 ? (
        filteredWatchlist.length > 0 ? (
          viewMode === '3d' ? (
            <div className="fade-in rounded-2xl overflow-hidden border border-white/10 shadow-2xl">
              <FloatingGallery items={filteredWatchlist as any} />
            </div>
          ) : (
            <div className="fade-in">
              <MediaGrid items={filteredWatchlist as any} />
            </div>
          )
        ) : (
          <div className="flex flex-col items-center justify-center py-24 text-center glass-panel rounded-2xl border border-white/5">
            <span className="material-symbols-outlined text-6xl text-on-surface-variant opacity-50 mb-4">filter_list_off</span>
            <h2 className="font-headline-lg-mobile text-[24px] font-bold text-on-surface mb-2">No items match filter</h2>
            <p className="font-body-md text-on-surface-variant">Try selecting a different status filter.</p>
          </div>
        )
      ) : (
        <div className="flex flex-col items-center justify-center py-24 text-center glass-panel rounded-2xl border border-white/5">
          <div className="w-20 h-20 bg-surface-container rounded-full flex items-center justify-center mb-6 border border-white/10 shadow-xl">
            <span className="material-symbols-outlined text-[40px] text-primary" style={{ fontVariationSettings: "'FILL' 1" }}>subscriptions</span>
          </div>
          <h2 className="font-headline-lg-mobile md:font-headline-lg text-[24px] md:text-[32px] font-bold text-on-surface mb-4">Your watchlist is empty</h2>
          <p className="font-body-md text-on-surface-variant max-w-md mx-auto mb-8">
            Start adding movies, series, and anime to your watchlist to keep track of what you want to see.
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
