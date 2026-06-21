'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Media } from '@/types/media';

interface HeroCarouselProps {
  items: Media[];
}

export default function HeroCarousel({ items }: HeroCarouselProps) {
  const [currentIndex, setCurrentIndex] = useState(0);

  if (!items || items.length === 0) return null;

  const nextSlide = () => {
    setCurrentIndex((prev) => (prev + 1) % items.length);
  };

  const prevSlide = () => {
    setCurrentIndex((prev) => (prev - 1 + items.length) % items.length);
  };

  const getVisibleItems = () => {
    const prev = (currentIndex - 1 + items.length) % items.length;
    const current = currentIndex;
    const next = (currentIndex + 1) % items.length;
    return [items[prev], items[current], items[next]];
  };

  const [prevItem, currentItem, nextItem] = getVisibleItems();

  return (
    <div className="relative w-full flex flex-col items-center justify-center py-10">
      {/* Left Arrow */}
      <button 
        onClick={prevSlide}
        className="absolute left-4 md:left-margin-desktop z-20 bg-surface-container/30 hover:bg-surface-container/50 backdrop-blur-md border border-white/10 text-white p-3 rounded-full shadow-[0_10px_30px_rgba(0,0,0,0.5)] transition-all active:scale-90 hidden md:block"
      >
        <span className="material-symbols-outlined text-3xl">chevron_left</span>
      </button>

      {/* Carousel Track */}
      <div className="flex items-center justify-center space-x-[-15%] md:space-x-[-10%] w-full max-w-[1200px]">
        {/* Previous Poster */}
        <div 
          onClick={prevSlide}
          className="relative w-[200px] md:w-[280px] aspect-[2/3] rounded-xl overflow-hidden opacity-40 scale-75 blur-[2px] transition-all duration-500 z-0 cursor-pointer"
        >
          <img 
            src={prevItem.posterUrl} 
            alt={prevItem.title} 
            className="absolute inset-0 w-full h-full object-cover" 
          />
        </div>

        {/* Active Poster */}
        <Link 
          href={`/media/${currentItem.type}/${currentItem.externalId}`}
          className="relative w-[260px] md:w-[400px] aspect-[2/3] rounded-2xl overflow-hidden group cursor-pointer border border-white/20 shadow-[0_30px_60px_rgba(0,0,0,0.7)] z-10 hover:shadow-[0_0_60px_rgba(245,158,11,0.4)] transition-all duration-500 hover:scale-105"
        >
          <img 
            src={currentItem.posterUrl} 
            alt={currentItem.title} 
            className="absolute inset-0 w-full h-full object-cover transition-transform duration-700 group-hover:scale-110" 
          />
          
          <div className="absolute top-4 left-4 bg-primary text-surface font-label-sm text-[12px] px-4 py-1.5 rounded-full shadow-lg z-10 font-bold tracking-wider">
            TRENDING
          </div>

          <div className="absolute inset-0 border-2 border-transparent group-hover:border-primary/50 rounded-2xl transition-all duration-500 z-20 pointer-events-none mix-blend-overlay"></div>
          
          <div className="absolute inset-0 bg-gradient-to-t from-background via-background/40 to-transparent opacity-90 group-hover:opacity-100 transition-opacity duration-300"></div>
          
          <div className="absolute bottom-0 left-0 right-0 p-6 translate-y-4 group-hover:translate-y-0 transition-transform duration-300 ease-out flex flex-col justify-end h-full z-30">
            <div>
              <h3 className="font-display-xl-mobile md:font-display-xl text-[40px] md:text-[64px] font-bold text-on-background mb-2 leading-tight">
                {currentItem.title}
              </h3>
              <div className="flex items-center space-x-3 text-primary font-body-md text-[16px] mb-6">
                <span className="flex items-center">
                  <span className="material-symbols-outlined text-[20px] mr-1" style={{ fontVariationSettings: "'FILL' 1" }}>star</span> 
                  {currentItem.rating?.toFixed(1) || 'N/A'}
                </span>
                <span className="text-on-surface-variant">•</span>
                <span className="text-on-surface-variant">{currentItem.releaseDate?.split('-')[0] || 'TBA'}</span>
                {currentItem.genres?.[0] && (
                  <>
                    <span className="text-on-surface-variant">•</span>
                    <span className="text-on-surface-variant border border-white/20 rounded px-2 py-0.5 text-sm">
                      {currentItem.genres[0].name}
                    </span>
                  </>
                )}
              </div>
              <div className="flex space-x-3 opacity-0 group-hover:opacity-100 transition-opacity duration-300 delay-100">
                <button className="flex-1 bg-primary text-surface py-3 rounded-lg font-label-sm text-[12px] hover:bg-primary-container transition-colors flex items-center justify-center space-x-2 font-bold shadow-[0_10px_20px_rgba(245,158,11,0.3)]">
                  <span className="material-symbols-outlined" style={{ fontVariationSettings: "'FILL' 1" }}>play_arrow</span>
                  <span>View Details</span>
                </button>
              </div>
            </div>
          </div>
        </Link>

        {/* Next Poster */}
        <div 
          onClick={nextSlide}
          className="relative w-[200px] md:w-[280px] aspect-[2/3] rounded-xl overflow-hidden opacity-40 scale-75 blur-[2px] transition-all duration-500 z-0 cursor-pointer"
        >
          <img 
            src={nextItem.posterUrl} 
            alt={nextItem.title} 
            className="absolute inset-0 w-full h-full object-cover" 
          />
        </div>
      </div>

      {/* Right Arrow */}
      <button 
        onClick={nextSlide}
        className="absolute right-4 md:right-margin-desktop z-20 bg-surface-container/30 hover:bg-surface-container/50 backdrop-blur-md border border-white/10 text-white p-3 rounded-full shadow-[0_10px_30px_rgba(0,0,0,0.5)] transition-all active:scale-90 hidden md:block"
      >
        <span className="material-symbols-outlined text-3xl">chevron_right</span>
      </button>

      {/* Pagination Dots */}
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
    </div>
  );
}
