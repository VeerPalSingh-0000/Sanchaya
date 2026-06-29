'use client';

import { useState, useEffect } from 'react';
import { AlertCircle, Sparkles, Map, PlayCircle, ChevronDown, ChevronRight } from 'lucide-react';
import type { Episode } from '@/types/media';

interface EpisodeDropdownProps {
  episodes: Episode[];
  isAnime: boolean;
}

export default function EpisodeDropdown({ episodes, isAnime }: EpisodeDropdownProps) {
  const [openArcIndex, setOpenArcIndex] = useState<number | null>(null);
  const [itemsPerRow, setItemsPerRow] = useState(1);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const handleResize = () => {
      if (window.innerWidth >= 1024) setItemsPerRow(3);
      else setItemsPerRow(2);
    };
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  if (!episodes || episodes.length === 0) {
    return null;
  }

  // Group episodes by sagaName (if available) or arcName
  const groupedEpisodes: { groupName: string; episodes: Episode[] }[] = [];
  let currentGroupName = '';
  let currentGroup: Episode[] = [];

  episodes.forEach(ep => {
    const groupName = ep.sagaName || ep.arcName || (isAnime ? 'Unknown Arc' : 'Episodes');
    if (groupName !== currentGroupName) {
      if (currentGroup.length > 0) {
        groupedEpisodes.push({ groupName: currentGroupName, episodes: currentGroup });
      }
      currentGroupName = groupName;
      currentGroup = [ep];
    } else {
      currentGroup.push(ep);
    }
  });
  if (currentGroup.length > 0) {
    groupedEpisodes.push({ groupName: currentGroupName, episodes: currentGroup });
  }

  const toggleArc = (idx: number) => {
    setOpenArcIndex(openArcIndex === idx ? null : idx);
  };

  if (!mounted) {
    return <div className="w-full mt-12 mb-8 min-h-[400px] animate-pulse bg-white/5 rounded-3xl" />;
  }

  const isSingleGroup = groupedEpisodes.length === 1;

  if (isSingleGroup) {
    const group = groupedEpisodes[0];
    const isOpen = openArcIndex === 0;

    return (
      <div className="w-full mt-12 mb-8 px-2 md:px-4 max-w-5xl mx-auto">
        <button 
          onClick={() => toggleArc(0)}
          className="group w-full flex items-center justify-between p-4 bg-surface-container hover:bg-surface-container-high border border-white/5 rounded-2xl transition-all duration-300 shadow-md"
        >
          <div className="flex items-center gap-3">
            <PlayCircle className="w-6 h-6 text-primary" />
            <h2 className="font-headline-md text-xl md:text-2xl font-black text-on-surface tracking-tight uppercase">Episodes</h2>
            <span className="bg-white/5 border border-white/10 px-2.5 py-0.5 rounded-full text-xs font-bold text-on-surface-variant ml-2">
              {group.episodes.length} EP
            </span>
          </div>
          <div className="text-white/40 group-hover:text-white/80 transition-colors">
            {isOpen ? <ChevronDown className="w-6 h-6" /> : <ChevronRight className="w-6 h-6" />}
          </div>
        </button>

        <div className={`w-full transition-all duration-300 overflow-hidden ${isOpen ? 'max-h-[800px] opacity-100 mt-4' : 'max-h-0 opacity-0 mt-0'}`}>
          <div className="w-full bg-surface-container/50 border border-white/5 rounded-3xl overflow-hidden p-2 md:p-4 shadow-inner">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2 max-h-[600px] overflow-y-auto episode-scroll pr-2">
              <style>{`
                .episode-scroll::-webkit-scrollbar { width: 4px; }
                .episode-scroll::-webkit-scrollbar-track { background: transparent; }
                .episode-scroll::-webkit-scrollbar-thumb { background: rgba(var(--color-primary-rgb), 0.3); border-radius: 4px; }
              `}</style>
              {group.episodes.map((ep, idx) => (
                <div key={ep.number || idx} className="flex items-center gap-3 py-3 px-4 rounded-2xl bg-surface hover:bg-white/5 border border-white/5 transition-colors group/ep cursor-default">
                  <span className="text-[12px] font-bold text-on-surface-variant/50 w-7 shrink-0 tracking-wider">
                    {String(ep.number).padStart(2, '0')}
                  </span>
                  
                  <div className="flex flex-col flex-1 min-w-0 justify-center">
                    <span className="text-[14px] font-medium text-on-surface/90 group-hover/ep:text-primary transition-colors truncate">
                      {ep.name || `Episode ${ep.number}`}
                    </span>
                  </div>
                  
                  <div className="flex items-center gap-1.5 shrink-0 ml-1">
                    {ep.isFiller && (
                      <span className="flex items-center gap-1 text-[9px] font-bold uppercase tracking-widest text-red-400 border border-red-500/20 px-1.5 py-0.5 rounded-sm bg-red-500/10">
                        Filler
                      </span>
                    )}
                    {ep.isRecap && (
                      <span className="flex items-center gap-1 text-[9px] font-bold uppercase tracking-widest text-orange-400 border border-orange-500/20 px-1.5 py-0.5 rounded-sm bg-orange-500/10">
                        Recap
                      </span>
                    )}
                    {!ep.isFiller && !ep.isRecap && isAnime && (
                      <span className="flex items-center gap-1 text-[9px] font-bold uppercase tracking-widest text-blue-400/80 border border-blue-500/20 px-1.5 py-0.5 rounded-sm bg-blue-500/10">
                        Canon
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  const chunks = [];
  for (let i = 0; i < groupedEpisodes.length; i += itemsPerRow) {
    chunks.push(groupedEpisodes.slice(i, i + itemsPerRow));
  }

  return (
    <div className="w-full mt-12 mb-8 px-2 md:px-4">
      <div className="flex items-center gap-3 mb-10 pl-4">
        <Map className="w-7 h-7 text-primary" />
        <h2 className="font-headline-md text-3xl font-black text-on-surface tracking-tight uppercase">Story Arcs</h2>
      </div>

      <div className="flex flex-col w-full relative">
        {chunks.map((chunk, rowIndex) => {
          const isEven = rowIndex % 2 === 0;
          return (
            <div key={rowIndex} className={`flex w-full ${isEven ? 'flex-row' : 'flex-row-reverse'}`}>
              {chunk.map((group, idxInChunk) => {
                const globalIdx = rowIndex * itemsPerRow + idxInChunk;
                const isOpen = openArcIndex === globalIdx;
                const isVeryFirst = globalIdx === 0;
                const isVeryLast = globalIdx === groupedEpisodes.length - 1;
                
                const isLeftEdge = (isEven && idxInChunk === 0) || (!isEven && idxInChunk === chunk.length - 1);
                const isRightEdge = (isEven && idxInChunk === chunk.length - 1) || (!isEven && idxInChunk === 0);
                
                let hasLeftLine = !isLeftEdge;
                let hasRightLine = !isRightEdge;

                if (isVeryFirst) hasLeftLine = false;
                if (isVeryLast) {
                  if (isEven) hasRightLine = false;
                  else hasLeftLine = false;
                }

                const isLastInChunk = idxInChunk === chunk.length - 1;
                const isFirstInChunk = idxInChunk === 0;
                const isLastChunk = rowIndex === chunks.length - 1;
                const isFirstChunk = rowIndex === 0;

                const needsDownLine = isLastInChunk && !isLastChunk;
                const needsUpLine = isFirstInChunk && !isFirstChunk;

                return (
                  <div key={globalIdx} style={{ width: `${100 / itemsPerRow}%`, flexShrink: 0 }} className={`flex flex-col relative px-2 sm:px-4 h-[180px] ${isOpen ? 'z-50' : 'z-10'}`}>
                    {/* Horizontal Lines */}
                    {hasLeftLine && <div className="absolute top-[40px] left-0 right-[50%] h-[4px] bg-primary/40 -translate-y-1/2 z-0 rounded-l-full" />}
                    {hasRightLine && <div className="absolute top-[40px] left-[50%] right-0 h-[4px] bg-primary/40 -translate-y-1/2 z-0 rounded-r-full" />}
                    
                    {/* Vertical Lines */}
                    {needsDownLine && <div className="absolute top-[40px] bottom-0 left-[50%] w-[4px] bg-primary/40 -translate-x-1/2 z-0 rounded-b-full" />}
                    {needsUpLine && <div className="absolute top-0 h-[40px] left-[50%] w-[4px] bg-primary/40 -translate-x-1/2 z-0 rounded-t-full" />}
                    
                    {/* Node / Point */}
                    <div className="flex flex-col items-center pt-[24px] relative z-10 w-full">
                      <button 
                        onClick={() => toggleArc(globalIdx)} 
                        className={`relative z-20 w-8 h-8 rounded-full border-[4px] transition-all duration-300 flex items-center justify-center ${
                          isOpen ? 'border-primary bg-surface shadow-[0_0_20px_rgba(var(--color-primary),0.8)] scale-125' : 'border-primary/50 bg-surface-container hover:border-primary hover:scale-110'
                        }`}
                      >
                        {isOpen && <div className="w-2.5 h-2.5 bg-primary rounded-full animate-pulse" />}
                      </button>
                      
                      <button 
                        onClick={() => toggleArc(globalIdx)}
                        className="mt-4 flex flex-col items-center text-center group cursor-pointer w-full px-2"
                      >
                        <span className="text-[10px] font-black uppercase text-primary/70 tracking-widest group-hover:text-primary transition-colors">
                          Arc {String(globalIdx + 1).padStart(2, '0')}
                        </span>
                        <h3 className={`font-headline-sm text-base md:text-lg font-bold mt-1 transition-colors line-clamp-2 ${isOpen ? 'text-primary' : 'text-on-surface group-hover:text-on-surface'}`}>
                          {group.groupName}
                        </h3>
                        <span className="text-[11px] font-bold text-on-surface-variant mt-2 bg-white/5 border border-white/10 px-2 py-0.5 rounded-full">
                          {group.episodes.length} EP
                        </span>
                      </button>

                      {/* Absolute Dropdown for Episodes (Floats above the map to avoid stretching lines) */}
                      <div className={`absolute left-1/2 -translate-x-1/2 top-[120px] w-[280px] sm:w-[320px] transition-all duration-300 origin-top z-[100] ${isOpen ? 'scale-y-100 opacity-100 pointer-events-auto' : 'scale-y-0 opacity-0 pointer-events-none'}`}>
                        <div className="bg-[#121212] border border-white/10 rounded-2xl overflow-hidden shadow-[0_15px_50px_rgba(0,0,0,0.9)] flex flex-col relative before:absolute before:inset-0 before:bg-gradient-to-b before:from-white/5 before:to-transparent before:pointer-events-none">
                          <div className="p-2 overflow-y-auto max-h-[350px] episode-scroll flex flex-col gap-0.5 relative z-10 bg-[#121212]">
                            <style>{`
                              .episode-scroll::-webkit-scrollbar { width: 4px; }
                              .episode-scroll::-webkit-scrollbar-track { background: transparent; }
                              .episode-scroll::-webkit-scrollbar-thumb { background: rgba(var(--color-primary-rgb), 0.3); border-radius: 4px; }
                            `}</style>
                            {group.episodes.map((ep, idx) => {
                              const showArcHeader = ep.sagaName && ep.arcName && (idx === 0 || group.episodes[idx - 1].arcName !== ep.arcName);
                              
                              return (
                                <div key={ep.number || idx} className="flex flex-col gap-1 w-full">
                                  {showArcHeader && (
                                    <div className="text-[10px] font-black text-primary/70 uppercase tracking-widest mt-2 mb-1 px-2 border-b border-primary/20 pb-1">
                                      {ep.arcName}
                                    </div>
                                  )}
                                  <div className="flex items-center gap-3 py-2 px-3 rounded-xl bg-surface hover:bg-white/5 transition-colors group/ep cursor-default">
                                    <span className="text-[11px] font-bold text-on-surface-variant/50 w-6 shrink-0 tracking-wider">
                                      {String(ep.number).padStart(2, '0')}
                                    </span>
                                    
                                    <div className="flex flex-col flex-1 min-w-0 justify-center">
                                      <span className="text-[13px] font-medium text-on-surface/90 group-hover/ep:text-primary transition-colors truncate">
                                        {ep.name || `Episode ${ep.number}`}
                                      </span>
                                    </div>
                                    
                                    <div className="flex items-center gap-1.5 shrink-0 ml-1">
                                      {ep.isFiller && (
                                        <span className="flex items-center gap-1 text-[8px] font-bold uppercase tracking-widest text-red-400 border border-red-500/20 px-1 rounded-sm bg-red-500/10">
                                          Filler
                                        </span>
                                      )}
                                      {ep.isRecap && (
                                        <span className="flex items-center gap-1 text-[8px] font-bold uppercase tracking-widest text-orange-400 border border-orange-500/20 px-1 rounded-sm bg-orange-500/10">
                                          Recap
                                        </span>
                                      )}
                                      {!ep.isFiller && !ep.isRecap && isAnime && (
                                        <span className="flex items-center gap-1 text-[8px] font-bold uppercase tracking-widest text-blue-400/80 border border-blue-500/20 px-1 rounded-sm bg-blue-500/10">
                                          Canon
                                        </span>
                                      )}
                                    </div>
                                  </div>
                                </div>
                              );
                            })}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          );
        })}
      </div>
    </div>
  );
}
