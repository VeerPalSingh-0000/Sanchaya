'use client';

import { useState, useEffect, useRef } from 'react';
import { useWatchlist } from '@/lib/contexts/WatchlistContext';
import { StickyNote, Save, X, Trash2, Check } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface NotesWidgetProps {
  mediaId: string;
}

export default function NotesWidget({ mediaId }: NotesWidgetProps) {
  const { watchlist, updateNotes } = useWatchlist();
  const [isOpen, setIsOpen] = useState(false);
  const [notes, setNotes] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [justSaved, setJustSaved] = useState(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  // Find item by ID or externalId
  const item = watchlist.find((i) => i.id === String(mediaId) || i.externalId === String(mediaId));

  useEffect(() => {
    if (item && item.notes) {
      setNotes(item.notes);
    } else {
      setNotes('');
    }
  }, [item]);

  // Focus textarea when modal opens
  useEffect(() => {
    if (isOpen) {
      setTimeout(() => {
        textareaRef.current?.focus();
      }, 80);
    }
  }, [isOpen]);

  // Close on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        setIsOpen(false);
      }
    };
    if (isOpen) window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen]);

  // Only show the notes widget if the item is in the user's watchlist
  if (!item) return null;

  const hasNotes = Boolean(item.notes && item.notes.trim().length > 0);

  const handleSave = () => {
    setIsSaving(true);
    const trimmed = notes.trim();

    // Update all items in the same franchise, or just this item if no franchise
    const itemsToUpdate = item.franchiseId
      ? watchlist.filter((i) => i.franchiseId === item.franchiseId)
      : [item];

    itemsToUpdate.forEach((i) => {
      updateNotes(i.id, trimmed === '' ? null : trimmed);
    });

    setJustSaved(true);
    setTimeout(() => {
      setIsSaving(false);
      setJustSaved(false);
      setIsOpen(false);
    }, 450);
  };

  const handleDelete = () => {
    setNotes('');
    const itemsToUpdate = item.franchiseId
      ? watchlist.filter((i) => i.franchiseId === item.franchiseId)
      : [item];

    itemsToUpdate.forEach((i) => {
      updateNotes(i.id, null);
    });
    setIsOpen(false);
  };

  return (
    <>
      <div className="relative inline-flex">
        <button
          type="button"
          onClick={() => setIsOpen(true)}
          aria-label={hasNotes ? 'View or edit notes' : 'Add personal note'}
          className={`h-11 px-4 rounded-full font-semibold text-sm inline-flex items-center justify-center gap-2 whitespace-nowrap cursor-pointer select-none transition-all duration-200 active:scale-95 border backdrop-blur-md ${
            hasNotes
              ? 'bg-amber-400/15 text-amber-300 border-amber-400/30 shadow-[0_0_16px_rgba(251,191,36,0.25)]'
              : 'bg-slate-900/65 text-slate-300 hover:text-white border-white/10 hover:border-white/20 hover:bg-slate-800/80 shadow-sm'
          }`}
        >
          <StickyNote className="w-4 h-4 shrink-0 opacity-85" />
          <span className="leading-none">{hasNotes ? 'Notes' : 'Add Note'}</span>
          {hasNotes && (
            <span className="w-1.5 h-1.5 rounded-full bg-amber-400 shadow-[0_0_8px_#fbbf24] shrink-0" />
          )}
        </button>
      </div>

      <AnimatePresence>
        {isOpen && (
          <div
            className="fixed inset-0 z-[100] flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/75 backdrop-blur-md"
            onClick={(e) => {
              if (e.target === e.currentTarget) setIsOpen(false);
            }}
          >
            <motion.div
              initial={{ opacity: 0, y: 20, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 20, scale: 0.95 }}
              transition={{ duration: 0.2, ease: [0.16, 1, 0.3, 1] }}
              className="w-full sm:max-w-md bg-slate-900/98 backdrop-blur-2xl border border-white/15 rounded-t-3xl sm:rounded-3xl p-5 sm:p-6 shadow-2xl flex flex-col gap-4 text-left max-sm:pb-8"
            >
              {/* Mobile Drag Indicator */}
              <div className="sm:hidden w-10 h-1 bg-white/20 rounded-full mx-auto -mt-1 mb-1" />

              {/* Header */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-full bg-amber-400/15 border border-amber-400/30 flex items-center justify-center text-amber-400">
                    <StickyNote className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="text-white font-bold text-base leading-tight">Personal Notes</h3>
                    <p className="text-xs text-slate-400">Only visible to you</p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setIsOpen(false)}
                  className="w-8 h-8 rounded-full flex items-center justify-center text-slate-400 hover:text-white hover:bg-white/10 transition-colors"
                  aria-label="Close notes"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              {/* Textarea */}
              <div className="flex flex-col gap-1.5">
                <textarea
                  ref={textareaRef}
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Write your review, thoughts, season notes, or reminders..."
                  maxLength={2000}
                  className="w-full bg-black/45 border border-white/10 rounded-2xl p-4 text-sm text-slate-100 placeholder:text-slate-500 focus:outline-none focus:border-amber-400/50 focus:ring-2 focus:ring-amber-400/20 resize-none h-36 font-sans transition-all leading-relaxed"
                />
                <div className="flex justify-end text-[11px] text-slate-500 font-medium">
                  {notes.length} / 2000
                </div>
              </div>

              {/* Actions Footer */}
              <div className="flex items-center justify-between pt-1">
                {hasNotes ? (
                  <button
                    type="button"
                    onClick={handleDelete}
                    className="flex items-center gap-1.5 px-3 py-2 text-rose-400 hover:text-rose-300 hover:bg-rose-500/10 rounded-xl text-xs font-semibold transition-colors cursor-pointer"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                    <span>Delete</span>
                  </button>
                ) : (
                  <div />
                )}

                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setIsOpen(false)}
                    className="px-4 py-2 text-xs font-semibold text-slate-300 hover:text-white hover:bg-white/10 rounded-full transition-colors cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="button"
                    onClick={handleSave}
                    disabled={isSaving}
                    className="flex items-center gap-1.5 px-5 py-2.5 bg-amber-500 hover:bg-amber-400 active:scale-95 text-slate-950 font-bold text-xs rounded-full shadow-lg shadow-amber-500/25 transition-all disabled:opacity-50 cursor-pointer"
                  >
                    {justSaved ? (
                      <>
                        <Check className="w-3.5 h-3.5" />
                        <span>Saved</span>
                      </>
                    ) : (
                      <>
                        <Save className="w-3.5 h-3.5" />
                        <span>{isSaving ? 'Saving...' : 'Save Note'}</span>
                      </>
                    )}
                  </button>
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </>
  );
}
