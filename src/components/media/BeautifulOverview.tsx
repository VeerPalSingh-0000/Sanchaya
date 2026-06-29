'use client';

import { useState } from 'react';
import { Sparkles, ChevronDown, ChevronUp } from 'lucide-react';

export default function BeautifulOverview({ text }: { text: string }) {
  const [isExpanded, setIsExpanded] = useState(false);

  if (!text) return <p className="text-on-surface-variant italic mt-8 font-medium">No lore found for this one... 🫥</p>;

  // Clean the text of typical ugly API cruft
  let cleanedText = text
    .replace(/\*This includes the following special episodes[\s\S]*/, '') // One Piece specific & others
    .replace(/\(Source:[\s\S]*?\)/g, '') // MyAnimeList source
    .replace(/\[Written by MAL Rewrite\]/g, '') // MAL rewrite tag
    .replace(/\[[\s\S]*?\].*?/g, '') // Other bracketed sources sometimes found
    .trim();
  
  // Try to split into readable paragraphs instead of a wall of text
  let rawParagraphs = cleanedText.split(/\n+/).map(p => p.trim()).filter(Boolean);
  
  let paragraphs: string[] = [];
  if (rawParagraphs.length === 1 && rawParagraphs[0].length > 300) {
    // It's a massive wall of text. Split by sentences intelligently to create smaller chunks.
    const sentences = rawParagraphs[0].match(/[^.!?]+[.!?]+/g) || [rawParagraphs[0]];
    let current = "";
    sentences.forEach(s => {
      current += s + " ";
      if (current.length > 250) {
        paragraphs.push(current.trim());
        current = "";
      }
    });
    if (current.trim()) paragraphs.push(current.trim());
  } else {
    paragraphs = rawParagraphs;
  }

  // Ensure we have at least something to show
  if (paragraphs.length === 0) {
    paragraphs = [cleanedText];
  }

  const isLong = paragraphs.length > 1 || paragraphs[0].length > 400;
  
  // If it's just one extremely long paragraph that couldn't be split (e.g. no punctuation), we handle it by truncating
  const displayParagraphs = isExpanded ? paragraphs : paragraphs.slice(0, 1);

  return (
    <div className="mt-10 mb-8 relative group/lore">
      <div className="flex items-center gap-2 mb-6">
        <Sparkles className="w-6 h-6 text-primary" />
        <h3 className="font-headline-sm text-2xl md:text-3xl font-black text-transparent bg-clip-text bg-gradient-to-r from-white to-white/60 tracking-tight uppercase">
          The Lore
        </h3>
      </div>
      
      <div className="relative pl-1">
        <div className="absolute left-[-12px] top-2 bottom-0 w-[3px] bg-gradient-to-b from-primary/80 via-primary/20 to-transparent rounded-full" />
        
        <div className={`flex flex-col gap-6 transition-all duration-500 relative z-10 ${!isExpanded && isLong ? 'mask-bottom pb-4' : ''}`}>
          <style>{`
            .mask-bottom {
              -webkit-mask-image: linear-gradient(to bottom, black 60%, transparent 100%);
              mask-image: linear-gradient(to bottom, black 60%, transparent 100%);
            }
          `}</style>
          
          {displayParagraphs.map((p, i) => {
            if (i === 0) {
              return (
                <p key={i} className={`text-base md:text-[17px] text-white/90 leading-[1.8] font-medium tracking-wide ${!isExpanded && isLong && paragraphs.length === 1 ? 'line-clamp-4' : ''}`}>
                  {/* Drop cap for GenZ aesthetic reading */}
                  <span className="float-left text-5xl md:text-[64px] font-black text-primary leading-none mr-3 mt-1 drop-shadow-[0_0_15px_rgba(var(--color-primary-rgb),0.5)]">
                    {p.charAt(0)}
                  </span>
                  {p.slice(1)}
                </p>
              );
            }
            return (
              <p key={i} className="text-[15px] md:text-[16px] text-white/70 leading-[1.8] tracking-wide font-medium">
                {p}
              </p>
            );
          })}
        </div>
      </div>

      {isLong && (
        <button 
          onClick={() => setIsExpanded(!isExpanded)}
          className="mt-4 flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.2em] text-primary hover:text-white transition-all bg-primary/10 hover:bg-primary/40 px-5 py-3 rounded-xl border border-primary/20 backdrop-blur-md shadow-lg shadow-primary/5 active:scale-95"
        >
          {isExpanded ? (
            <>Collapse <ChevronUp className="w-4 h-4" /></>
          ) : (
            <>Spill the tea <ChevronDown className="w-4 h-4" /></>
          )}
        </button>
      )}
    </div>
  );
}
