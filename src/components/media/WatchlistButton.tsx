'use client';

import { useState, useRef, useEffect } from 'react';
import { useWatchlist } from '@/lib/contexts/WatchlistContext';
import type { Media, WatchStatus } from '@/types/media';
import styles from './WatchlistButton.module.css';

interface WatchlistButtonProps {
  media: Media;
}

const STATUS_OPTIONS: { value: WatchStatus; label: string; color: string }[] = [
  { value: 'plan_to_watch', label: 'Plan to Watch', color: '#f59e0b' },
  { value: 'watching', label: 'Watching', color: '#22c55e' },
  { value: 'completed', label: 'Completed', color: '#3b82f6' },
  { value: 'on_hold', label: 'On Hold', color: '#94a3b8' },
  { value: 'dropped', label: 'Dropped', color: '#ef4444' },
];

export default function WatchlistButton({ media }: WatchlistButtonProps) {
  const { watchlist, addToWatchlist, removeFromWatchlist, updateStatus } = useWatchlist();
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  const existingItem = watchlist.find((item) => item.id === String(media.id));
  const isAdded = !!existingItem;
  const currentStatus = existingItem?.status || 'plan_to_watch';

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    if (isOpen) document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen]);

  const handleStatusSelect = (status: WatchStatus) => {
    if (isAdded) {
      updateStatus(String(media.id), status);
    } else {
      addToWatchlist(media, status);
    }
    setIsOpen(false);
  };

  const handleRemove = () => {
    removeFromWatchlist(String(media.id));
    setIsOpen(false);
  };

  const currentOption = STATUS_OPTIONS.find((opt) => opt.value === currentStatus);

  return (
    <div className={styles.container} ref={dropdownRef}>
      <button
        className={`${styles.button} ${isAdded ? styles.added : styles.add}`}
        onClick={() => setIsOpen(!isOpen)}
        aria-expanded={isOpen}
        style={isAdded ? { borderColor: currentOption?.color, boxShadow: `0 0 10px ${currentOption?.color}33` } : {}}
      >
        <span className={styles.icon}>
          {isAdded ? (
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={currentOption?.color || 'currentColor'} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M20 6L9 17l-5-5" />
            </svg>
          ) : (
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <line x1="12" y1="5" x2="12" y2="19" />
              <line x1="5" y1="12" x2="19" y2="12" />
            </svg>
          )}
        </span>
        <span className={styles.label} style={isAdded ? { color: currentOption?.color } : {}}>
          {isAdded ? currentOption?.label : 'Add to Watchlist'}
        </span>
        <svg
          className={`${styles.chevron} ${isOpen ? styles.chevronOpen : ''}`}
          width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={isAdded ? currentOption?.color : 'currentColor'} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
        >
          <polyline points="6 9 12 15 18 9" />
        </svg>
      </button>

      {isOpen && (
        <div className={styles.dropdown}>
          <div className={styles.menuItems}>
            {STATUS_OPTIONS.map((option) => (
              <button
                key={option.value}
                className={`${styles.menuItem} ${currentStatus === option.value && isAdded ? styles.activeItem : ''}`}
                onClick={() => handleStatusSelect(option.value)}
              >
                <span className={styles.statusDot} style={{ backgroundColor: option.color }} />
                {option.label}
              </button>
            ))}
          </div>
          
          {isAdded && (
            <>
              <div className={styles.divider} />
              <button className={styles.removeBtn} onClick={handleRemove}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2M10 11v6M14 11v6" />
                </svg>
                Remove from List
              </button>
            </>
          )}
        </div>
      )}
    </div>
  );
}
