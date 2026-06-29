'use client';

import Image from 'next/image';
import Link from 'next/link';
import type { Media } from '@/types/media';
import { useWatchlist } from '@/lib/contexts/WatchlistContext';
import { motion } from 'framer-motion';
import { Image as ImageIcon, PlayCircle, Check, Plus } from 'lucide-react';

interface MediaCardProps {
  media: Media;
  onAddToWatchlist?: (media: Media) => void;
  index?: number;
}

export default function MediaCard({ media, onAddToWatchlist, index = 0 }: MediaCardProps) {
  const { addToWatchlist, removeFromWatchlist, isInWatchlist } = useWatchlist();
  
  const year = media.releaseDate ? new Date(media.releaseDate).getFullYear() : null;
  const genres = (media.genres ?? []).slice(0, 2);
  const posterSrc = media.posterUrl || null;
  const itemType = media.type || ('mediaType' in media ? (media as any).mediaType : 'movie');
  
  const isAdded = isInWatchlist(media.id);
  
  const itemStatus = 'status' in media ? (media as any).status : undefined;
  const progress = 'progress' in media ? (media as any).progress : 0;
  const totalEpisodes = media.totalEpisodes || ('totalEpisodes' in media ? (media as any).totalEpisodes : 0);
  const showProgress = progress && totalEpisodes;
  const progressPercent = showProgress ? Math.round((progress / totalEpisodes) * 100) : 0;

  return (
    <motion.article
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05, duration: 0.5, type: 'spring', stiffness: 100 }}
      className="relative overflow-hidden rounded-xl aspect-[2/3] group cursor-pointer glass-panel"
    >
      <Link
        href={`/media/${itemType}/${media.externalId}`}
        aria-label={`View ${media.title}`}
        className="relative block w-full h-full"
      >
        {posterSrc ? (
          <Image
            src={posterSrc}
            alt={media.title}
            fill
            sizes="(max-width: 768px) 50vw, (max-width: 1200px) 33vw, 20vw"
            className="object-cover transition-transform duration-500 group-hover:scale-110"
          />
        ) : (
          <div className="absolute inset-0 bg-surface-container flex flex-col items-center justify-center p-4">
            <ImageIcon className="w-10 h-10 text-on-surface-variant opacity-30 mb-2" />
            <span className="text-on-surface-variant text-center text-sm font-bold opacity-50 truncate w-full">{media.title}</span>
          </div>
        )}

        {/* Floating Badges */}
        <div className="absolute top-2 left-2 flex flex-col gap-1 z-10">
          <span className="bg-primary-container text-on-primary-container font-label-sm text-[10px] px-2 py-0.5 rounded shadow-lg uppercase font-bold tracking-wider">
            {(() => {
              const isActuallyAnime = 
                itemType === 'anime' || 
                ((itemType === 'series' || itemType === 'movie') && 
                 (media.originCountry === 'JP' || (media.title && media.title.match(/[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff]/))) && 
                 (media.genres ?? []).some((g) => g.name === 'Animation' || g.id === 16));
              return isActuallyAnime ? 'Anime' : (itemType === 'movie' ? 'Movie' : 'Series');
            })()}
          </span>
        </div>

        {/* Hover Overlay */}
        <div className="absolute inset-0 bg-black/80 backdrop-blur-md opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex flex-col justify-center items-center p-4 text-center border-t border-white/10 mt-auto h-full z-20">
          <PlayCircle className="w-16 h-16 text-primary mb-4 transition-transform duration-300 group-hover:scale-110" />
          <h3 className="font-headline-lg-mobile text-[18px] font-bold text-on-surface mb-1 line-clamp-2">{media.title}</h3>
          
          {showProgress ? (
            <div className="w-full mt-2">
              <div className="w-full h-1.5 bg-white/10 rounded-full overflow-hidden mb-1">
                <div className="h-full bg-primary" style={{ width: `${progressPercent}%` }} />
              </div>
              <div className="flex justify-between text-[10px] text-on-surface-variant font-label-sm">
                <span>Ep {progress}</span>
                <span>{progressPercent}%</span>
              </div>
            </div>
          ) : (
            <p className="font-label-sm text-[12px] text-on-surface-variant mt-1">
              {year && <span>{year}</span>}
              {year && genres.length > 0 && <span className="mx-1">•</span>}
              {genres.map(g => g.name).join(', ')}
            </p>
          )}
        </div>
      </Link>

      {/* Quick-add watchlist button */}
      {!isAdded && (
        <button
          type="button"
          onClick={(e) => {
            e.preventDefault();
            e.stopPropagation();
            addToWatchlist(media);
            if (onAddToWatchlist) onAddToWatchlist(media);
          }}
          className="absolute top-2 right-2 z-30 w-8 h-8 rounded-full flex items-center justify-center transition-colors shadow-lg bg-surface/50 backdrop-blur-md text-white border border-white/20 hover:bg-white/20"
          aria-label={`Add ${media.title} to watchlist`}
        >
          <Plus className="w-5 h-5 text-white" />
        </button>
      )}
    </motion.article>
  );
}

/** Skeleton placeholder for loading state */
export function MediaCardSkeleton() {
  return (
    <div className="relative overflow-hidden rounded-xl aspect-[2/3] glass-panel shimmer border-none w-full" />
  );
}
