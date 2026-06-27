"use client";

import { useState, useRef, useEffect, ReactNode } from "react";
import { createPortal } from "react-dom";
import Image from "next/image";
import Link from "next/link";
import { Season, Media } from "@/types/media";
import { ChevronLeft, ChevronRight, Check } from "lucide-react";
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
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: "16px",
            width: "100%",
          }}
        >
          <div style={{ display: "flex", alignItems: "baseline", gap: "16px" }}>
            <h3 className={styles.minimalTitle}>
              {isAnime ? "Franchise" : "Seasons"}
            </h3>
            <p className={styles.minimalSubtitle}>Watch order</p>
          </div>

          {isAnime && (
            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <button
                onClick={() => setMainStoryOnly(false)}
                style={{
                  background: !mainStoryOnly
                    ? "linear-gradient(135deg, #ffc174, #f59e0b)"
                    : "rgba(255, 255, 255, 0.05)",
                  color: !mainStoryOnly ? "#000" : "rgba(255, 255, 255, 0.7)",
                  border: !mainStoryOnly
                    ? "1px solid #f59e0b"
                    : "1px solid rgba(255, 255, 255, 0.1)",
                  padding: "8px 18px",
                  borderRadius: "20px",
                  fontSize: "0.9rem",
                  fontWeight: 600,
                  cursor: "pointer",
                  transition: "all 0.3s ease",
                  boxShadow: !mainStoryOnly
                    ? "0 4px 12px rgba(245, 158, 11, 0.3)"
                    : "none",
                }}
              >
                <span style={{ marginRight: "6px" }}>📺</span>
                All Content
              </button>
              <button
                onClick={() => setMainStoryOnly(true)}
                style={{
                  background: mainStoryOnly
                    ? "linear-gradient(135deg, #ffc174, #f59e0b)"
                    : "rgba(255, 255, 255, 0.05)",
                  color: mainStoryOnly ? "#000" : "rgba(255, 255, 255, 0.7)",
                  border: mainStoryOnly
                    ? "1px solid #f59e0b"
                    : "1px solid rgba(255, 255, 255, 0.1)",
                  padding: "8px 18px",
                  borderRadius: "20px",
                  fontSize: "0.9rem",
                  fontWeight: 600,
                  cursor: "pointer",
                  transition: "all 0.3s ease",
                  boxShadow: mainStoryOnly
                    ? "0 4px 12px rgba(245, 158, 11, 0.3)"
                    : "none",
                }}
              >
                <span style={{ marginRight: "6px" }}>✨</span>
                Main Story Only
              </button>
            </div>
          )}
        </div>
      </div>

      <div className={styles.timelineWrapper}>
        {/* Scrollable Container */}
        <div
          ref={scrollContainerRef}
          className={`${styles.minimalScrollContainer} hide-scrollbar`}
        >
          <div className={styles.minimalTrack}>
            {displayedSeasons.map((season, idx) => {
              const cleanMediaId = season.mediaId ? String(season.mediaId).replace(/anilist-/g, '').replace(/tmdb-movie-/g, '') : '';
              const savedItem = cleanMediaId ? watchlist.find(i => i.externalId === cleanMediaId || i.id === `anilist-${cleanMediaId}` || i.id === `tmdb-movie-${cleanMediaId}`) : null;
              const isCompleted = savedItem?.status === 'completed';
              const isWatching = savedItem?.status === 'watching';
              const progress = savedItem?.progress || 0;

              const CardContent = (
                <>
                  <div className={styles.minimalNumberBackground}>
                    {String(idx + 1).padStart(2, "0")}
                  </div>

                  <div className={styles.minimalCard}>
                    <div className={`${styles.minimalPosterContainer} transition-all duration-300 ${
                      savedItem?.status === 'watching' ? 'ring-2 ring-blue-500/80 ring-offset-4 ring-offset-[#121212] shadow-[0_0_30px_rgba(59,130,246,0.25)]' :
                      savedItem?.status === 'completed' ? 'ring-2 ring-green-500/80 ring-offset-4 ring-offset-[#121212] shadow-[0_0_30px_rgba(34,197,94,0.25)]' :
                      savedItem?.status === 'plan_to_watch' ? 'ring-2 ring-orange-500/80 ring-offset-4 ring-offset-[#121212] shadow-[0_0_30px_rgba(249,115,22,0.25)]' :
                      ''
                    }`}>
                      {season.posterUrl ? (
                        <Image
                          src={season.posterUrl}
                          alt={season.name}
                          fill
                          sizes="16rem"
                          className={styles.minimalPosterImage}
                          priority={idx < 4}
                        />
                      ) : (
                        <div className={styles.backdropFallback} />
                      )}
                    </div>

                    <div className={styles.minimalInfo}>
                      <span className={styles.minimalStepBadge}>
                        Part {String(idx + 1).padStart(2, "0")}
                        {season.format ? ` • ${season.format}` : ""}
                      </span>
                      <h4 className={styles.minimalSeasonTitle}>
                        {season.name}
                      </h4>
                      <div className="flex items-center gap-2 mt-1">
                        {season.episodeCount > 0 && (
                          <span className={styles.minimalEpisodeCount}>
                            {season.episodeCount} Episodes
                          </span>
                        )}
                        {isCompleted && (
                          <span className="flex items-center gap-1 text-[10px] font-bold uppercase tracking-wider text-green-400 bg-green-500/20 px-2 py-0.5 rounded-full border border-green-500/30">
                            <Check className="w-3 h-3" />
                          </span>
                        )}
                        {isWatching && progress > 0 && (
                          <span className="flex items-center gap-1 text-[10px] font-bold uppercase tracking-wider text-primary bg-primary/20 px-2 py-0.5 rounded-full border border-primary/30">
                            EP {progress}
                          </span>
                        )}
                      </div>
                      
                      {/* Interactive Status Editor */}
                      <div className="mt-3 relative z-20" onClick={(e) => { e.preventDefault(); e.stopPropagation(); }}>
                        <button
                          onClick={(e) => {
                            if (dropdownState?.idx === idx) {
                              setDropdownState(null);
                            } else {
                              const rect = e.currentTarget.getBoundingClientRect();
                              setDropdownState({ idx, rect });
                            }
                          }}
                          className={`w-full flex items-center justify-center gap-1 bg-white/5 border border-white/10 text-[11px] font-bold uppercase tracking-wider px-2 py-1.5 rounded outline-none transition-all cursor-pointer text-center shadow-sm hover:shadow-md ${
                            savedItem?.status === 'watching' ? 'text-blue-400 border-blue-500/30 bg-blue-500/10' :
                            savedItem?.status === 'completed' ? 'text-green-400 border-green-500/30 bg-green-500/10' :
                            savedItem?.status === 'plan_to_watch' ? 'text-orange-400 border-orange-500/30 bg-orange-500/10' :
                            savedItem?.status === 'on_hold' || savedItem?.status === 'dropped' ? 'text-red-400 border-red-500/30 bg-red-500/10' :
                            'text-on-surface-variant hover:text-white hover:bg-white/10'
                          }`}
                        >
                          {savedItem ? savedItem.status.replace(/_/g, ' ') : '+ ADD TO LIST'}
                        </button>
                      </div>

                    </div>
                  </div>
                </>
              );

              return season.mediaId && season.mediaType ? (
                <Link
                  key={season.number}
                  href={`/media/${season.mediaType}/${season.mediaId}`}
                  className={styles.minimalCardWrapper}
                  style={{ textDecoration: "none" }}
                >
                  {CardContent}
                </Link>
              ) : (
                <div key={season.number} className={styles.minimalCardWrapper}>
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

      {/* Navigation Arrows Grouped Below */}
      <div className="w-full flex items-center justify-center gap-4 mt-2">
        <button
          onClick={() => scroll("left")}
          disabled={!showLeftArrow}
          className={`w-12 h-12 flex items-center justify-center rounded-full bg-[#121212]/90 border border-white/10 backdrop-blur-sm shadow-lg transition-all duration-200 ${
            showLeftArrow
              ? "text-white hover:bg-white hover:text-black cursor-pointer"
              : "text-white/20 cursor-not-allowed"
          }`}
          aria-label="Scroll left"
        >
          <ChevronLeft className="w-8 h-8" />
        </button>

        <button
          onClick={() => scroll("right")}
          disabled={!showRightArrow}
          className={`w-12 h-12 flex items-center justify-center rounded-full bg-[#121212]/90 border border-white/10 backdrop-blur-sm shadow-lg transition-all duration-200 ${
            showRightArrow
              ? "text-white hover:bg-white hover:text-black cursor-pointer"
              : "text-white/20 cursor-not-allowed"
          }`}
          aria-label="Scroll right"
        >
          <ChevronRight className="w-8 h-8" />
        </button>
      </div>
    </div>
  );
}
