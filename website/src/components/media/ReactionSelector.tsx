'use client';

import { useState, useRef, useEffect } from 'react';
import { useWatchlist } from '@/lib/contexts/WatchlistContext';
import { Heart, ThumbsUp, ThumbsDown, ChevronDown, Sparkles, Star } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface ReactionSelectorProps {
  mediaId: string;
}

const REACTIONS = [
  { id: 'FAVORITE', label: 'Favourite', icon: Star, color: 'text-amber-400', bg: 'bg-amber-400/15', border: 'border-amber-400/30', glow: 'rgba(251,191,36,0.35)' },
  { id: 'LOVE', label: 'Love it', icon: Heart, color: 'text-rose-500', bg: 'bg-rose-500/15', border: 'border-rose-500/30', glow: 'rgba(244,63,94,0.35)' },
  { id: 'GOOD', label: "It's good", icon: ThumbsUp, color: 'text-emerald-400', bg: 'bg-emerald-400/15', border: 'border-emerald-400/30', glow: 'rgba(52,211,153,0.35)' },
  { id: 'BAD', label: "It's bad", icon: ThumbsDown, color: 'text-slate-400', bg: 'bg-slate-500/15', border: 'border-slate-500/30', glow: 'rgba(148,163,184,0.35)' },
] as const;

export default function ReactionSelector({ mediaId }: ReactionSelectorProps) {
  const { watchlist, updateReaction } = useWatchlist();
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  
  // Find item by ID or externalId
  const item = watchlist.find((i) => i.id === String(mediaId) || i.externalId === String(mediaId));
  
  // Close dropdown on outside click
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Only show the rating widget if the item is in the user's watchlist
  if (!item) return null;

  const currentReaction = item.reaction;
  const activeReaction = REACTIONS.find((r) => r.id === currentReaction);

  const handleReaction = (reactionId: 'FAVORITE' | 'LOVE' | 'GOOD' | 'BAD') => {
    const newReaction = currentReaction === reactionId ? null : reactionId;
    
    // Update all items in the same franchise, or just this item if no franchise
    const itemsToUpdate = item.franchiseId 
      ? watchlist.filter((i) => i.franchiseId === item.franchiseId)
      : [item];
      
    itemsToUpdate.forEach((i) => {
      updateReaction(i.id, newReaction);
    });
    setIsOpen(false);
  };

  return (
    <div className="relative inline-flex z-40" ref={dropdownRef}>
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        aria-expanded={isOpen}
        aria-label="Rate or react to media"
        className={`h-11 px-4 rounded-full font-semibold text-sm inline-flex items-center justify-center gap-2 whitespace-nowrap cursor-pointer select-none transition-all duration-200 active:scale-95 border backdrop-blur-md ${
          activeReaction
            ? `${activeReaction.bg} ${activeReaction.color} ${activeReaction.border} shadow-[0_0_16px_var(--glow-color)]`
            : 'bg-slate-900/65 text-slate-300 hover:text-white border-white/10 hover:border-white/20 hover:bg-slate-800/80 shadow-sm'
        }`}
        style={activeReaction ? ({ '--glow-color': activeReaction.glow } as React.CSSProperties) : undefined}
      >
        {activeReaction ? (
          <>
            <activeReaction.icon className="w-4 h-4 fill-current shrink-0" />
            <span className="leading-none">{activeReaction.label}</span>
          </>
        ) : (
          <>
            <Sparkles className="w-4 h-4 shrink-0 opacity-80" />
            <span className="leading-none">Rate</span>
          </>
        )}
        <ChevronDown className={`w-3.5 h-3.5 opacity-70 transition-transform duration-200 shrink-0 ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: -6, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -6, scale: 0.96 }}
            transition={{ duration: 0.18, ease: [0.16, 1, 0.3, 1] }}
            className="absolute top-[calc(100%+8px)] left-0 p-1.5 min-w-[170px] max-w-[calc(100vw-32px)] bg-slate-900/95 backdrop-blur-2xl border border-white/12 rounded-2xl shadow-2xl flex flex-col gap-1 z-50 origin-top-left"
          >
            {REACTIONS.map((reaction) => {
              const isActive = currentReaction === reaction.id;
              const Icon = reaction.icon;
              return (
                <button
                  key={reaction.id}
                  type="button"
                  onClick={() => handleReaction(reaction.id)}
                  className={`flex items-center gap-3 px-3 py-2 rounded-xl transition-all duration-150 text-sm font-medium w-full text-left cursor-pointer ${
                    isActive
                      ? `${reaction.bg} ${reaction.color} font-semibold`
                      : 'text-slate-300 hover:bg-white/10 hover:text-white'
                  }`}
                >
                  <Icon className={`w-4 h-4 shrink-0 ${isActive ? 'fill-current' : ''}`} />
                  <span>{reaction.label}</span>
                  {isActive && (
                    <span className="ml-auto w-1.5 h-1.5 rounded-full bg-current shrink-0" />
                  )}
                </button>
              );
            })}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
