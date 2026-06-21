'use client';

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import type { Media, WatchlistItem, WatchStatus } from '@/types/media';
import { useSession } from 'next-auth/react';

interface WatchlistContextType {
  watchlist: WatchlistItem[];
  addToWatchlist: (media: Media, status?: WatchStatus) => void;
  removeFromWatchlist: (id: string) => void;
  updateStatus: (id: string, status: WatchStatus) => void;
  isInWatchlist: (id: string) => boolean;
}

const WatchlistContext = createContext<WatchlistContextType | undefined>(undefined);

export function WatchlistProvider({ children }: { children: React.ReactNode }) {
  const { data: session, status: sessionStatus } = useSession();
  const [watchlist, setWatchlist] = useState<WatchlistItem[]>([]);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    if (sessionStatus === 'loading') return;

    if (session) {
      fetch('/api/watchlist')
        .then(res => res.json())
        .then(data => {
          if (Array.isArray(data)) {
            const mapped: WatchlistItem[] = data.map(item => ({
              id: item.mediaId,
              externalId: item.mediaId,
              mediaType: item.mediaType as any,
              title: item.title,
              posterUrl: item.posterPath || '',
              genres: [],
              rating: item.rating || 0,
              status: item.status.toLowerCase() as WatchStatus,
              addedAt: item.createdAt,
              updatedAt: item.updatedAt,
            }));
            setWatchlist(mapped);
          }
        });
    } else {
      try {
        const stored = localStorage.getItem('cineverse_watchlist');
        if (stored) {
          setWatchlist(JSON.parse(stored));
        }
      } catch (e) {
        console.error('Failed to parse watchlist from local storage', e);
      }
    }
    setMounted(true);
  }, [session, sessionStatus]);

  useEffect(() => {
    if (!mounted || session) return;
    try {
      localStorage.setItem('cineverse_watchlist', JSON.stringify(watchlist));
    } catch (e) {
      console.error('Failed to save watchlist to local storage', e);
    }
  }, [watchlist, mounted, session]);

  const addToWatchlist = useCallback((media: Media, status: WatchStatus = 'plan_to_watch') => {
    setWatchlist((prev) => {
      if (prev.some((item) => item.id === String(media.id))) return prev;
      const newItem: WatchlistItem = {
        id: String(media.id),
        externalId: media.externalId,
        mediaType: media.type,
        title: media.title,
        posterUrl: media.posterUrl,
        backdropUrl: media.backdropUrl,
        genres: media.genres,
        rating: media.rating,
        status,
        totalEpisodes: media.totalEpisodes,
        addedAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      return [newItem, ...prev];
    });

    if (session) {
      fetch('/api/watchlist', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          mediaId: String(media.id),
          mediaType: media.type,
          title: media.title,
          posterPath: media.posterUrl || '',
          status: status.toUpperCase(),
        })
      });
    }
  }, [session]);

  const removeFromWatchlist = useCallback((id: string) => {
    setWatchlist((prev) => prev.filter((item) => item.id !== String(id)));
    if (session) {
      fetch(`/api/watchlist/${id}`, { method: 'DELETE' });
    }
  }, [session]);

  const updateStatus = useCallback((id: string, status: WatchStatus) => {
    setWatchlist((prev) =>
      prev.map((item) =>
        item.id === String(id) ? { ...item, status, updatedAt: new Date().toISOString() } : item
      )
    );
    if (session) {
      fetch(`/api/watchlist/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: status.toUpperCase() })
      });
    }
  }, [session]);

  const isInWatchlist = useCallback(
    (id: string) => watchlist.some((item) => item.id === String(id)),
    [watchlist]
  );

  return (
    <WatchlistContext.Provider value={{ watchlist, addToWatchlist, removeFromWatchlist, updateStatus, isInWatchlist }}>
      {children}
    </WatchlistContext.Provider>
  );
}

export function useWatchlist() {
  const context = useContext(WatchlistContext);
  if (context === undefined) throw new Error('useWatchlist must be used within a WatchlistProvider');
  return context;
}
