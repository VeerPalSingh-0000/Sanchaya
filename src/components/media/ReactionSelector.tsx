'use client';

import { useState, useRef, useEffect } from 'react';
import { useWatchlist } from '@/lib/contexts/WatchlistContext';
import { Heart, ThumbsUp, ThumbsDown, ChevronDown, Sparkles } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface ReactionSelectorProps {
  mediaId: string;
}

const REACTIONS = [
  { id: 'LOVE', label: 'Love it', icon: Heart, color: 'text-rose-500', bg: 'bg-rose-500/20', glow: 'rgba(244,63,94,0.4)' },
  { id: 'GOOD', label: "It's good", icon: ThumbsUp, color: 'text-emerald-500', bg: 'bg-emerald-500/20', glow: 'rgba(16,185,129,0.4)' },
  { id: 'BAD', label: "It's bad", icon: ThumbsDown, color: 'text-slate-400', bg: 'bg-slate-500/20', glow: 'rgba(100,116,139,0.4)' },
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
  const activeReaction = REACTIONS.find(r => r.id === currentReaction);

  const handleReaction = (reactionId: 'LOVE' | 'GOOD' | 'BAD') => {
    const newReaction = currentReaction === reactionId ? null : reactionId;
    
    // Update all items in the same franchise, or just this item if no franchise
    const itemsToUpdate = item.franchiseId 
      ? watchlist.filter(i => i.franchiseId === item.franchiseId)
      : [item];
      
    itemsToUpdate.forEach(i => {
      updateReaction(i.id, newReaction);
    });
    setIsOpen(false);
  };

  return (
    <div className="relative z-40" ref={dropdownRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={`flex items-center gap-2 px-4 h-11 rounded-full transition-all duration-300 font-label-md font-bold tracking-wide border backdrop-blur-md ${
          activeReaction
            ? `${activeReaction.bg} ${activeReaction.color} border-transparent shadow-[0_0_20px_var(--glow-color)]`
            : 'bg-surface-container/50 text-on-surface-variant border-white/10 hover:bg-white/10 hover:text-white shadow-lg'
        }`}
        style={activeReaction ? { '--glow-color': activeReaction.glow } as React.CSSProperties : undefined}
      >
        {activeReaction ? (
          <>
            <activeReaction.icon className="w-4 h-4 fill-current" />
            <span>{activeReaction.label}</span>
          </>
        ) : (
          <>
            <Sparkles className="w-4 h-4" />
            <span>Rate</span>
          </>
        )}
        <ChevronDown className={`w-4 h-4 transition-transform duration-300 ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: 10, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 10, scale: 0.95 }}
            transition={{ duration: 0.2, ease: 'easeOut' }}
            className="absolute top-full left-0 mt-2 p-1.5 min-w-[160px] bg-surface-container/95 backdrop-blur-xl border border-white/10 rounded-2xl shadow-2xl flex flex-col gap-1 origin-top-left"
          >
            {REACTIONS.map((reaction) => {
              const isActive = currentReaction === reaction.id;
              const Icon = reaction.icon;
              return (
                <button
                  key={reaction.id}
                  onClick={() => handleReaction(reaction.id)}
                  className={`flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-200 text-sm font-bold w-full text-left ${
                    isActive
                      ? `${reaction.bg} ${reaction.color}`
                      : 'text-on-surface hover:bg-white/10 hover:text-white'
                  }`}
                >
                  <Icon className={`w-4 h-4 ${isActive ? 'fill-current' : ''}`} />
                  {reaction.label}
                </button>
              );
            })}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
