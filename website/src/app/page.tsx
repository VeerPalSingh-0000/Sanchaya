import { getTrending } from '@/lib/tmdb';
import { getTrendingAnime } from '@/lib/anilist';
import MediaGrid from '@/components/media/MediaGrid';
import SearchBar from '@/components/media/SearchBar';
import HeroCarousel from '@/components/media/HeroCarousel';
import LandingPage from '@/components/landing/LandingPage';
import { auth } from '@/lib/auth';

export default async function Home() {
  const session = await auth();

  // If user is NOT logged in, show the independent marketing landing page
  if (!session) {
    return <LandingPage />;
  }

  // Fetch trending data for the authenticated dashboard
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

      <div id="explore-section" className="w-full mx-auto pb-[120px] md:pb-24 pt-12 md:pt-8">
        {/* Search & Filters Section */}
        <section className="mb-12 max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop">
          <div className="relative w-full max-w-2xl mx-auto md:mx-0 slide-up">
            <SearchBar />
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
