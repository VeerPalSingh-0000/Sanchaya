'use client';

import { useState, useEffect } from 'react';
import { useWatchlist } from '@/lib/contexts/WatchlistContext';
import { StickyNote, Save } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface NotesWidgetProps {
  mediaId: string;
}

export default function NotesWidget({ mediaId }: NotesWidgetProps) {
  const { watchlist, updateNotes } = useWatchlist();
  const [isOpen, setIsOpen] = useState(false);
  const [notes, setNotes] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  
  // Find item by ID or externalId
  const item = watchlist.find((i) => i.id === String(mediaId) || i.externalId === String(mediaId));

  useEffect(() => {
    if (item && item.notes) {
      setNotes(item.notes);
    }
  }, [item]);

  // Only show the notes widget if the item is in the user's watchlist
  if (!item) return null;

  const handleSave = () => {
    setIsSaving(true);
    
    // Update all items in the same franchise, or just this item if no franchise
    const itemsToUpdate = item.franchiseId 
      ? watchlist.filter(i => i.franchiseId === item.franchiseId)
      : [item];
      
    itemsToUpdate.forEach(i => {
      updateNotes(i.id, notes.trim() === '' ? null : notes.trim());
    });
    
    setTimeout(() => {
      setIsSaving(false);
      setIsOpen(false);
    }, 400); // Fake delay for UX
  };

  return (
    <div className="mt-4">
      {!isOpen ? (
        <button
          onClick={() => setIsOpen(true)}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl transition-all duration-300 font-label-md font-bold tracking-wide border backdrop-blur-md ${
            item.notes
              ? 'bg-primary/20 text-primary border-primary/30 shadow-[0_0_15px_rgba(245,158,11,0.2)]'
              : 'bg-surface-container/50 text-on-surface-variant border-white/10 hover:bg-white/10 hover:text-white shadow-sm'
          }`}
        >
          <StickyNote className="w-4 h-4" />
          <span>{item.notes ? 'Edit Notes' : 'Add Note'}</span>
        </button>
      ) : (
        <motion.div
          initial={{ opacity: 0, y: -10, height: 0 }}
          animate={{ opacity: 1, y: 0, height: 'auto' }}
          className="bg-surface-container/60 backdrop-blur-xl border border-white/10 rounded-2xl p-4 flex flex-col gap-3 shadow-lg"
        >
          <div className="flex items-center justify-between mb-1">
            <h3 className="text-on-surface font-bold text-sm flex items-center gap-2">
              <StickyNote className="w-4 h-4 text-primary" />
              Personal Notes
            </h3>
            <button 
              onClick={() => setIsOpen(false)}
              className="text-on-surface-variant hover:text-white text-xs font-bold"
            >
              Cancel
            </button>
          </div>
          
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Write your thoughts, opinions, or a reminder..."
            className="w-full bg-black/40 border border-white/5 rounded-xl p-3 text-sm text-on-surface placeholder:text-on-surface-variant/50 focus:outline-none focus:ring-1 focus:ring-primary/50 resize-none h-24"
          />
          
          <div className="flex justify-end">
            <button
              onClick={handleSave}
              disabled={isSaving}
              className="flex items-center gap-2 px-4 py-2 bg-primary text-background font-bold text-sm rounded-lg hover:bg-primary-container transition-colors disabled:opacity-70 disabled:cursor-not-allowed"
            >
              <Save className="w-4 h-4" />
              <span>{isSaving ? 'Saving...' : 'Save Notes'}</span>
            </button>
          </div>
        </motion.div>
      )}
    </div>
  );
}
