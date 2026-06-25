'use client';

import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import type { WatchlistItem } from '@/types/media';

interface FranchiseCardProps {
  rootId?: string;
  rootTitle: string;
  rootPosterUrl: string;
  items: WatchlistItem[];
  index?: number;
}

export default function FranchiseCard({ rootId, rootTitle, rootPosterUrl, items, index = 0 }: FranchiseCardProps) {
  const router = useRouter();

  const posterSrc = rootPosterUrl || items[0].posterUrl;
  const title = rootTitle !== 'Unknown' ? rootTitle : items[0].title;
  
  const watchingItem = items.find(i => i.status === 'watching');

  return (
    <motion.article
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05, duration: 0.5, type: 'spring', stiffness: 100 }}
      className="relative overflow-hidden rounded-xl aspect-[2/3] group cursor-pointer glass-panel"
      onClick={() => {
        if (watchingItem) {
          router.push(`/media/${watchingItem.mediaType}/${watchingItem.externalId}`);
        } else if (rootId && rootId.startsWith('anilist-')) {
          router.push(`/media/anime/${rootId.replace('anilist-', '')}`);
        } else {
          router.push(`/media/${items[0].mediaType}/${items[0].externalId}`);
        }
      }}
    >
      <div className="block w-full h-full">
        {posterSrc ? (
          <img
            src={posterSrc}
            alt={title}
            className="absolute inset-0 w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
          />
        ) : (
          <div className="absolute inset-0 bg-surface-container flex flex-col items-center justify-center p-4">
            <span className="material-symbols-outlined text-4xl text-on-surface-variant opacity-30 mb-2">image</span>
            <span className="text-on-surface-variant text-center text-sm font-bold opacity-50 truncate w-full">{title}</span>
          </div>
        )}

        {/* Floating Badges */}
        <div className="absolute top-2 left-2 flex flex-col gap-1 z-10">
          <span className="bg-primary-container text-on-primary-container font-label-sm text-[10px] px-2 py-0.5 rounded shadow-lg uppercase font-bold tracking-wider">
            {(() => {
              const item = items[0];
              if (!item) return 'Series';
              const isActuallyAnime = 
                item.mediaType === 'anime' || 
                ((item.mediaType === 'series' || item.mediaType === 'movie') && 
                 ((item as any).originCountry === 'JP' || (item.title && item.title.match(/[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff]/))) && 
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
        <div className="absolute inset-0 bg-black/80 backdrop-blur-md opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex flex-col justify-center items-center p-4 text-center border-t border-white/10 mt-auto h-full z-20">
          <span className="material-symbols-outlined text-[64px] text-primary mb-4 transition-transform duration-300 group-hover:scale-110" style={{ fontVariationSettings: "'FILL' 1" }}>play_circle</span>
          <h3 className="font-headline-lg-mobile text-[18px] font-bold text-on-surface mb-1 line-clamp-2">{title}</h3>
          
          <p className="font-label-sm text-[12px] text-on-surface-variant mt-1">
            {(items[0]?.genres ?? []).slice(0, 2).map(g => g.name).join(', ')}
          </p>
        </div>
      </div>
    </motion.article>
  );
}
