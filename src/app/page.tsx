import { getTrending } from '@/lib/tmdb';
import { getTrendingAnime } from '@/lib/anilist';
import MediaGrid from '@/components/media/MediaGrid';
import SearchBar from '@/components/media/SearchBar';
import HeroCarousel from '@/components/media/HeroCarousel';

export default async function Home() {
  // Fetch trending data in parallel
  const [trendingMovies, trendingTV, trendingAnime] = await Promise.all([
    getTrending('movie', 'week'),
    getTrending('tv', 'week'),
    getTrendingAnime(1, 20),
  ]);

  // Combine top trending items for the Hero carousel
  const topTrending = [...trendingMovies.slice(0, 3), ...trendingAnime.slice(0, 3), ...trendingTV.slice(0, 4)]
    .sort(() => Math.random() - 0.5); // Shuffle slightly

  return (
    <>
      {/* Immersive Background Animation */}
      <div className="fixed inset-0 z-[-1] pointer-events-none">
        <div className="absolute inset-0 bg-gradient-to-b from-background/20 via-background/60 to-background"></div>
      </div>

      <div className="w-full mx-auto pb-[120px] md:pb-24 pt-24 md:pt-12">
        {/* Search & Filters Section */}
        <section className="mb-12 max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop">
          <div className="relative w-full max-w-2xl mx-auto md:mx-0 mb-6 slide-up">
            <SearchBar />
          </div>
          
          {/* Glassmorphic Pill Filters */}
          <div className="flex space-x-4 overflow-x-auto no-scrollbar pb-2 slide-up" style={{ animationDelay: '100ms' }}>
            <button className="px-6 py-2 rounded-full bg-gradient-to-r from-primary to-secondary text-surface font-label-sm text-[12px] whitespace-nowrap active:scale-95 transition-transform shadow-[0_10px_20px_rgba(245,158,11,0.2)] font-bold">All</button>
            <button className="px-6 py-2 rounded-full bg-surface-container/40 backdrop-blur-lg border border-white/10 text-on-surface-variant hover:text-on-surface hover:bg-white/10 font-label-sm text-[12px] whitespace-nowrap transition-all active:scale-95 font-bold">Movies</button>
            <button className="px-6 py-2 rounded-full bg-surface-container/40 backdrop-blur-lg border border-white/10 text-on-surface-variant hover:text-on-surface hover:bg-white/10 font-label-sm text-[12px] whitespace-nowrap transition-all active:scale-95 font-bold">Series</button>
            <button className="px-6 py-2 rounded-full bg-surface-container/40 backdrop-blur-lg border border-white/10 text-on-surface-variant hover:text-on-surface hover:bg-white/10 font-label-sm text-[12px] whitespace-nowrap transition-all active:scale-95 font-bold">Anime</button>
          </div>
        </section>

        {/* Hero Carousel Section */}
        <section className="mb-16 relative w-full overflow-hidden px-4 md:px-0 fade-in" style={{ animationDelay: '200ms' }}>
          <div className="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop mb-6">
            <h2 className="font-headline-lg-mobile md:font-headline-lg text-[24px] md:text-[32px] text-on-background font-bold">Trending Now</h2>
          </div>
          <HeroCarousel items={topTrending} />
        </section>

        {/* Trending Categories */}
        <div className="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop flex flex-col gap-12">
          {/* Trending Movies */}
          <section className="fade-in" style={{ animationDelay: '300ms' }}>
            <div className="mb-6">
              <h2 className="font-headline-lg-mobile md:font-headline-lg text-[24px] md:text-[32px] text-on-background font-bold">Popular Movies</h2>
            </div>
            <MediaGrid items={trendingMovies.slice(0, 10)} layout="horizontal" />
          </section>

          {/* Trending Series */}
          <section className="fade-in" style={{ animationDelay: '400ms' }}>
            <div className="mb-6">
              <h2 className="font-headline-lg-mobile md:font-headline-lg text-[24px] md:text-[32px] text-on-background font-bold">Popular Series</h2>
            </div>
            <MediaGrid items={trendingTV.slice(0, 10)} layout="horizontal" />
          </section>

          {/* Trending Anime */}
          <section className="fade-in" style={{ animationDelay: '500ms' }}>
            <div className="mb-6">
              <h2 className="font-headline-lg-mobile md:font-headline-lg text-[24px] md:text-[32px] text-on-background font-bold">Popular Anime</h2>
            </div>
            <MediaGrid items={trendingAnime.slice(0, 10)} layout="horizontal" />
          </section>
        </div>
      </div>
    </>
  );
}
