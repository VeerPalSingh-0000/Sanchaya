'use client';

import { useState, useRef, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useWatchlist } from '@/lib/contexts/WatchlistContext';
import type { Media, WatchStatus } from '@/types/media';
import { Minus, Plus } from 'lucide-react';
import styles from './WatchlistButton.module.css';

interface WatchlistButtonProps {
  media: Media;
  hideEpisodeTracker?: boolean;
}

const STATUS_OPTIONS: { value: WatchStatus; label: string; color: string }[] = [
  { value: 'plan_to_watch', label: 'Plan to Watch', color: '#f59e0b' },
  { value: 'watching', label: 'Watching', color: '#22c55e' },
  { value: 'completed', label: 'Completed', color: '#3b82f6' },
  { value: 'on_hold', label: 'On Hold', color: '#94a3b8' },
  { value: 'dropped', label: 'Dropped', color: '#ef4444' },
];

export default function WatchlistButton({ media, hideEpisodeTracker = false }: WatchlistButtonProps) {
  const { watchlist, addToWatchlist, removeFromWatchlist, updateStatus, updateProgress } = useWatchlist();
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Find exact item
  const existingItem = watchlist.find((item) => item.id === String(media.id) || item.externalId === String(media.id));
  
  // Find all franchise items
  const franchiseItems = watchlist.filter(item => 
    (media.franchiseId && item.franchiseId === String(media.franchiseId)) || 
    item.id === String(media.id) || 
    item.externalId === String(media.id)
  );
  
  const isAdded = franchiseItems.length > 0;
  
  // Calculate aggregate status
  let currentStatus: WatchStatus = 'plan_to_watch';
  if (franchiseItems.length > 0) {
    if (franchiseItems.some(i => i.status === 'watching')) {
      currentStatus = 'watching';
    } else if (franchiseItems.every(i => i.status === 'completed')) {
      currentStatus = 'completed';
    } else if (franchiseItems.some(i => i.status === 'plan_to_watch')) {
      currentStatus = 'plan_to_watch';
    } else if (franchiseItems.some(i => i.status === 'on_hold')) {
      currentStatus = 'on_hold';
    } else {
      currentStatus = 'dropped';
    }
  }

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

  const handleStatusSelect = async (status: WatchStatus) => {
    if (franchiseItems.length > 0) {
      // Bulk update all franchise items currently in the watchlist
      franchiseItems.forEach(item => {
        updateStatus(item.id, status);
      });
      // If the specific item we are viewing isn't in the list yet, add it
      if (!existingItem) {
        addToWatchlist(media, status);
      }
    } else {
      let finalMedia = { ...media };
      if (!finalMedia.franchiseId) {
        try {
          const { getFranchiseMetadata } = await import('@/app/actions');
          const meta = await getFranchiseMetadata(finalMedia);
          finalMedia = { ...finalMedia, ...meta };
        } catch (e) {
          console.error('Failed to get franchise metadata', e);
        }
      }
      addToWatchlist(finalMedia, status);
    }
    setIsOpen(false);
  };

  const handleRemove = () => {
    if (franchiseItems.length > 0) {
      // Bulk remove all franchise items
      franchiseItems.forEach(item => {
        removeFromWatchlist(item.id);
      });
    }
    setIsOpen(false);
  };

  const currentOption = STATUS_OPTIONS.find((opt) => opt.value === currentStatus);

  const progress = existingItem?.progress || 0;
  const totalEpisodes = existingItem?.totalEpisodes || media.totalEpisodes;

  const handleProgressChange = (newProgress: number) => {
    if (!existingItem) return;
    const clampedProgress = Math.max(0, Math.min(newProgress, totalEpisodes || 9999));
    updateProgress(existingItem.id, clampedProgress);
    if (totalEpisodes && clampedProgress === totalEpisodes && currentStatus === 'watching') {
      updateStatus(existingItem.id, 'completed');
    }
  };

  return (
    <div className="flex flex-col gap-3 items-start">
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

      {(!hideEpisodeTracker && isAdded && currentStatus === 'watching') && (
        <div className="flex items-center gap-3 bg-surface-container/50 backdrop-blur-md border border-white/10 rounded-full p-1 shadow-lg animate-in fade-in slide-in-from-top-2">
          <button 
            onClick={() => handleProgressChange(progress - 1)}
            disabled={progress <= 0}
            className="w-8 h-8 flex items-center justify-center rounded-full bg-surface hover:bg-white/10 text-on-surface-variant transition-colors disabled:opacity-30 disabled:hover:bg-surface"
          >
            <Minus className="w-[18px] h-[18px]" />
          </button>
          
          <div className="flex items-center gap-1 min-w-[80px] justify-center px-2">
            <span className="font-headline-sm text-[16px] font-bold text-on-surface leading-none">{progress}</span>
            {totalEpisodes && (
              <>
                <span className="text-on-surface-variant opacity-50 text-[12px] leading-none">/</span>
                <span className="text-on-surface-variant text-[14px] leading-none">{totalEpisodes}</span>
              </>
            )}
            {!totalEpisodes && (
              <span className="text-on-surface-variant text-[12px] ml-1 uppercase tracking-wider font-bold">EP</span>
            )}
          </div>
          
          <button 
            onClick={() => handleProgressChange(progress + 1)}
            disabled={totalEpisodes ? progress >= totalEpisodes : false}
            className="w-8 h-8 flex items-center justify-center rounded-full bg-primary/20 hover:bg-primary/30 text-primary transition-colors disabled:opacity-30"
          >
            <Plus className="w-[18px] h-[18px]" />
          </button>
        </div>
      )}
    </div>
  );
}
