'use client';

import { useWatchlist } from '@/lib/contexts/WatchlistContext';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, Film, PlayCircle, Library, Tv, CheckCircle, Clock } from 'lucide-react';
import { motion } from 'framer-motion';

export default function StatisticsPage() {
  const { watchlist, isLoading } = useWatchlist();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const totalCompleted = watchlist.filter((i) => i.status === 'completed').length;
  const totalWatching = watchlist.filter((i) => i.status === 'watching').length;
  const totalPlanToWatch = watchlist.filter((i) => i.status === 'plan_to_watch').length;

  const movies = watchlist.filter((i) => i.mediaType === 'movie').length;
  const series = watchlist.filter((i) => i.mediaType === 'series').length;
  const anime = watchlist.filter((i) => i.mediaType === 'anime').length;

  if (!mounted) {
    return <main className="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop pt-8 pb-32 min-h-screen" />;
  }

  return (
    <main className="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop pt-8 pb-32 min-h-screen slide-up">
      <header className="flex items-center gap-4 mb-8">
        <Link href="/settings" className="p-2 hover:bg-white/10 rounded-full transition-colors">
          <ArrowLeft className="w-6 h-6 text-on-surface" />
        </Link>
        <h1 className="font-display-xl-mobile md:font-display-xl text-[32px] md:text-[48px] text-on-surface tracking-tight font-bold">
          Your Statistics
        </h1>
      </header>

      {isLoading ? (
        <div className="flex flex-col items-center justify-center py-32 text-center fade-in">
          <div className="w-12 h-12 border-4 border-primary/20 border-t-primary rounded-full animate-spin mb-4" />
          <p className="font-body-md text-on-surface-variant animate-pulse">Loading statistics...</p>
        </div>
      ) : watchlist.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-24 text-center glass-panel rounded-2xl border border-white/5">
          <h2 className="font-headline-lg-mobile md:font-headline-lg text-[24px] md:text-[32px] font-bold text-on-surface mb-4">
            No statistics available
          </h2>
          <p className="font-body-md text-on-surface-variant max-w-md mx-auto mb-8">
            Add some items to your watchlist to see your stats!
          </p>
          <Link
            href="/discover"
            className="bg-primary text-surface font-bold py-3 px-8 rounded-full hover:bg-primary-container transition-colors shadow-[0_10px_20px_rgba(245,158,11,0.2)] active:scale-95"
          >
            Discover Media
          </Link>
        </div>
      ) : (
        <div className="flex flex-col gap-10">
          {/* Total Entries */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4 }}
            className="w-full p-6 md:p-8 rounded-3xl bg-surface-container/60 backdrop-blur-xl border border-white/10 flex items-center gap-6 shadow-xl"
          >
            <div className="p-4 rounded-full bg-primary/20">
              <Library className="w-8 h-8 text-primary" />
            </div>
            <div>
              <p className="text-on-surface-variant font-medium text-sm mb-1">Total Entries</p>
              <h2 className="text-on-surface font-bold text-4xl">{watchlist.length}</h2>
            </div>
          </motion.div>

          {/* By Status */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4, delay: 0.1 }}
          >
            <h3 className="text-xl font-bold text-on-surface mb-4">By Status</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <StatBox title="Completed" value={totalCompleted} colorClass="text-emerald-500" icon={<CheckCircle className="w-5 h-5 mb-2 opacity-50" />} />
              <StatBox title="Watching" value={totalWatching} colorClass="text-blue-500" icon={<PlayCircle className="w-5 h-5 mb-2 opacity-50" />} />
              <StatBox title="Plan to Watch" value={totalPlanToWatch} colorClass="text-orange-500" icon={<Clock className="w-5 h-5 mb-2 opacity-50" />} />
            </div>
          </motion.div>

          {/* By Type */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4, delay: 0.2 }}
          >
            <h3 className="text-xl font-bold text-on-surface mb-4">By Type</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <StatBox title="Movies" value={movies} colorClass="text-purple-500" icon={<Film className="w-5 h-5 mb-2 opacity-50" />} />
              <StatBox title="TV Shows" value={series} colorClass="text-pink-500" icon={<Tv className="w-5 h-5 mb-2 opacity-50" />} />
              <StatBox title="Anime" value={anime} colorClass="text-teal-500" icon={<PlayCircle className="w-5 h-5 mb-2 opacity-50" />} />
            </div>
          </motion.div>
        </div>
      )}
    </main>
  );
}

function StatBox({ title, value, colorClass, icon }: { title: string; value: number | string; colorClass: string; icon: React.ReactNode }) {
  return (
    <div className="p-6 rounded-2xl bg-surface-container/60 backdrop-blur-xl border border-white/10 flex flex-col items-center justify-center text-center shadow-lg hover:bg-surface-container transition-colors">
      <div className={colorClass}>
        {icon}
      </div>
      <h3 className={`text-3xl font-bold mb-2 ${colorClass}`}>{value}</h3>
      <p className="text-on-surface-variant text-sm font-semibold">{title}</p>
    </div>
  );
}
