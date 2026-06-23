"use client";

import { useState, useEffect, useRef } from "react";
import Link from "next/link";
import type { Media } from "@/types/media";
import MediaCard from "@/components/media/MediaCard";
import { useWatchlist } from "@/lib/contexts/WatchlistContext";
import { fetchDiscoverData, MediaTypeFilter, FilterCategory } from "./actions";

interface DiscoverClientProps {
  items: Media[];
}

// Categories definition
const categories: { id: FilterCategory; label: string }[] = [
  { id: "all", label: "All Genres" },
  { id: "action", label: "Action" },
  { id: "adventure", label: "Adventure" },
  { id: "drama", label: "Drama" },
  { id: "romance", label: "Romance" },
  { id: "comedy", label: "Comedy" },
  { id: "scifi", label: "Sci-Fi" },
  { id: "fantasy", label: "Fantasy" },
];

const mediaTypes: { id: MediaTypeFilter; label: string }[] = [
  { id: "all", label: "Everything" },
  { id: "movie", label: "Movies" },
  { id: "series", label: "Webseries" },
  { id: "anime", label: "Anime" },
];

export default function DiscoverClient({ items: initialItems }: DiscoverClientProps) {
  const [activeCategory, setActiveCategory] = useState<FilterCategory>("all");
  const [activeType, setActiveType] = useState<MediaTypeFilter>("all");
  
  const [items, setItems] = useState<Media[]>(initialItems);
  const [page, setPage] = useState<number>(1);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [hasMore, setHasMore] = useState<boolean>(true);

  const { addToWatchlist, removeFromWatchlist, isInWatchlist } = useWatchlist();
  
  const observerTarget = useRef<HTMLDivElement>(null);
  const initialRender = useRef(true);

  // Fetch when filters change
  useEffect(() => {
    if (initialRender.current) {
      initialRender.current = false;
      return;
    }

    let isMounted = true;
    const fetchNewData = async () => {
      setIsLoading(true);
      setPage(1);
      const newItems = await fetchDiscoverData(1, activeType, activeCategory);
      if (isMounted) {
        setItems(newItems);
        setHasMore(newItems.length > 0);
        setIsLoading(false);
      }
    };

    fetchNewData();
    return () => { isMounted = false; };
  }, [activeType, activeCategory]);

  // Fetch when page changes
  useEffect(() => {
    if (page === 1) return; // Handled by filter effect

    let isMounted = true;
    const loadMoreData = async () => {
      setIsLoading(true);
      const newItems = await fetchDiscoverData(page, activeType, activeCategory);
      if (isMounted) {
        if (newItems.length === 0) {
          setHasMore(false);
        } else {
          setItems((prev) => {
            // Avoid duplicates by tracking IDs
            const prevIds = new Set(prev.map(i => i.id));
            const uniqueNew = newItems.filter(i => !prevIds.has(i.id));
            return [...prev, ...uniqueNew];
          });
        }
        setIsLoading(false);
      }
    };

    loadMoreData();
    return () => { isMounted = false; };
  }, [page, activeType, activeCategory]);

  // Intersection Observer for Infinite Scroll
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && !isLoading && hasMore) {
          setPage((prev) => prev + 1);
        }
      },
      { threshold: 0.1 }
    );

    if (observerTarget.current) {
      observer.observe(observerTarget.current);
    }

    return () => {
      if (observerTarget.current) {
        observer.unobserve(observerTarget.current);
      }
    };
  }, [isLoading, hasMore]);

  // Extract featured bento item (first item in the filtered list)
  const featuredItem = items[0];
  const gridItems = items.slice(1);

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

        <div className="flex flex-col gap-4">
          {/* Media Type Pills */}
          <div className="flex overflow-x-auto gap-3 pb-2 no-scrollbar">
            {mediaTypes.map((type) => (
              <button
                key={type.id}
                onClick={() => setActiveType(type.id)}
                className={
                  activeType === type.id
                    ? "bg-white text-surface font-bold shadow-[0_10px_20px_rgba(255,255,255,0.1)] font-label-sm text-[13px] px-6 py-2.5 rounded-full whitespace-nowrap active:scale-95 transition-transform"
                    : "bg-surface-container/50 border border-white/5 text-on-surface font-label-sm text-[13px] px-6 py-2.5 rounded-full hover:bg-white/10 transition-colors whitespace-nowrap active:scale-95 font-medium"
                }
              >
                {type.label}
              </button>
            ))}
          </div>

          {/* Category Pills */}
          <div className="flex overflow-x-auto gap-3 pb-2 no-scrollbar">
            {categories.map((cat) => (
              <button
                key={cat.id}
                onClick={() => setActiveCategory(cat.id)}
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
        </div>
      </header>

      {/* Grid Content */}
      {items.length > 0 ? (
        <section className="flex flex-col gap-8">
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4 md:gap-gutter">
            {/* Bento Feature Card (Takes 2 cols on Desktop) */}
            {featuredItem && (
              <article className="col-span-2 relative overflow-hidden rounded-xl aspect-[4/3] md:aspect-[2/3] lg:aspect-[4/3] group cursor-pointer glass-panel">
                <Link
                  href={`/media/${featuredItem.type}/${featuredItem.externalId}`}
                  className="block w-full h-full"
                >
                  {featuredItem.posterUrl ? (
                    <img
                      src={featuredItem.posterUrl}
                      alt={featuredItem.title}
                      className="absolute inset-0 w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
                    />
                  ) : (
                    <div className="absolute inset-0 bg-surface-container flex flex-col items-center justify-center p-4">
                      <span className="material-symbols-outlined text-4xl text-on-surface-variant opacity-30 mb-2">
                        image
                      </span>
                    </div>
                  )}

                  <div className="absolute top-4 left-4 bg-primary text-on-primary font-label-sm text-[12px] font-bold px-3 py-1 rounded-full shadow-lg z-10">
                    Featured
                  </div>

                  <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/40 to-transparent backdrop-blur-[2px] opacity-100 md:opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex flex-col justify-end p-6 gap-3 z-20">
                    <div className="flex items-center gap-2">
                      <span className="text-primary font-label-sm text-[10px] border border-primary/30 bg-primary/10 px-2 py-0.5 rounded font-bold uppercase">
                        {featuredItem.type === "movie"
                          ? "Movie"
                          : featuredItem.type === "series"
                            ? "Series"
                            : "Anime"}
                      </span>
                      <span className="text-on-surface-variant font-label-sm text-[10px] font-bold">
                        {featuredItem.releaseDate
                          ? new Date(featuredItem.releaseDate).getFullYear()
                          : "TBA"}
                        {featuredItem.genres?.[0]
                          ? ` • ${featuredItem.genres[0].name}`
                          : ""}
                      </span>
                    </div>
                    <h2 className="font-headline-lg-mobile text-[24px] font-bold text-on-surface leading-tight">
                      {featuredItem.title}
                    </h2>
                    <div className="flex items-center gap-4 mt-2">
                      <button className="bg-white text-surface font-label-sm text-[12px] font-bold px-4 py-2 rounded-full flex items-center gap-2 hover:bg-tertiary transition-colors">
                        <span
                          className="material-symbols-outlined"
                          style={{ fontVariationSettings: "'FILL' 1" }}
                        >
                          play_arrow
                        </span>{" "}
                        View Details
                      </button>
                      <button
                        onClick={handleFeaturedWatchlistToggle}
                        className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors border ${
                          isFeaturedAdded
                            ? "bg-primary text-surface border-transparent"
                            : "bg-surface/50 backdrop-blur-md text-on-surface hover:bg-white/20 border-white/20"
                        }`}
                      >
                        <span
                          className="material-symbols-outlined"
                          style={
                            isFeaturedAdded
                              ? { fontVariationSettings: "'FILL' 1" }
                              : {}
                          }
                        >
                          {isFeaturedAdded ? "check" : "add"}
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
          </div>

          {/* Intersection Observer Target */}
          <div ref={observerTarget} className="w-full h-20 flex items-center justify-center">
            {isLoading && (
              <div className="w-8 h-8 rounded-full border-2 border-primary border-t-transparent animate-spin"></div>
            )}
            {!isLoading && !hasMore && (
              <span className="text-on-surface-variant font-body-sm">You've reached the end!</span>
            )}
          </div>
        </section>
      ) : (
        <div className="text-center py-20 text-on-surface-variant font-body-md flex flex-col items-center gap-4">
          {isLoading ? (
             <div className="w-8 h-8 rounded-full border-2 border-primary border-t-transparent animate-spin"></div>
          ) : (
            "No items found matching the selected category."
          )}
        </div>
      )}
    </main>
  );
}
