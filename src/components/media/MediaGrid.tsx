'use client';

import type { Media } from '@/types/media';
import MediaCard, { MediaCardSkeleton } from './MediaCard';

interface MediaGridProps {
  items: Media[];
  loading?: boolean;
  emptyMessage?: string;
  layout?: 'grid' | 'horizontal';
  onAddToWatchlist?: (media: Media) => void;
}

export default function MediaGrid({
  items,
  loading = false,
  emptyMessage = 'No media found',
  layout = 'grid',
  onAddToWatchlist,
}: MediaGridProps) {
  const containerClass = layout === 'horizontal' 
    ? "flex overflow-x-auto gap-4 md:gap-gutter no-scrollbar pb-6 px-1"
    : "grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 md:gap-gutter";

  if (loading) {
    return (
      <div className={containerClass}>
        {Array.from({ length: layout === 'horizontal' ? 6 : 10 }, (_, i) => (
          <div key={i} className={layout === 'horizontal' ? "min-w-[160px] md:min-w-[200px]" : "w-full"}>
            <MediaCardSkeleton />
          </div>
        ))}
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-on-surface-variant">
        <span className="material-symbols-outlined text-6xl mb-4 opacity-50">movie</span>
        <p className="font-body-md text-[16px]">{emptyMessage}</p>
      </div>
    );
  }

  return (
    <div className={containerClass}>
      {items.map((media, i) => (
        <div key={media.externalId ?? media.id ?? i} className={layout === 'horizontal' ? "min-w-[160px] md:min-w-[200px] flex-shrink-0" : "w-full"}>
          <MediaCard
            media={media}
            index={i}
            onAddToWatchlist={onAddToWatchlist}
          />
        </div>
      ))}
    </div>
  );
}
