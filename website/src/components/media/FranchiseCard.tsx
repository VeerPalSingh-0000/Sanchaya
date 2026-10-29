'use client';

import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import type { WatchlistItem } from '@/types/media';
import { Image as ImageIcon, PlayCircle, Calendar } from 'lucide-react';

interface FranchiseCardProps {
  rootId?: string;
  rootTitle: string;
  rootPosterUrl: string;
  items: WatchlistItem[];
  index?: number;
  currentFilter?: string;
}

export default function FranchiseCard({ rootId, rootTitle, rootPosterUrl, items, index = 0, currentFilter }: FranchiseCardProps) {
  const router = useRouter();

  const sortedItems = [...items].sort((a, b) => {
    const timeA = a.releaseDate ? new Date(a.releaseDate).getTime() : NaN;
    const timeB = b.releaseDate ? new Date(b.releaseDate).getTime() : NaN;
    if (!isNaN(timeA) && !isNaN(timeB) && timeA !== timeB) {
      return timeA - timeB;
    }

    const cleanRootId = (rootId || '').replace(/^(anilist-|tmdb-movie-|tmdb-tv-)+/, '');
    const aClean = String(a.externalId || a.id).replace(/^(anilist-|tmdb-movie-|tmdb-tv-)+/, '');
    const bClean = String(b.externalId || b.id).replace(/^(anilist-|tmdb-movie-|tmdb-tv-)+/, '');
    if (cleanRootId) {
      if (aClean === cleanRootId) return -1;
      if (bClean === cleanRootId) return 1;
    }

    const aSeasonMatch = String(a.externalId || a.id).match(/-season-(\d+)/);
    const bSeasonMatch = String(b.externalId || b.id).match(/-season-(\d+)/);
    if (aSeasonMatch && bSeasonMatch) {
      const sDiff = parseInt(aSeasonMatch[1], 10) - parseInt(bSeasonMatch[1], 10);
      if (sDiff !== 0) return sDiff;
    }

    const aId = parseInt(aClean, 10);
    const bId = parseInt(bClean, 10);
    if (!isNaN(aId) && !isNaN(bId) && aId !== bId) {
      return aId - bId;
    }

    return a.title.localeCompare(b.title, undefined, { numeric: true, sensitivity: 'base' });
  });

  const filterMatchItem = currentFilter && currentFilter !== 'all'
    ? sortedItems.find(i => i.status === currentFilter)
    : null;

  const watchingItem = sortedItems.find(i => i.status === 'watching');
  const onHoldItem = sortedItems.find(i => i.status === 'on_hold');
  const firstUncompletedItem = sortedItems.find(i => i.status !== 'completed' && i.status !== 'dropped');

  const targetItem = filterMatchItem || watchingItem || onHoldItem || firstUncompletedItem || sortedItems[0];

  const posterSrc = (targetItem?.posterUrl && targetItem.posterUrl !== 'null')
    ? targetItem.posterUrl
    : (rootPosterUrl || sortedItems[0]?.posterUrl);
  const title = (targetItem?.title && targetItem.title !== 'Unknown')
    ? targetItem.title
    : ((rootTitle && rootTitle !== 'Unknown') ? rootTitle : sortedItems[0]?.title);

  return (
    <motion.article
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05, duration: 0.5, type: 'spring', stiffness: 100 }}
      className="relative overflow-hidden rounded-xl aspect-[2/3] group cursor-pointer glass-panel"
      onClick={() => {
        if (targetItem) {
          router.push(`/media/${targetItem.mediaType}/${targetItem.externalId}`);
        } else if (rootId && rootId.startsWith('anilist-')) {
          router.push(`/media/anime/${rootId.replace('anilist-', '')}`);
        }
      }}
    >
      <div className="block w-full h-full">
        {posterSrc ? (
          <img
            src={posterSrc}
            alt={title}
            className="absolute inset-0 w-full h-full object-cover transition-transform duration-500 md:group-hover:scale-110"
          />
        ) : (
          <div className="absolute inset-0 bg-surface-container flex flex-col items-center justify-center p-4">
            <ImageIcon className="w-10 h-10 text-on-surface-variant opacity-30 mb-2" />
            <span className="text-on-surface-variant text-center text-sm font-bold opacity-50 truncate w-full">{title}</span>
          </div>
        )}

        {/* Floating Badges */}
        <div className="absolute top-2 left-2 flex flex-col gap-1 z-10">
          <span className="bg-primary-container text-on-primary-container font-label-sm text-[10px] px-2 py-0.5 rounded shadow-lg uppercase font-bold tracking-wider">
            {(() => {
              const item = targetItem || items[0];
              if (!item) return 'Series';
              const isActuallyAnime = 
                item.mediaType === 'anime' || 
                (rootId && rootId.startsWith('anilist-')) ||
                (item.id && String(item.id).startsWith('anilist-')) ||
                (item.externalId && String(item.externalId).startsWith('anilist-')) ||
                ((item.mediaType === 'series' || item.mediaType === 'movie') && 
                 ((item as any).originCountry === 'JP' || (item as any).originalLanguage === 'ja' || (item.title && item.title.match(/[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff]/))) && 
                 (item.genres ?? []).some((g) => g.name === 'Animation' || g.id === 16));
              return isActuallyAnime ? 'Anime' : (item.mediaType === 'movie' ? 'Movie' : 'Series');
            })()}
          </span>
        </div>

        {/* Dynamic Progress Badge */}
        {watchingItem && (watchingItem.progress || 0) > 0 && (
          <div className="absolute top-2 right-2 z-30 px-2 py-1 bg-black/60 backdrop-blur-md rounded border border-white/10 shadow-lg flex flex-col items-end">
            <span className="text-[9px] uppercase tracking-wider font-bold text-primary/80 mb-[2px] leading-none">Currently On</span>
            <div className="flex items-baseline gap-1">
              <span className="font-bold text-white text-[12px] leading-none">EP {watchingItem.progress}</span>
              {watchingItem.totalEpisodes && (
                <span className="text-white/50 text-[10px] leading-none">/ {watchingItem.totalEpisodes}</span>
              )}
            </div>
          </div>
        )}

        {/* Hover Overlay */}
        <div className="absolute inset-0 bg-black/80 backdrop-blur-md opacity-0 md:group-hover:opacity-100 transition-opacity duration-300 flex flex-col justify-center items-center p-4 text-center border-t border-white/10 mt-auto h-full z-20">
          <PlayCircle className="w-16 h-16 text-primary mb-4 transition-transform duration-300 md:group-hover:scale-110" />
          <h3 className="font-headline-lg-mobile text-[18px] font-bold text-on-surface mb-1 line-clamp-2">{title}</h3>
          
          <div className="flex flex-col items-center gap-2 mt-2">
            <p className="font-label-sm text-[12px] text-on-surface-variant">
              {(targetItem?.genres ?? items[0]?.genres ?? []).slice(0, 2).map(g => g.name).join(', ')}
            </p>
            {targetItem?.releaseDate && (
              <div className="flex items-center gap-1.5 text-[11px] text-on-surface-variant bg-white/5 px-2.5 py-1 rounded-full border border-white/10 shadow-inner">
                <Calendar className="w-3.5 h-3.5 text-primary/80" />
                <span className="font-medium tracking-wide">
                  {new Date(targetItem.releaseDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                </span>
              </div>
            )}
          </div>
        </div>
      </div>
    </motion.article>
  );
}
