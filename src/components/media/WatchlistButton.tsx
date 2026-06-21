'use client';

import { useWatchlist } from '@/lib/contexts/WatchlistContext';
import type { Media } from '@/types/media';
import styles from './WatchlistButton.module.css';

interface WatchlistButtonProps {
  media: Media;
}

export default function WatchlistButton({ media }: WatchlistButtonProps) {
  const { isInWatchlist, addToWatchlist, removeFromWatchlist } = useWatchlist();

  const isAdded = isInWatchlist(media.id);

  const handleToggle = () => {
    if (isAdded) {
      removeFromWatchlist(media.id);
    } else {
      addToWatchlist(media);
    }
  };

  return (
    <button
      className={`${styles.button} ${isAdded ? styles.remove : styles.add}`}
      onClick={handleToggle}
      aria-label={isAdded ? 'Remove from Watchlist' : 'Add to Watchlist'}
    >
      <span className={styles.icon}>
        {isAdded ? (
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M20 6L9 17l-5-5" />
          </svg>
        ) : (
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <line x1="12" y1="5" x2="12" y2="19" />
            <line x1="5" y1="12" x2="19" y2="12" />
          </svg>
        )}
      </span>
      {isAdded ? 'Remove from Watchlist' : 'Add to Watchlist'}
    </button>
  );
}
