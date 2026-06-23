"use client";

import { useSession } from "next-auth/react";
import { useState, useEffect } from "react";
import MediaRow from "@/components/media/MediaRow";
import type { Media, RecommendationResult } from "@/types/media";

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

  const fallbackRecommended = [
    ...trendingMovies.slice(0, 5),
    ...trendingSeries.slice(0, 5),
    ...trendingAnime.slice(0, 5),
  ].sort(() => 0.5 - Math.random());

  if (!mounted) {
    return <main className="min-h-screen" />;
  }

  const displayItems =
    recommended.length > 0
      ? recommended.map((r) => r.media)
      : fallbackRecommended;

  const subtitleText = session?.user
    ? loading
      ? "Analyzing your watchlist..."
      : topGenres.length > 0
        ? `Based on your love for ${topGenres.slice(0, 3).join(", ")}`
        : "Because you've added items to your watchlist, we think you'll love these."
    : "Sign in and add items to your watchlist to get personalized recommendations! For now, here are the trending hits.";

  return (
    <main className="w-full pb-32 pt-8 md:pt-16 flex flex-col gap-12 slide-up">
      {/* Premium Hero Header */}
      <header className="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop w-full flex flex-col items-center text-center gap-6">
        <div className="flex flex-col gap-2 items-center">
          <h1 className="font-display-xl-mobile text-[40px] md:font-display-xl md:text-[64px] font-bold text-on-surface tracking-tight">
            Your{" "}
            <span className="bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
              Recommendations
            </span>
          </h1>
          <p className="font-body-md text-[16px] md:text-[18px] text-on-surface-variant max-w-2xl">
            {subtitleText}
          </p>
        </div>

        {session?.user && !loading && (
          <button
            className="flex items-center gap-2 bg-surface-container/40 backdrop-blur-md border border-white/10 text-on-surface px-6 py-3 rounded-full font-bold font-label-sm text-[12px] hover:bg-white/10 transition-colors shadow-lg active:scale-95"
            onClick={fetchRecommendations}
          >
            <span className="material-symbols-outlined text-[18px]">
              refresh
            </span>
            REFRESH PICKS
          </button>
        )}
      </header>

      {/* Media Rows */}
      <div className="flex flex-col gap-16 mt-8">
        {loading ? (
          <div className="flex flex-col gap-4 mx-margin-mobile md:mx-margin-desktop overflow-hidden mt-8">
            <div className="h-8 w-64 bg-surface-variant/50 rounded-md shimmer mb-2" />
            <div className="flex gap-4">
              {[1, 2, 3, 4, 5, 6].map((i) => (
                <div
                  key={i}
                  className="min-w-[140px] md:min-w-[200px] aspect-[2/3] bg-surface-variant/30 rounded-xl shimmer border border-white/5"
                />
              ))}
            </div>
          </div>
        ) : error ? (
          <div className="flex flex-col items-center justify-center py-20 gap-4 glass-panel mx-margin-mobile md:mx-margin-desktop rounded-2xl border border-error/20 bg-error-container/10">
            <span className="material-symbols-outlined text-4xl text-error">
              error
            </span>
            <p className="font-body-md text-on-surface">{error}</p>
            <button
              onClick={fetchRecommendations}
              className="mt-4 bg-error text-on-error font-bold px-6 py-2 rounded-full hover:bg-error/80 transition-colors"
            >
              Try Again
            </button>
          </div>
        ) : (
          <MediaRow
            title="Top Picks for You"
            items={filterItems(displayItems)}
            icon={
              <span
                className="material-symbols-outlined text-primary text-[32px]"
                style={{ fontVariationSettings: "'FILL' 1" }}
              >
                auto_awesome
              </span>
            }
          />
        )}

        {!hideFillers && trendingMovies.length > 0 && (
          <MediaRow
            title="Trending Movies"
            items={trendingMovies.slice(0, 15)}
          />
        )}

        {trendingSeries.length > 0 && (
          <MediaRow
            title="Trending Series"
            items={filterItems(trendingSeries)}
          />
        )}

        {trendingAnime.length > 0 && (
          <MediaRow title="Trending Anime" items={filterItems(trendingAnime)} />
        )}
      </div>
    </main>
  );
}
