import React, { useRef } from 'react';
import type { Media } from '@/types/media';
import MediaCard from './MediaCard';

interface MediaRowProps {
  title: string;
  subtitle?: string;
  items: Media[];
  icon?: React.ReactNode;
}

export default function MediaRow({ title, subtitle, items, icon }: MediaRowProps) {
  const scrollRef = useRef<HTMLDivElement>(null);

  if (!items || items.length === 0) {
    return null;
  }

  return (
    <div className="flex flex-col gap-6 slide-up">
      <div className="flex items-end justify-between max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop w-full">
        <div className="flex items-center gap-3">
          {icon && <span className="text-primary">{icon}</span>}
          <h2 className="font-headline-lg-mobile md:font-headline-lg text-[24px] md:text-[32px] font-bold text-on-surface">
            {title}
          </h2>
        </div>
        {subtitle && <span className="font-label-sm text-[12px] text-on-surface-variant font-bold uppercase tracking-wider hidden sm:block">{subtitle}</span>}
      </div>
      
      <div 
        ref={scrollRef}
        className="flex overflow-x-auto gap-4 md:gap-gutter no-scrollbar px-margin-mobile md:px-margin-desktop pb-6 snap-x snap-mandatory"
      >
        {items.map((media, i) => (
          <div key={media.id} className="min-w-[160px] md:min-w-[200px] flex-shrink-0 snap-start">
            <MediaCard media={media} index={i} />
          </div>
        ))}
        {/* Spacer for right edge */}
        <div className="min-w-[16px] md:min-w-[48px] flex-shrink-0" aria-hidden="true" />
      </div>
    </div>
  );
}
