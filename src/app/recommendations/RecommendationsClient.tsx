"use client";

import { useSession } from "next-auth/react";
import { useState, useEffect } from "react";
import MediaRow from "@/components/media/MediaRow";
import MediaCard from "@/components/media/MediaCard";
import type { Media, RecommendationResult } from "@/types/media";
import { RefreshCw, AlertCircle, Sparkles } from "lucide-react";

interface RecommendationsClientProps {
  trendingMovies: Media[];
  trendingSeries: Media[];
  trendingAnime: Media[];
}

export default function RecommendationsClient({
  trendingMovies,
  trendingSeries,
  trendingAnime,
}: RecommendationsClientProps) {
  const { data: session } = useSession();
  const [mounted, setMounted] = useState(false);
  const [recommended, setRecommended] = useState<RecommendationResult[]>([]);
  const [topGenres, setTopGenres] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [filterType, setFilterType] = useState<"all" | "movie" | "series" | "anime">("all");

  const hideFillers = false;
  const filterItems = (items: Media[]) => items.filter((item) => !!item);

  useEffect(() => {
    setMounted(true);
  }, []);

  const fetchRecommendations = async () => {
    if (!session?.user) return;
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/recommendations");
      if (!res.ok) throw new Error("Failed to fetch recommendations");
      const data = await res.json();
      setRecommended(data.results || []);
      setTopGenres(data.topGenres || []);
    } catch (err) {
      console.error(err);
      setError("Could not load personalized recommendations.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (session?.user) {
      fetchRecommendations();
    }
  }, [session]);

  let displayItems = recommended
    .map((r) => r.media)
    .filter(m => filterType === "all" || m.type === filterType);

  if (displayItems.length === 0) {
    if (filterType === "movie") displayItems = trendingMovies;
    else if (filterType === "series") displayItems = trendingSeries;
    else if (filterType === "anime") displayItems = trendingAnime;
    else {
      displayItems = [
        ...trendingMovies.slice(0, 15),
        ...trendingSeries.slice(0, 15),
        ...trendingAnime.slice(0, 15),
      ].sort(() => 0.5 - Math.random());
    }
  }

  const subtitleText = session?.user
    ? loading
      ? "Analyzing your watchlist..."
      : topGenres.length > 0
        ? `Curated exclusively based on your love for ${topGenres.slice(0, 3).join(", ")}`
        : "Because you've added items to your watchlist, we think you'll love these."
    : "Sign in and build your watchlist to unlock your personalized recommendation engine.";

  if (!mounted) {
    return <main className="min-h-screen" />;
  }

  return (
    <main className="w-full pb-32 flex flex-col gap-12 overflow-x-hidden">
      {/* Minimalist Hero Header */}
      <section className="relative w-full pt-20 pb-8 flex flex-col items-center justify-center text-center px-4">
        
        <div className="slide-up flex flex-col items-center gap-4 max-w-3xl relative z-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-surface-variant/30 text-on-surface-variant mb-2">
            <Sparkles className="w-3.5 h-3.5" />
            <span className="text-[11px] font-medium tracking-widest uppercase">For You</span>
          </div>
          
          <h1 className="font-display-xl-mobile text-[40px] md:font-display-xl md:text-[56px] font-medium tracking-tight text-on-surface leading-tight">
            Personal Discoveries
          </h1>
          
          <p className="font-body-md text-[15px] md:text-[16px] text-on-surface-variant max-w-xl leading-relaxed">
            {subtitleText}
          </p>

          {session?.user && !loading && (
            <button
              className="mt-6 flex items-center gap-2 border border-surface-variant/50 hover:bg-surface-variant/30 text-on-surface px-6 py-2.5 rounded-full font-medium text-[13px] transition-colors active:scale-95 group"
              onClick={fetchRecommendations}
            >
              <RefreshCw className="w-4 h-4 text-on-surface-variant group-hover:rotate-180 transition-transform duration-700" />
              Refresh Picks
            </button>
          )}
        </div>
      </section>

      {/* Filters */}
      <div className="flex items-center justify-center gap-4 px-4 slide-up mb-4" style={{ animationDelay: '0.1s' }}>
        <div className="flex items-center p-1 bg-surface-container/20 border border-surface-variant/30 rounded-full overflow-x-auto no-scrollbar">
          {[
            { id: 'all', label: 'Everything' },
            { id: 'movie', label: 'Movies' },
            { id: 'series', label: 'Webseries' },
            { id: 'anime', label: 'Anime' },
          ].map((f) => (
            <button
              key={f.id}
              className={`px-5 py-2 rounded-full font-medium text-[13px] whitespace-nowrap transition-colors flex-shrink-0 ${
                filterType === f.id
                  ? "bg-surface-variant text-on-surface"
                  : "text-on-surface-variant hover:text-on-surface"
              }`}
              onClick={() => setFilterType(f.id as any)}
            >
              {f.label}
            </button>
          ))}
        </div>
      </div>

      {/* Media Grid */}
      <div className="flex flex-col gap-10 px-margin-mobile md:px-margin-desktop w-full max-w-container-max mx-auto">
        {loading ? (
          <div className="flex flex-col gap-4 overflow-hidden mt-4 slide-up">
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 md:gap-gutter">
              {[...Array(10)].map((_, i) => (
                <div
                  key={i}
                  className="w-full aspect-[2/3] bg-surface-variant/30 rounded-2xl shimmer border border-white/5"
                />
              ))}
            </div>
          </div>
        ) : error ? (
          <div className="flex flex-col items-center justify-center py-24 gap-4 glass-panel rounded-3xl border border-error/20 bg-error-container/5 relative overflow-hidden slide-up">
            <div className="absolute inset-0 bg-gradient-to-br from-error/5 to-transparent opacity-50" />
            <AlertCircle className="w-12 h-12 text-error animate-bounce-slight relative z-10" />
            <p className="font-body-md text-on-surface relative z-10 text-lg">{error}</p>
            <button
              onClick={fetchRecommendations}
              className="mt-4 bg-error text-white font-bold px-8 py-3 rounded-full hover:bg-error/80 transition-colors shadow-lg relative z-10 active:scale-95"
            >
              Try Again
            </button>
          </div>
        ) : displayItems.length > 0 ? (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 md:gap-gutter slide-up" style={{ animationDelay: '0.2s' }}>
            {displayItems.map((media, i) => (
              <div key={media.id}>
                <MediaCard media={media as any} index={i} />
              </div>
            ))}
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center py-24 text-center glass-panel rounded-3xl border border-white/5">
            <Sparkles className="w-16 h-16 text-on-surface-variant opacity-50 mb-4" />
            <h2 className="font-headline-lg-mobile text-[24px] font-bold text-on-surface mb-2">
              No recommendations yet
            </h2>
            <p className="font-body-md text-on-surface-variant max-w-md mx-auto">
              Add more items to your watchlist to help us understand your taste better!
            </p>
          </div>
        )}
      </div>
    </main>
  );
}
