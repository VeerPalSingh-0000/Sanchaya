'use client';

import { useState, useEffect, useRef, useCallback, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import type { Media, MediaFilter } from '@/types/media';
import { performSearch } from '@/app/actions';
import styles from './SearchBar.module.css';

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
    <div className={styles.wrapper} ref={wrapperRef}>
      {/* Search input */}
      <div className={`${styles.inputWrapper} ${focused ? styles.focused : ''}`}>
        <span className={styles.searchIcon}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="11" cy="11" r="8" />
            <path d="M21 21l-4.35-4.35" />
          </svg>
        </span>
        <input
          ref={inputRef}
          type="text"
          className={styles.input}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => setFocused(true)}
          placeholder={PLACEHOLDER_TEXTS[placeholderIdx]}
          aria-label="Search media"
        />
        {searching && (
          <span className={styles.spinner} aria-label="Searching">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" />
            </svg>
          </span>
        )}
        {query && !searching && (
          <button
            className={styles.clear}
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
      <div className={styles.filters}>
        {FILTER_OPTIONS.map((opt) => (
          <button
            key={opt.value}
            className={`${styles.pill} ${filter === opt.value ? styles.pillActive : ''}`}
            onClick={() => handleFilterChange(opt.value)}
          >
            {opt.label}
          </button>
        ))}
      </div>

      {/* Dropdown Overlay */}
      {focused && query.trim() && (
        <div className={styles.dropdown}>
          {searching && !results.length ? (
            <div className={styles.dropdownEmpty}>Searching...</div>
          ) : results.length > 0 ? (
            results.map((media) => (
              <Link
                key={media.id}
                href={`/media/${media.type}/${media.externalId}`}
                className={styles.dropdownItem}
                onClick={() => setFocused(false)}
              >
                {media.posterUrl ? (
                  <div className={styles.dropdownImageWrapper}>
                    <Image
                      src={media.posterUrl}
                      alt={media.title}
                      fill
                      sizes="3rem"
                      className={styles.dropdownImage}
                    />
                  </div>
                ) : (
                  <div className={styles.dropdownImage} />
                )}
                <div className={styles.dropdownInfo}>
                  <div className={styles.dropdownTitle}>{media.title}</div>
                  <div className={styles.dropdownMeta}>
                    <span className={styles.dropdownType}>{media.type}</span>
                    {media.releaseDate && <span>{new Date(media.releaseDate).getFullYear()}</span>}
                    {media.rating > 0 && <span>★ {media.rating.toFixed(1)}</span>}
                  </div>
                </div>
              </Link>
            ))
          ) : hasSearched ? (
            <div className={styles.dropdownEmpty}>
              No results found for "{query}"
            </div>
          ) : null}
        </div>
      )}
    </div>
  );
}

export default function SearchBar() {
  return (
    <Suspense fallback={
      <div className={styles.inputWrapper}>
        <span className={styles.searchIcon}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="11" cy="11" r="8" />
            <path d="M21 21l-4.35-4.35" />
          </svg>
        </span>
        <input
          type="text"
          className={styles.input}
          placeholder="Search movies, shows, genres..."
          disabled
        />
      </div>
    }>
      <SearchBarInner />
    </Suspense>
  );
}
