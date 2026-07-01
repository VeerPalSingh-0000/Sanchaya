'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import Link from 'next/link';
import { Media } from '@/types/media';
import { ChevronLeft, ChevronRight, Star, Play, Image as ImageIcon, Calendar } from 'lucide-react';

interface HeroCarouselProps {
  items: Media[];
}

export default function HeroCarousel({ items }: HeroCarouselProps) {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isHovered, setIsHovered] = useState(false);
  const touchStartX = useRef<number | null>(null);

  const nextSlide = useCallback(() => {
    setCurrentIndex((prev) => (prev + 1) % items.length);
  }, [items.length]);

  const prevSlide = useCallback(() => {
    setCurrentIndex((prev) => (prev - 1 + items.length) % items.length);
  }, [items.length]);

  // Autoplay
  useEffect(() => {
    if (isHovered || items.length <= 1) return;
    const timer = setInterval(nextSlide, 5000);
    return () => clearInterval(timer);
  }, [isHovered, items.length, nextSlide]);

  // Keyboard navigation
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft') prevSlide();
      if (e.key === 'ArrowRight') nextSlide();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [prevSlide, nextSlide]);

  // Touch swipe support
  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartX.current = e.touches[0].clientX;
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    if (touchStartX.current === null) return;
    const touchEndX = e.changedTouches[0].clientX;
    const diff = touchStartX.current - touchEndX;

    if (diff > 50) nextSlide();
    else if (diff < -50) prevSlide();
    
    touchStartX.current = null;
  };

  if (!items || items.length === 0) return null;

  const getVisibleItems = () => {
    const prev = (currentIndex - 1 + items.length) % items.length;
    const current = currentIndex;
    const next = (currentIndex + 1) % items.length;
    return [items[prev], items[current], items[next]];
  };

  const [prevItem, currentItem, nextItem] = getVisibleItems();

  const renderPosterFallback = (title: string) => (
    <div className="absolute inset-0 bg-surface-variant flex flex-col items-center justify-center p-4">
      <ImageIcon className="w-10 h-10 text-on-surface-variant opacity-30 mb-2" />
      <span className="text-on-surface-variant text-center text-sm font-bold opacity-50 truncate w-full">{title}</span>
    </div>
  );

  return (
    <div 
      className="relative w-full flex flex-col items-center justify-center py-10"
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
    >
      {/* Left Arrow */}
      {items.length > 1 && (
        <button 
          onClick={prevSlide}
          className="absolute left-4 md:left-margin-desktop z-20 bg-surface-container/30 hover:bg-surface-container/50 backdrop-blur-md border border-white/10 text-white p-3 rounded-full shadow-[0_10px_30px_rgba(0,0,0,0.5)] transition-all active:scale-90 hidden md:block"
          aria-label="Previous slide"
        >
          <ChevronLeft className="w-8 h-8" />
        </button>
      )}

      {/* Carousel Track */}
      <div className="flex items-center justify-center space-x-[-15%] md:space-x-[-10%] w-full max-w-[1200px]">
        {/* Previous Poster */}
        {items.length > 1 && (
          <div 
            onClick={prevSlide}
            className="relative w-[200px] md:w-[280px] aspect-[2/3] rounded-xl overflow-hidden opacity-40 scale-75 blur-[2px] transition-all duration-500 z-0 cursor-pointer"
          >
            {prevItem?.posterUrl ? (
              <img 
                src={prevItem.posterUrl} 
                alt={prevItem?.title || 'Previous'} 
                className="absolute inset-0 w-full h-full object-cover" 
              />
            ) : renderPosterFallback(prevItem?.title || 'Unknown')}
          </div>
        )}

        {/* Active Poster */}
        {currentItem && (
          <Link 
            href={`/media/${currentItem.type}/${currentItem.externalId}`}
            className="relative w-[260px] md:w-[400px] aspect-[2/3] rounded-2xl overflow-hidden group cursor-pointer border border-white/20 shadow-[0_30px_60px_rgba(0,0,0,0.7)] z-10 md:hover:shadow-[0_0_60px_rgba(245,158,11,0.4)] transition-all duration-500 md:hover:scale-105"
          >
            {currentItem.posterUrl ? (
              <img 
                src={currentItem.posterUrl} 
                alt={currentItem.title} 
                className="absolute inset-0 w-full h-full object-cover transition-transform duration-700 md:group-hover:scale-110" 
              />
            ) : renderPosterFallback(currentItem.title)}
            
            <div className="absolute top-3 left-3 md:top-4 md:left-4 bg-primary text-surface font-label-sm text-[10px] md:text-[12px] px-3 md:px-4 py-1 md:py-1.5 rounded-full shadow-lg z-10 font-bold tracking-wider">
              TRENDING
            </div>

            <div className="absolute inset-0 border-2 border-transparent md:group-hover:border-primary/50 rounded-2xl transition-all duration-500 z-20 pointer-events-none mix-blend-overlay"></div>
            
            <div className="absolute inset-0 bg-gradient-to-t from-background via-background/40 to-transparent opacity-90 md:group-hover:opacity-100 transition-opacity duration-300"></div>
            
            <div className="absolute bottom-0 left-0 right-0 p-4 md:p-6 translate-y-0 md:translate-y-4 md:group-hover:translate-y-0 transition-transform duration-300 ease-out flex flex-col justify-end h-full z-30">
              <div>
                <h3 className="font-display-xl-mobile md:font-display-xl text-[20px] md:text-[42px] font-bold text-on-background mb-1 md:mb-2 leading-tight line-clamp-2 md:line-clamp-4 break-words">
                  {currentItem.title}
                </h3>
                <div className="flex flex-wrap items-center gap-x-2 md:gap-x-3 gap-y-2 text-primary font-body-md text-[13px] md:text-[16px] mb-2 md:mb-6">
                  <span className="flex items-center">
                    <Star className="w-4 h-4 md:w-5 md:h-5 mr-1 fill-current" /> 
                    {currentItem.rating?.toFixed(1) || 'N/A'}
                  </span>
                  <span className="hidden md:inline text-on-surface-variant">•</span>
                  <span className="text-on-surface-variant flex items-center gap-1">
                    <Calendar className="w-3.5 h-3.5 md:w-4 md:h-4 text-primary/80" />
                    {currentItem.releaseDate 
                      ? new Date(currentItem.releaseDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
                      : 'TBA'}
                  </span>
                  {currentItem.genres?.[0] && (
                    <>
                      <span className="hidden md:inline text-on-surface-variant">•</span>
                      <span className="text-on-surface-variant border border-white/20 rounded md:border-none px-1.5 md:px-0 py-0.5 md:py-0 text-[11px] md:text-sm whitespace-nowrap">
                        {currentItem.genres[0].name}
                      </span>
                    </>
                  )}
                </div>
                <div className="hidden md:flex space-x-3 opacity-0 md:group-hover:opacity-100 transition-opacity duration-300 delay-100">
                  <button className="flex-1 bg-primary text-surface py-3 rounded-lg font-label-sm text-[12px] hover:bg-primary-container transition-colors flex items-center justify-center space-x-2 font-bold shadow-[0_10px_20px_rgba(245,158,11,0.3)]">
                    <Play className="w-4 h-4 fill-current" />
                    <span>View Details</span>
                  </button>
                </div>
              </div>
            </div>
          </Link>
        )}

        {/* Next Poster */}
        {items.length > 1 && (
          <div 
            onClick={nextSlide}
            className="relative w-[200px] md:w-[280px] aspect-[2/3] rounded-xl overflow-hidden opacity-40 scale-75 blur-[2px] transition-all duration-500 z-0 cursor-pointer"
          >
            {nextItem?.posterUrl ? (
              <img 
                src={nextItem.posterUrl} 
                alt={nextItem?.title || 'Next'} 
                className="absolute inset-0 w-full h-full object-cover" 
              />
            ) : renderPosterFallback(nextItem?.title || 'Unknown')}
          </div>
        )}
      </div>

      {/* Right Arrow */}
      {items.length > 1 && (
        <button 
          onClick={nextSlide}
          className="absolute right-4 md:right-margin-desktop z-20 bg-surface-container/30 hover:bg-surface-container/50 backdrop-blur-md border border-white/10 text-white p-3 rounded-full shadow-[0_10px_30px_rgba(0,0,0,0.5)] transition-all active:scale-90 hidden md:block"
          aria-label="Next slide"
        >
          <ChevronRight className="w-8 h-8" />
        </button>
      )}

      {/* Pagination Dots */}
      {items.length > 1 && (
        <div className="flex justify-center items-center space-x-2 mt-8">
          {items.map((_, idx) => (
            <div 
              key={idx}
              onClick={() => setCurrentIndex(idx)}
              className={`h-1.5 rounded-full cursor-pointer transition-all ${
                idx === currentIndex 
                  ? 'w-8 bg-primary shadow-[0_0_10px_rgba(245,158,11,0.5)]' 
                  : 'w-1.5 bg-white/20 hover:bg-white/40'
              }`}
            />
          ))}
        </div>
      )}
    </div>
  );
}

