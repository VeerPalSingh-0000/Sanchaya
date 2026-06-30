'use client';

import { useState, useEffect, useRef, useCallback, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { motion, AnimatePresence } from 'framer-motion';
import type { Media, MediaFilter } from '@/types/media';
import { performSearch } from '@/app/actions';

const FILTER_OPTIONS: { value: MediaFilter; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'movie', label: 'Movies' },
  { value: 'series', label: 'Series' },
  { value: 'anime', label: 'Anime' },
];

const PLACEHOLDER_TEXTS = [
  'Search movies...',
  'Search anime...',
  'Search web series...',
];

function SearchBarInner() {
  const searchParams = useSearchParams();

  const [query, setQuery] = useState(searchParams.get('q') ?? '');
  const [filter, setFilter] = useState<MediaFilter>(
    (searchParams.get('type') as MediaFilter) || 'all'
  );
  const [focused, setFocused] = useState(false);
  const [searching, setSearching] = useState(false);
  const [results, setResults] = useState<Media[]>([]);
  const [hasSearched, setHasSearched] = useState(false);
  const [placeholderIdx, setPlaceholderIdx] = useState(0);

  const inputRef = useRef<HTMLInputElement>(null);
  const wrapperRef = useRef<HTMLDivElement>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);

  // Close dropdown on click outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        wrapperRef.current &&
        !wrapperRef.current.contains(event.target as Node)
      ) {
        setFocused(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Cycle placeholder text
  useEffect(() => {
    if (focused || query) return;
    const interval = setInterval(() => {
      setPlaceholderIdx((i) => (i + 1) % PLACEHOLDER_TEXTS.length);
    }, 2500);
    return () => clearInterval(interval);
  }, [focused, query]);

  // Debounced search fetch
  const executeSearch = useCallback(
    async (q: string, type: MediaFilter) => {
      if (!q.trim()) {
        setResults([]);
        setHasSearched(false);
        return;
      }
      setSearching(true);
      try {
        const fetchedResults = await performSearch(q, type);
        setResults(fetchedResults);
        setHasSearched(true);
      } catch (error) {
        console.error('Search failed:', error);
        setResults([]);
      } finally {
        setSearching(false);
      }
    },
    []
  );

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);

    if (!query.trim()) {
      setSearching(false);
      setResults([]);
      setHasSearched(false);
      return;
    }

    setSearching(true);
    debounceRef.current = setTimeout(() => {
      executeSearch(query, filter);
    }, 300);

    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [query, filter, executeSearch]);

  const handleFilterChange = (f: MediaFilter) => {
    setFilter(f);
    if (query.trim()) {
      executeSearch(query, f);
    }
  };

  return (
    <div className="w-full relative z-[100] flex flex-col gap-3" ref={wrapperRef}>
      {/* Search input */}
      <div className={`relative flex items-center w-full h-14 bg-white/5 backdrop-blur-md border rounded-full px-5 transition-all duration-300 shadow-[0_20px_40px_rgba(0,0,0,0.5)] z-20 ${
        focused ? 'bg-white/10 border-primary shadow-[0_0_24px_rgba(245,158,11,0.15)]' : 'border-white/10'
      }`}>
        <span className={`flex items-center justify-center mr-3 transition-colors duration-300 ${focused ? 'text-primary' : 'text-on-surface-variant'}`}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="11" cy="11" r="8" />
            <path d="M21 21l-4.35-4.35" />
          </svg>
        </span>
        <input
          ref={inputRef}
          type="text"
          className="grow bg-transparent border-none outline-none text-on-surface font-body-md text-lg w-full placeholder-on-surface-variant/50"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => setFocused(true)}
          placeholder={PLACEHOLDER_TEXTS[placeholderIdx]}
          aria-label="Search media"
        />
        {searching && (
          <span className="text-primary animate-spin flex items-center justify-center ml-3" aria-label="Searching">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" />
            </svg>
          </span>
        )}
        {query && !searching && (
          <button
            className="text-on-surface-variant flex items-center justify-center ml-3 p-1 rounded-full cursor-pointer hover:text-on-surface hover:bg-white/10 transition-all"
            onClick={() => {
              setQuery('');
              inputRef.current?.focus();
            }}
            aria-label="Clear search"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
              <path d="M18 6L6 18M6 6l12 12" />
            </svg>
          </button>
        )}
      </div>

      {/* Type filter pills */}
      <div className="flex space-x-3 overflow-x-auto no-scrollbar pb-1">
        {FILTER_OPTIONS.map((opt) => {
          const active = filter === opt.value;
          return (
            <button
              key={opt.value}
              className={`px-6 py-2 rounded-full font-label-sm text-[12px] whitespace-nowrap font-bold transition-all active:scale-95 ${
                active
                  ? 'bg-gradient-to-r from-primary to-secondary text-surface shadow-[0_10px_20px_rgba(245,158,11,0.2)]'
                  : 'bg-surface-container/40 backdrop-blur-lg border border-white/10 text-on-surface-variant hover:text-on-surface hover:bg-white/10'
              }`}
              onClick={() => handleFilterChange(opt.value)}
            >
              {opt.label}
            </button>
          );
        })}
      </div>

      {/* Dropdown Overlay */}
      <AnimatePresence>
        {focused && query.trim() && (
          <motion.div 
            initial={{ opacity: 0, y: -10, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -10, scale: 0.98 }}
            transition={{ duration: 0.2, ease: 'easeOut' }}
            className="absolute top-[calc(100%+8px)] left-0 right-0 bg-surface-container-high/95 backdrop-blur-3xl border border-white/10 rounded-3xl shadow-[0_30px_60px_rgba(0,0,0,0.7)] max-h-[60vh] overflow-y-auto z-50 flex flex-col py-3 no-scrollbar origin-top"
          >
            {searching && !results.length ? (
              <div className="flex flex-col gap-2 px-3 py-2">
                {[...Array(4)].map((_, i) => (
                  <div key={i} className="flex items-center gap-4 px-3 py-2 animate-pulse">
                    <div className="w-12 h-16 bg-white/10 rounded-lg shrink-0" />
                    <div className="flex flex-col gap-2 w-full">
                      <div className="h-4 bg-white/10 rounded w-3/4" />
                      <div className="h-3 bg-white/10 rounded w-1/4" />
                    </div>
                  </div>
                ))}
              </div>
          ) : results.length > 0 ? (
            results.map((media) => (
              <Link
                key={media.id}
                href={`/media/${media.type}/${media.externalId}`}
                className="flex items-center gap-4 px-4 py-3 cursor-pointer hover:bg-white/5 focus:bg-white/5 transition-all text-left no-underline"
                onClick={() => setFocused(false)}
              >
                {media.posterUrl ? (
                  <div className="relative w-12 h-16 shrink-0 rounded-lg overflow-hidden bg-white/5 border border-white/10">
                    <Image
                      src={media.posterUrl}
                      alt={media.title}
                      fill
                      sizes="3rem"
                      className="object-cover"
                    />
                  </div>
                ) : (
                  <div className="w-12 h-16 shrink-0 rounded-lg bg-white/5 border border-white/10" />
                )}
                <div className="flex flex-col gap-1 overflow-hidden">
                  <div className="font-headline-lg text-base font-bold text-on-surface truncate">{media.title}</div>
                  <div className="flex items-center gap-2 text-sm text-on-surface-variant">
                    <span className="bg-white/10 border border-white/10 px-1.5 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider text-on-surface">{media.type}</span>
                    {media.releaseDate && <span>{new Date(media.releaseDate).getFullYear()}</span>}
                    {media.rating && media.rating > 0 ? <span className="text-primary-fixed-dim">★ {media.rating.toFixed(1)}</span> : null}
                  </div>
                </div>
              </Link>
            ))
          ) : hasSearched ? (
            <div className="p-10 text-center flex flex-col items-center gap-3">
              <span className="text-4xl">🔍</span>
              <div className="text-on-surface-variant font-label-md">No results found for <span className="text-white font-bold">"{query}"</span></div>
            </div>
          ) : null}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

export default function SearchBar() {
  return (
    <Suspense fallback={
      <div className="relative flex items-center w-full h-14 bg-white/5 backdrop-blur-md border border-white/10 rounded-full px-5 transition-all duration-300 shadow-[0_20px_40px_rgba(0,0,0,0.5)] z-20">
        <span className="flex items-center justify-center mr-3 text-on-surface-variant">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="11" cy="11" r="8" />
            <path d="M21 21l-4.35-4.35" />
          </svg>
        </span>
        <input
          type="text"
          className="grow bg-transparent border-none outline-none text-on-surface font-body-md text-lg w-full placeholder-on-surface-variant/50"
          placeholder="Search movies, shows, genres..."
          disabled
        />
      </div>
    }>
      <SearchBarInner />
    </Suspense>
  );
}
