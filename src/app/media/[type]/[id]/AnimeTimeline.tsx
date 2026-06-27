"use client";

import { useState, useRef, useEffect, ReactNode } from "react";
import { createPortal } from "react-dom";
import Image from "next/image";
import Link from "next/link";
import { Season, Media } from "@/types/media";
import { ChevronLeft, ChevronRight, Check, Layers, Sparkles } from "lucide-react";
import { useWatchlist } from "@/lib/contexts/WatchlistContext";
import styles from "./mediaDetail.module.css";

interface AnimeTimelineProps {
  seasons: Season[];
  type: string;
  media: Media | null;
}

export default function AnimeTimeline({
  seasons,
  type,
  media,
}: AnimeTimelineProps) {
  const [mainStoryOnly, setMainStoryOnly] = useState(false);
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const [showLeftArrow, setShowLeftArrow] = useState(false);
  const [showRightArrow, setShowRightArrow] = useState(true);
  const [dropdownState, setDropdownState] = useState<{ idx: number, rect: DOMRect } | null>(null);
  const [mounted, setMounted] = useState(false);
  const { watchlist, updateStatus, updateProgress, addToWatchlist, removeFromWatchlist } = useWatchlist();

  useEffect(() => {
    if (dropdownState) {
      const handleScroll = () => setDropdownState(null);
      window.addEventListener('scroll', handleScroll, true);
      return () => window.removeEventListener('scroll', handleScroll, true);
    }
  }, [dropdownState]);

  useEffect(() => {
    setMounted(true);
  }, []);

  const isAnime =
    type === "anime" ||
    (media?.originCountry === "JP" &&
      media?.genres.some((g) => g.name === "Animation"));

  // Clean, metadata-driven filtering
  const displayedSeasons = mainStoryOnly
    ? seasons.filter((s) => {
        // If we have AniList metadata, use it as the source of truth
        if (s.relationType) {
          // These 4 relationships dictate the Canon "Main" Timeline
          const canonRelations = ["CURRENT", "PREQUEL", "SEQUEL", "PARENT"];
          return canonRelations.includes(s.relationType.toUpperCase());
        }

        // Fallback for non-anime TMDB data that lacks AniList graphs
        return true;
      })
    : seasons;

  const handleScroll = () => {
    if (!scrollContainerRef.current) return;
    const { scrollLeft, scrollWidth, clientWidth } = scrollContainerRef.current;

    // Show/hide arrows based on scroll position
    setShowLeftArrow(scrollLeft > 0);
    setShowRightArrow(Math.ceil(scrollLeft + clientWidth) < scrollWidth);
  };

  const scroll = (direction: "left" | "right") => {
    if (scrollContainerRef.current) {
      const container = scrollContainerRef.current;
      const card = container.querySelector(`.${styles.minimalCardWrapper}`);

      let scrollAmount = container.clientWidth / 2;
      if (card) {
        const cardWidth = card.getBoundingClientRect().width;
        const track = container.querySelector(`.${styles.minimalTrack}`);
        const gap = track
          ? parseFloat(
              window.getComputedStyle(track).columnGap ||
                window.getComputedStyle(track).gap ||
                "32",
            )
          : 32;
        scrollAmount = cardWidth + gap;
      }

      container.scrollBy({
        left: direction === "left" ? -scrollAmount : scrollAmount,
        behavior: "smooth",
      });
    }
  };

  // Add scroll listener on mount / updates
  useEffect(() => {
    const container = scrollContainerRef.current;
    if (container) {
      container.addEventListener("scroll", handleScroll);
      // Initial check
      handleScroll();
      return () => container.removeEventListener("scroll", handleScroll);
    }
  }, [displayedSeasons]);

  if (!seasons || seasons.length === 0) return null;

  return (
    <div className={styles.minimalTimelineSection}>
      <div className={styles.minimalHeader}>
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 w-full mb-4">
          <div className="flex items-baseline gap-4">
            <h3 className={styles.minimalTitle}>
              {isAnime ? "Franchise" : "Seasons"}
            </h3>
            <p className="font-label-sm text-primary tracking-[0.2em] uppercase font-black text-[12px] opacity-90">Watch Order</p>
          </div>

          {isAnime && (
            <div className="flex flex-col sm:flex-row items-center gap-4">
              <div className="flex items-center p-1 bg-[#0a0a0a]/80 backdrop-blur-3xl border border-white/[0.08] rounded-full w-full sm:w-auto shadow-inner relative overflow-hidden">
                <button
                  onClick={() => setMainStoryOnly(false)}
                  className={`relative px-5 md:px-6 py-2 rounded-full font-label-sm text-[11px] md:text-[12px] font-bold whitespace-nowrap transition-all duration-500 ease-out flex items-center justify-center gap-2 flex-shrink-0 z-10 w-1/2 sm:w-auto ${
                    !mainStoryOnly
                      ? "text-white drop-shadow-md"
                      : "text-white/40 hover:text-white/70"
                  }`}
                >
                  {!mainStoryOnly && (
                    <div className="absolute inset-0 bg-white/10 rounded-full -z-10 shadow-[inset_0_1px_1px_rgba(255,255,255,0.2)] border border-white/[0.05]" />
                  )}
                  <Layers className={`w-[14px] h-[14px] transition-colors duration-500 ${!mainStoryOnly ? 'text-blue-400 drop-shadow-[0_0_8px_rgba(96,165,250,0.8)]' : ''}`} />
                  <span className="tracking-widest uppercase mt-[1px]">All Content</span>
                </button>
                
                <button
                  onClick={() => setMainStoryOnly(true)}
                  className={`relative px-5 md:px-6 py-2 rounded-full font-label-sm text-[11px] md:text-[12px] font-bold whitespace-nowrap transition-all duration-500 ease-out flex items-center justify-center gap-2 flex-shrink-0 z-10 w-1/2 sm:w-auto ${
                    mainStoryOnly
                      ? "text-white drop-shadow-md"
                      : "text-white/40 hover:text-white/70"
                  }`}
                >
                  {mainStoryOnly && (
                    <div className="absolute inset-0 bg-white/10 rounded-full -z-10 shadow-[inset_0_1px_1px_rgba(255,255,255,0.2)] border border-white/[0.05]" />
                  )}
                  <Sparkles className={`w-[14px] h-[14px] transition-colors duration-500 ${mainStoryOnly ? 'text-amber-400 drop-shadow-[0_0_8px_rgba(251,191,36,0.8)]' : ''}`} />
                  <span className="tracking-widest uppercase mt-[1px]">Main Story</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="relative w-full group/timeline mt-6">
        {/* Decorative horizontal timeline line */}
        <div className="absolute top-[35%] left-0 right-0 h-[2px] bg-gradient-to-r from-transparent via-white/10 to-transparent z-0 pointer-events-none" />
        
        <button
          onClick={() => scroll("left")}
          disabled={!showLeftArrow}
          className={`absolute left-4 top-[32%] -translate-y-1/2 z-50 w-14 h-14 flex items-center justify-center rounded-full bg-black/50 backdrop-blur-xl border border-white/20 shadow-[0_8px_32px_rgba(0,0,0,0.6)] transition-all duration-500 ${
            showLeftArrow
              ? "text-white hover:bg-white hover:text-black cursor-pointer hover:scale-110 opacity-0 group-hover/timeline:opacity-100 translate-x-4 group-hover/timeline:translate-x-0"
              : "opacity-0 pointer-events-none"
          }`}
          aria-label="Scroll left"
        >
          <ChevronLeft className="w-8 h-8 ml-[-2px]" />
        </button>

        <button
          onClick={() => scroll("right")}
          disabled={!showRightArrow}
          className={`absolute right-4 top-[32%] -translate-y-1/2 z-50 w-14 h-14 flex items-center justify-center rounded-full bg-black/50 backdrop-blur-xl border border-white/20 shadow-[0_8px_32px_rgba(0,0,0,0.6)] transition-all duration-500 ${
            showRightArrow
              ? "text-white hover:bg-white hover:text-black cursor-pointer hover:scale-110 opacity-0 group-hover/timeline:opacity-100 -translate-x-4 group-hover/timeline:translate-x-0"
              : "opacity-0 pointer-events-none"
          }`}
          aria-label="Scroll right"
        >
          <ChevronRight className="w-8 h-8 mr-[-2px]" />
        </button>

        {/* Scrollable Container */}
        <div
          ref={scrollContainerRef}
          className="w-full overflow-x-auto overflow-y-hidden scroll-smooth snap-x snap-mandatory hide-scrollbar relative z-10 pb-16 pt-12 -mt-12"
        >
          <div className="flex gap-6 md:gap-8 px-6 md:px-12 w-max">
            {displayedSeasons.map((season, idx) => {
              const cleanMediaId = season.mediaId ? String(season.mediaId).replace(/anilist-/g, '').replace(/tmdb-movie-/g, '') : '';
              const savedItem = cleanMediaId ? watchlist.find(i => i.externalId === cleanMediaId || i.id === `anilist-${cleanMediaId}` || i.id === `tmdb-movie-${cleanMediaId}`) : null;
              const isCompleted = savedItem?.status === 'completed';
              const isWatching = savedItem?.status === 'watching';
              const progress = savedItem?.progress || 0;

              const CardContent = (
                <div className="relative flex flex-col h-full group/card z-10 pt-8">
                  {/* Huge background number */}
                  <div className="absolute top-0 left-[-10px] text-[7rem] leading-none font-black tracking-tighter text-white/[0.03] select-none pointer-events-none transition-all duration-700 ease-out group-hover/card:text-white/[0.08] group-hover/card:-translate-y-2 group-hover/card:scale-110 origin-bottom-left z-0">
                    {String(idx + 1).padStart(2, "0")}
                  </div>

                  <div className={`relative w-full aspect-[2/3] rounded-2xl overflow-hidden bg-surface-container border border-white/5 shadow-2xl transition-all duration-500 ease-out group-hover/card:shadow-[0_20px_40px_rgba(0,0,0,0.8)] group-hover/card:-translate-y-2 z-10 ${
                      savedItem?.status === 'watching' ? 'ring-2 ring-blue-500/80 shadow-[0_0_30px_rgba(59,130,246,0.3)]' :
                      savedItem?.status === 'completed' ? 'ring-2 ring-green-500/80 shadow-[0_0_30px_rgba(34,197,94,0.3)]' :
                      savedItem?.status === 'plan_to_watch' ? 'ring-2 ring-orange-500/80 shadow-[0_0_30px_rgba(249,115,22,0.3)]' :
                      ''
                    }`}>
                      <div className="absolute inset-0 bg-gradient-to-tr from-white/0 via-white/[0.05] to-white/0 opacity-0 group-hover/card:opacity-100 transition-opacity duration-700 z-20 pointer-events-none" />

                      {season.posterUrl ? (
                        <Image
                          src={season.posterUrl}
                          alt={season.name}
                          fill
                          sizes="(max-width: 768px) 12rem, 16rem"
                          className="object-cover transition-transform duration-700 ease-out group-hover/card:scale-110"
                          priority={idx < 4}
                        />
                      ) : (
                        <div className="absolute inset-0 bg-gradient-to-br from-surface-container to-surface flex items-center justify-center opacity-50" />
                      )}
                      
                      {/* Floating badging on top of poster */}
                      <div className="absolute top-2 left-2 z-30 flex flex-col gap-1">
                        <span className="bg-black/60 backdrop-blur-md text-white/90 border border-white/10 font-label-sm text-[10px] px-2.5 py-1 rounded-md shadow-lg uppercase font-bold tracking-wider">
                          Part {String(idx + 1).padStart(2, "0")}
                        </span>
                      </div>
                      
                      {/* Status overlay (if watching) */}
                      {isWatching && progress > 0 && (
                        <div className="absolute top-2 right-2 z-30">
                          <span className="flex items-center justify-center text-[10px] font-bold uppercase tracking-wider text-blue-100 bg-blue-500/80 backdrop-blur-md px-2 py-1 rounded-md shadow-lg border border-blue-400/50">
                            EP {progress}
                          </span>
                        </div>
                      )}
                  </div>

                  <div className="flex flex-col mt-4 gap-1.5 px-1 relative z-20">
                    <h4 className="font-headline-sm text-[15px] md:text-[17px] font-bold text-white leading-tight line-clamp-2 group-hover/card:text-primary transition-colors duration-300">
                      {season.name}
                    </h4>
                    
                    <div className="flex items-center gap-2 mt-0.5">
                      {season.episodeCount > 0 && (
                        <span className="font-label-sm text-[11px] text-white/50 tracking-wide font-medium">
                          {season.episodeCount} EP
                        </span>
                      )}
                      {season.format && (
                        <>
                          <span className="text-white/20 text-[10px]">•</span>
                          <span className="font-label-sm text-[11px] text-white/50 uppercase tracking-wider font-medium">
                            {season.format}
                          </span>
                        </>
                      )}
                    </div>
                      
                    {/* Interactive Status Editor */}
                    <div className="mt-3 relative z-30 w-full" onClick={(e) => { e.preventDefault(); e.stopPropagation(); }}>
                      <button
                        onClick={(e) => {
                          if (dropdownState?.idx === idx) {
                            setDropdownState(null);
                          } else {
                            const rect = e.currentTarget.getBoundingClientRect();
                            setDropdownState({ idx, rect });
                          }
                        }}
                        className={`w-full flex items-center justify-center gap-2 bg-white/5 backdrop-blur-sm border border-white/10 text-[10px] md:text-[11px] font-bold uppercase tracking-widest px-3 py-2 rounded-lg outline-none transition-all duration-300 cursor-pointer text-center hover:shadow-lg ${
                          savedItem?.status === 'watching' ? 'text-blue-400 border-blue-500/40 bg-blue-500/10 hover:bg-blue-500/20' :
                          savedItem?.status === 'completed' ? 'text-green-400 border-green-500/40 bg-green-500/10 hover:bg-green-500/20' :
                          savedItem?.status === 'plan_to_watch' ? 'text-orange-400 border-orange-500/40 bg-orange-500/10 hover:bg-orange-500/20' :
                          savedItem?.status === 'on_hold' || savedItem?.status === 'dropped' ? 'text-red-400 border-red-500/40 bg-red-500/10 hover:bg-red-500/20' :
                          'text-white/70 hover:text-white hover:bg-white/10 hover:border-white/20'
                        }`}
                      >
                        {savedItem ? (
                           <>
                             <span className="relative flex h-2 w-2">
                               <span className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-40 ${
                                 savedItem.status === 'watching' ? 'bg-blue-400' :
                                 savedItem.status === 'completed' ? 'bg-green-400' :
                                 savedItem.status === 'plan_to_watch' ? 'bg-orange-400' : 'bg-red-400'
                               }`}></span>
                               <span className={`relative inline-flex rounded-full h-2 w-2 ${
                                 savedItem.status === 'watching' ? 'bg-blue-500' :
                                 savedItem.status === 'completed' ? 'bg-green-500' :
                                 savedItem.status === 'plan_to_watch' ? 'bg-orange-500' : 'bg-red-500'
                               }`}></span>
                             </span>
                             {savedItem.status.replace(/_/g, ' ')}
                           </>
                        ) : '+ Add to List'}
                      </button>
                    </div>
                  </div>
                </div>
              );

              return season.mediaId && season.mediaType ? (
                <Link
                  key={season.number}
                  href={`/media/${season.mediaType}/${season.mediaId}`}
                  className="relative flex-shrink-0 w-[160px] md:w-[200px] lg:w-[240px] snap-start"
                  style={{ textDecoration: "none" }}
                >
                  {CardContent}
                </Link>
              ) : (
                <div key={season.number} className="relative flex-shrink-0 w-[160px] md:w-[200px] lg:w-[240px] snap-start">
                  {CardContent}
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Portal Dropdown Menu */}
      {mounted && dropdownState && createPortal(
        <>
          <div 
            className="fixed inset-0 z-[9998]" 
            onClick={() => setDropdownState(null)} 
          />
            {(() => {
              const isNearBottom = typeof window !== 'undefined' && dropdownState.rect.bottom + 250 > window.innerHeight;
              
              return (
                <div 
                  className="fixed z-[9999] bg-[#121212] border border-white/10 rounded-xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200"
                  style={{ 
                    top: isNearBottom ? 'auto' : (dropdownState.rect.bottom + 6) + 'px',
                    bottom: isNearBottom ? (window.innerHeight - dropdownState.rect.top + 6) + 'px' : 'auto',
                    left: Math.min(dropdownState.rect.left, typeof window !== 'undefined' ? window.innerWidth - 190 : dropdownState.rect.left) + 'px', 
                    minWidth: Math.max(dropdownState.rect.width, 140) + 'px',
                    width: 'max-content',
                    maxHeight: (isNearBottom ? dropdownState.rect.top - 10 : window.innerHeight - dropdownState.rect.bottom - 10) + 'px',
                    overflowY: 'auto'
                  }}
                >
                  {(() => {
                    const season = displayedSeasons[dropdownState.idx];
              const cleanMediaId = season.mediaId ? String(season.mediaId).replace(/anilist-/g, '').replace(/tmdb-movie-/g, '') : '';
              const savedItem = cleanMediaId ? watchlist.find(i => i.externalId === cleanMediaId || i.id === `anilist-${cleanMediaId}` || i.id === `tmdb-movie-${cleanMediaId}`) : null;
              const isCurrentlyWatching = savedItem?.status === 'watching';

              return (
                <div className="flex flex-col">
                  {isCurrentlyWatching && (
                    <div className="p-3 border-b border-white/10 bg-[#1a1a1a]/95 backdrop-blur-md" onClick={(e) => { e.stopPropagation(); }}>
                      <div className="flex flex-col items-center gap-2.5">
                        <span className="text-[10px] font-bold text-white/40 uppercase tracking-[0.15em] w-full text-center">Track Episode</span>
                        
                        <div className="flex items-center justify-center w-full gap-2">
                          <button 
                            onClick={(e) => { e.preventDefault(); e.stopPropagation(); updateProgress(savedItem.id, Math.max(0, (savedItem.progress || 0) - 1)); }}
                            className="w-8 h-8 flex-shrink-0 flex items-center justify-center rounded-full bg-white/5 hover:bg-white/10 text-white/70 hover:text-white transition-colors"
                          >
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                          </button>
                          
                          <div className="flex-1 flex items-center justify-center gap-1 bg-black/60 rounded-lg py-1.5 border border-white/5 shadow-inner">
                            <input 
                              type="number" 
                              min="0"
                              max={season.episodeCount || 999}
                              value={savedItem.progress || 0} 
                              onChange={(e) => {
                                 let val = parseInt(e.target.value) || 0;
                                 if (season.episodeCount && val > season.episodeCount) val = season.episodeCount;
                                 updateProgress(savedItem.id, val);
                              }}
                              className="w-7 bg-transparent text-center text-[14px] font-black text-white outline-none"
                              style={{ MozAppearance: 'textfield' }}
                            />
                            {season.episodeCount > 0 ? (
                              <div className="flex items-center text-white/40 font-bold text-[10px] pr-1.5">
                                <span>/</span>
                                <span className="ml-0.5">{season.episodeCount}</span>
                              </div>
                            ) : (
                               <span className="text-white/40 text-[10px] font-bold uppercase pr-2 tracking-wider">EP</span>
                            )}
                          </div>

                          <button 
                            onClick={(e) => { 
                              e.preventDefault(); e.stopPropagation(); 
                              const next = (savedItem.progress || 0) + 1;
                              if (season.episodeCount && next > season.episodeCount) return;
                              updateProgress(savedItem.id, next); 
                            }}
                            className="w-8 h-8 flex-shrink-0 flex items-center justify-center rounded-full bg-blue-500/20 hover:bg-blue-500/30 text-blue-400 hover:text-blue-300 transition-colors"
                          >
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                          </button>
                        </div>
                      </div>
                    </div>
                  )}
                  {[
                    { val: 'watching', label: 'Watching', color: 'text-blue-400 hover:bg-blue-500/10' },
                    { val: 'plan_to_watch', label: 'Plan to Watch', color: 'text-orange-400 hover:bg-orange-500/10' },
                    { val: 'completed', label: 'Completed', color: 'text-green-400 hover:bg-green-500/10' },
                    { val: 'on_hold', label: 'On Hold', color: 'text-red-400 hover:bg-red-500/10' },
                    { val: 'dropped', label: 'Dropped', color: 'text-red-400 hover:bg-red-500/10' },
                    { val: 'none', label: 'Remove', color: 'text-white/50 hover:bg-white/5 hover:text-white' },
                  ].map((opt) => (
                    <button
                      key={opt.val}
                      onClick={(e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        if (opt.val === 'none') {
                          if (savedItem) removeFromWatchlist(savedItem.id);
                        } else {
                          if (savedItem) {
                            updateStatus(savedItem.id, opt.val as any);
                          } else {
                            const prefix = (season.mediaType || type) === 'anime' ? 'anilist-' : 'tmdb-movie-';
                            const cleanMediaId = String(season.mediaId).replace(/anilist-/g, '').replace(/tmdb-movie-/g, '');
                            const pseudoMedia: any = {
                              id: `${prefix}${cleanMediaId}`,
                              externalId: cleanMediaId,
                              type: season.mediaType || type,
                              title: season.name,
                              posterUrl: season.posterUrl || '',
                              genres: media?.genres || [],
                              franchiseId: media?.franchiseId || undefined,
                              franchiseTitle: media?.franchiseTitle || media?.title,
                              franchisePosterUrl: media?.franchisePosterUrl || media?.posterUrl,
                            };
                            addToWatchlist(pseudoMedia, opt.val as any);
                          }
                        }
                        // Don't close immediately if selecting watching, so they can edit episodes!
                        if (opt.val !== 'watching') {
                           setDropdownState(null);
                        }
                      }}
                      className={`w-full text-left px-3 py-2.5 text-[11px] font-bold uppercase tracking-wider transition-colors border-b border-white/5 last:border-0 ${opt.color} ${savedItem?.status === opt.val ? 'bg-white/5' : ''}`}
                    >
                      {opt.label}
                    </button>
                  ))}
                </div>
              );
            })()}
          </div>
        );
      })()}
        </>,
        document.body
      )}

      {/* End of component */}
    </div>
  );
}
