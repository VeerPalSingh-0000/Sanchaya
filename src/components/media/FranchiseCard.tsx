'use client';

import Image from 'next/image';
import { useState } from 'react';
import type { WatchlistItem } from '@/types/media';
import { useWatchlist } from '@/lib/contexts/WatchlistContext';
import Link from 'next/link';
import { motion } from 'framer-motion';

interface FranchiseCardProps {
  rootTitle: string;
  rootPosterUrl: string;
  items: WatchlistItem[];
  index?: number;
}

export default function FranchiseCard({ rootTitle, rootPosterUrl, items, index = 0 }: FranchiseCardProps) {
  const [isOpen, setIsOpen] = useState(false);
  const { updateStatus, removeFromWatchlist } = useWatchlist();

  const posterSrc = rootPosterUrl || items[0].posterUrl;
  const title = rootTitle !== 'Unknown' ? rootTitle : items[0].title;

  return (
    <>
      <motion.article
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: index * 0.05, duration: 0.5, type: 'spring', stiffness: 100 }}
        className="relative overflow-hidden rounded-xl aspect-[2/3] group cursor-pointer glass-panel"
        onClick={() => setIsOpen(true)}
      >
        <div className="block w-full h-full">
          {posterSrc ? (
            <img
              src={posterSrc}
              alt={title}
              className="absolute inset-0 w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
            />
          ) : (
            <div className="absolute inset-0 bg-surface-container flex flex-col items-center justify-center p-4">
              <span className="material-symbols-outlined text-4xl text-on-surface-variant opacity-30 mb-2">image</span>
              <span className="text-on-surface-variant text-center text-sm font-bold opacity-50 truncate w-full">{title}</span>
            </div>
          )}

          {/* Floating Badges - Ultra Clean, matches MediaCard */}
          <div className="absolute top-2 left-2 flex flex-col gap-1 z-10">
            <span className="bg-primary-container text-on-primary-container font-label-sm text-[10px] px-2 py-0.5 rounded shadow-lg uppercase font-bold tracking-wider">
              Series
            </span>
            {items[0]?.rating != null && items[0].rating > 0 && (
              <span className="bg-surface/80 backdrop-blur-md text-primary font-label-sm text-[10px] px-2 py-0.5 rounded shadow-lg flex items-center font-bold">
                <span className="material-symbols-outlined text-[12px] mr-0.5" style={{ fontVariationSettings: "'FILL' 1" }}>star</span>
                {items[0].rating.toFixed(1)}
              </span>
            )}
          </div>

          {/* Circular Badge Top Right - Exact match to MediaCard */}
          <button className="absolute top-2 right-2 z-30 w-8 h-8 rounded-full flex items-center justify-center shadow-lg bg-primary text-surface transition-colors pointer-events-none">
            <span className="material-symbols-outlined text-[18px]" style={{ fontVariationSettings: "'FILL' 1" }}>
              check
            </span>
          </button>

          {/* Hover Overlay - Exact match to MediaCard */}
          <div className="absolute inset-0 bg-black/80 backdrop-blur-md opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex flex-col justify-center items-center p-4 text-center border-t border-white/10 mt-auto h-full z-20">
            <span className="material-symbols-outlined text-[64px] text-primary mb-4 transition-transform duration-300 group-hover:scale-110" style={{ fontVariationSettings: "'FILL' 1" }}>play_circle</span>
            <h3 className="font-headline-lg-mobile text-[18px] font-bold text-on-surface mb-1 line-clamp-2">{title}</h3>
            
            <p className="font-label-sm text-[12px] text-on-surface-variant mt-1">
              {(items[0]?.genres ?? []).slice(0, 2).map(g => g.name).join(', ')}
            </p>
          </div>
        </div>
      </motion.article>

      {/* The Modal */}
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/80 backdrop-blur-sm fade-in">
          <div className="bg-surface-container border border-white/10 w-full max-w-2xl rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[85vh]">
            <div className="relative h-48 w-full overflow-hidden shrink-0">
               <Image
                  src={posterSrc || '/placeholder-poster.png'}
                  alt={title}
                  fill
                  className="object-cover blur-sm opacity-50"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-surface-container to-transparent"></div>
                <div className="absolute bottom-4 left-6 right-6 flex justify-between items-end">
                   <div>
                     <span className="text-primary font-label-sm font-bold uppercase tracking-wider mb-1 block">Franchise Collection</span>
                     <h2 className="font-headline-lg text-2xl font-bold text-on-surface">{title}</h2>
                   </div>
                   <button onClick={() => setIsOpen(false)} className="w-10 h-10 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white backdrop-blur-md transition-colors">
                     <span className="material-symbols-outlined">close</span>
                   </button>
                </div>
            </div>

            <div className="p-6 overflow-y-auto flex flex-col gap-4">
              {items.sort((a,b) => new Date(a.addedAt).getTime() - new Date(b.addedAt).getTime()).map(item => (
                <div key={item.id} className="flex gap-4 p-4 rounded-xl bg-surface/50 border border-white/5 hover:border-white/10 transition-colors">
                  <div className="relative w-16 h-24 shrink-0 rounded-md overflow-hidden">
                    <Image src={item.posterUrl || '/placeholder-poster.png'} alt={item.title} fill className="object-cover" />
                  </div>
                  <div className="flex flex-col justify-center flex-1">
                    <Link href={`/media/${item.mediaType}/${item.externalId}`} className="hover:text-primary transition-colors">
                      <h4 className="font-bold text-[15px] text-on-surface line-clamp-1">{item.title}</h4>
                    </Link>
                    <div className="flex items-center gap-2 mt-1 mb-3">
                       <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider ${
                          item.status === 'completed' ? 'bg-green-500/20 text-green-400 border border-green-500/30' :
                          item.status === 'watching' ? 'bg-blue-500/20 text-blue-400 border border-blue-500/30' :
                          item.status === 'plan_to_watch' ? 'bg-orange-500/20 text-orange-400 border border-orange-500/30' :
                          'bg-red-500/20 text-red-400 border border-red-500/30'
                       }`}>
                         {item.status.replace(/_/g, ' ')}
                       </span>
                    </div>
                    <div className="flex gap-2">
                       <select 
                         value={item.status} 
                         onChange={(e) => updateStatus(item.id, e.target.value as any)}
                         className="bg-background/50 border border-white/10 text-on-surface text-[12px] rounded px-2 py-1 outline-none focus:border-primary"
                       >
                         <option value="plan_to_watch">Plan to Watch</option>
                         <option value="watching">Watching</option>
                         <option value="completed">Completed</option>
                         <option value="on_hold">On Hold</option>
                         <option value="dropped">Dropped</option>
                       </select>
                       <button onClick={() => removeFromWatchlist(item.id)} className="text-red-400 hover:bg-red-500/10 px-2 py-1 rounded text-[12px] font-medium transition-colors">
                         Remove
                       </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
