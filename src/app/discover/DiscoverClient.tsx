'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import type { Media, MediaType } from '@/types/media';
import MediaCard from '@/components/media/MediaCard';
import { useWatchlist } from '@/lib/contexts/WatchlistContext';

interface DiscoverClientProps {
  items: Media[];
}

type FilterCategory = 'all' | 'action' | 'adventure' | 'drama' | 'romance' | 'comedy' | 'scifi' | 'fantasy';

export default function DiscoverClient({ items }: DiscoverClientProps) {
  const [activeCategory, setActiveCategory] = useState<FilterCategory>('all');
  const { addToWatchlist, removeFromWatchlist, isInWatchlist } = useWatchlist();

  // Categories definition
  const categories = [
    { id: 'all', label: 'All Genres' },
    { id: 'action', label: 'Action' },
    { id: 'adventure', label: 'Adventure' },
    { id: 'drama', label: 'Drama' },
    { id: 'romance', label: 'Romance' },
    { id: 'comedy', label: 'Comedy' },
    { id: 'scifi', label: 'Sci-Fi' },
    { id: 'fantasy', label: 'Fantasy' },
  ] as const;

  // Filter logic
  const filteredItems = useMemo(() => {
    return items.filter((item) => {
      if (activeCategory === 'all') return true;
      const genres = (item.genres ?? []).map(g => g.name.toLowerCase());
      
      switch (activeCategory) {
        case 'action':
          return genres.some(g => g.includes('action'));
        case 'adventure':
          return genres.some(g => g.includes('adventure'));
        case 'drama':
          return genres.some(g => g.includes('drama'));
        case 'romance':
          return genres.some(g => g.includes('romance'));
        case 'comedy':
          return genres.some(g => g.includes('comedy'));
        case 'scifi':
          return genres.some(g => g.includes('sci-fi') || g.includes('science fiction'));
        case 'fantasy':
          return genres.some(g => g.includes('fantasy'));
        default:
          return true;
      }
    });
  }, [items, activeCategory]);

  // Extract featured bento item (first item in the filtered list)
  const featuredItem = filteredItems[0];
  const gridItems = filteredItems.slice(1);

  const isFeaturedAdded = featuredItem ? isInWatchlist(featuredItem.id) : false;

  const handleFeaturedWatchlistToggle = (e: React.MouseEvent) => {
    e.preventDefault();
    if (!featuredItem) return;
    if (isFeaturedAdded) {
      removeFromWatchlist(featuredItem.id);
    } else {
      addToWatchlist(featuredItem);
    }
  };

  return (
    <main className="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop pt-8 pb-32 md:pb-16 flex flex-col gap-12 slide-up">
      {/* Header Section */}
      <header className="flex flex-col gap-6">
        <h1 className="font-display-xl-mobile text-[40px] md:font-display-xl md:text-[64px] text-on-surface tracking-tight font-bold">
          Discover New Horizons
        </h1>
        
        {/* Category Pills */}
        <div className="flex overflow-x-auto gap-3 pb-2 no-scrollbar">
          {categories.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setActiveCategory(cat.id as FilterCategory)}
              className={
                activeCategory === cat.id
                  ? "bg-gradient-to-r from-primary to-secondary text-background font-bold shadow-[0_10px_20px_rgba(245,158,11,0.2)] font-label-sm text-[12px] px-5 py-2.5 rounded-full whitespace-nowrap active:scale-95 transition-transform"
                  : "glass-panel text-on-surface font-label-sm text-[12px] px-5 py-2.5 rounded-full hover:bg-white/10 transition-colors whitespace-nowrap active:scale-95 font-bold"
              }
            >
              {cat.label}
            </button>
          ))}
        </div>
      </header>

      {/* Grid Content */}
      {filteredItems.length > 0 ? (
        <section className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4 md:gap-gutter">
          {/* Bento Feature Card (Takes 2 cols on Desktop) */}
          {featuredItem && (
            <article className="col-span-2 relative overflow-hidden rounded-xl aspect-[4/3] md:aspect-[2/3] lg:aspect-[4/3] group cursor-pointer glass-panel">
              <Link href={`/media/${featuredItem.type}/${featuredItem.externalId}`} className="block w-full h-full">
                {featuredItem.posterUrl ? (
                  <img
                    src={featuredItem.posterUrl}
                    alt={featuredItem.title}
                    className="absolute inset-0 w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
                  />
                ) : (
                  <div className="absolute inset-0 bg-surface-container flex flex-col items-center justify-center p-4">
                    <span className="material-symbols-outlined text-4xl text-on-surface-variant opacity-30 mb-2">image</span>
                  </div>
                )}
                
                <div className="absolute top-4 left-4 bg-primary text-on-primary font-label-sm text-[12px] font-bold px-3 py-1 rounded-full shadow-lg z-10">
                  Featured
                </div>

                <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/40 to-transparent backdrop-blur-[2px] opacity-100 md:opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex flex-col justify-end p-6 gap-3 z-20">
                  <div className="flex items-center gap-2">
                    <span className="text-primary font-label-sm text-[10px] border border-primary/30 bg-primary/10 px-2 py-0.5 rounded font-bold uppercase">
                      {featuredItem.type === 'movie' ? 'Movie' : featuredItem.type === 'series' ? 'Series' : 'Anime'}
                    </span>
                    <span className="text-on-surface-variant font-label-sm text-[10px] font-bold">
                      {featuredItem.releaseDate ? new Date(featuredItem.releaseDate).getFullYear() : 'TBA'} 
                      {featuredItem.genres?.[0] ? ` • ${featuredItem.genres[0].name}` : ''}
                    </span>
                  </div>
                  <h2 className="font-headline-lg-mobile text-[24px] font-bold text-on-surface leading-tight">{featuredItem.title}</h2>
                  <div className="flex items-center gap-4 mt-2">
                    <button className="bg-white text-surface font-label-sm text-[12px] font-bold px-4 py-2 rounded-full flex items-center gap-2 hover:bg-tertiary transition-colors">
                      <span className="material-symbols-outlined" style={{ fontVariationSettings: "'FILL' 1" }}>play_arrow</span> View Details
                    </button>
                    <button 
                      onClick={handleFeaturedWatchlistToggle}
                      className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors border ${
                        isFeaturedAdded 
                          ? 'bg-primary text-surface border-transparent' 
                          : 'bg-surface/50 backdrop-blur-md text-on-surface hover:bg-white/20 border-white/20'
                      }`}
                    >
                      <span className="material-symbols-outlined" style={isFeaturedAdded ? { fontVariationSettings: "'FILL' 1" } : {}}>
                        {isFeaturedAdded ? 'check' : 'add'}
                      </span>
                    </button>
                  </div>
                </div>
              </Link>
            </article>
          )}

          {/* Standard Media Cards */}
          {gridItems.map((media, i) => (
            <MediaCard key={media.id} media={media} index={i} />
          ))}
        </section>
      ) : (
        <div className="text-center py-20 text-on-surface-variant font-body-md">
          No items found matching the selected category.
        </div>
      )}
    </main>
  );
}
