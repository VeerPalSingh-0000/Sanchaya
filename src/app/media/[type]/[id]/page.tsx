import Image from 'next/image';
import { notFound } from 'next/navigation';
import { getMovieDetails, getTVDetails, getTVSeasonDetails } from '@/lib/tmdb';
import { getAnimeDetails, getAnimeSeasons } from '@/lib/anilist';
import Badge from '@/components/ui/Badge';
import WatchlistButton from '@/components/media/WatchlistButton';
import type { MediaType } from '@/types/media';
import styles from './mediaDetail.module.css';

export default async function MediaDetailPage({
  params,
}: {
  params: Promise<{ type: string; id: string }>;
}) {
  const { type, id } = await params;

  let media = null;
  let seasons = null;

  if (type === 'movie') {
    media = await getMovieDetails(id);
  } else if (type === 'series') {
    media = await getTVDetails(id);
    if (media?.seasons && media.seasons.length > 0) {
      // Sort seasons: normal seasons (1,2,3...) first, then Specials (0)
      const sortedSeasons = [...media.seasons].sort((a, b) => {
        if (a.number === 0) return 1;
        if (b.number === 0) return -1;
        return a.number - b.number;
      });

      // Fetch details for the *first proper season* to show episodes as an example
      const firstSeason = await getTVSeasonDetails(id, sortedSeasons[0].number);
      if (firstSeason) {
        seasons = [firstSeason, ...sortedSeasons.slice(1)];
      } else {
        seasons = sortedSeasons;
      }
    }
  } else if (type === 'anime') {
    media = await getAnimeDetails(id);
    seasons = await getAnimeSeasons(id);
  }

  if (!media) {
    notFound();
  }

  return (
    <div className={styles.pageWrapper}>
      {/* Backdrop Header */}
      <div className={styles.backdropHeader}>
        {media.backdropUrl ? (
          <Image
            src={media.backdropUrl}
            alt={media.title}
            fill
            sizes="100vw"
            className={styles.backdropImage}
            priority
          />
        ) : (
          <div className={styles.backdropFallback} />
        )}
        <div className={styles.backdropGradient} />
      </div>

      {/* Content */}
      <div className={`container ${styles.contentContainer}`}>
        <div className={styles.detailsWrapper}>
          {/* Poster */}
          <div className={styles.posterWrapper}>
            <div className={styles.poster}>
              <Image
                src={media.posterUrl}
                alt={media.title}
                fill
                sizes="(max-width: 768px) 100vw, 16rem"
                className={styles.posterImage}
                priority
              />
            </div>
          </div>

          {/* Details */}
          <div className={styles.infoSection}>
            <div>
              <h1 className={styles.title}>
                {media.title}
              </h1>
              {media.originalTitle && media.originalTitle !== media.title && (
                <h2 className={styles.originalTitle}>
                  {media.originalTitle}
                </h2>
              )}
            </div>

            <div className={styles.metaRow}>
              <Badge variant="rating">★ {media.rating}</Badge>
              <Badge variant="type">{media.type.toUpperCase()}</Badge>
              <span className={styles.metaText}>{media.releaseDate?.substring(0, 4)}</span>
              {media.totalEpisodes && (
                <span className={styles.metaText}>{media.totalEpisodes} Episodes</span>
              )}
            </div>

            <div className={styles.genresRow}>
              {media.genres.map((g) => (
                <Badge key={g.id} variant="genre">
                  {g.name}
                </Badge>
              ))}
            </div>

            <div style={{ marginTop: '24px', marginBottom: '24px' }}>
              <WatchlistButton media={media} />
            </div>

            <div className={styles.overviewSection}>
              <h3 className={styles.sectionTitle}>Overview</h3>
              <p className={styles.overviewText}>
                {media.overview || 'No overview available.'}
              </p>
            </div>
          </div>
        </div>

        {/* Seasons Section */}
        {seasons && seasons.length > 0 && (
          <div className={styles.seasonsSection}>
            <h3 className={styles.sectionTitle}>Seasons & Episodes</h3>
            <div className={styles.seasonsGrid}>
              {seasons.map((season) => (
                <div key={season.number} className={`glass-card ${styles.seasonCard}`}>
                  <div style={{ display: 'flex', gap: '16px' }}>
                    {season.posterUrl && (
                      <div className={styles.seasonPoster}>
                        <Image src={season.posterUrl} alt={season.name} fill sizes="6rem" className={styles.posterImage} />
                      </div>
                    )}
                    <div>
                      <h4 className={styles.seasonTitle}>{season.name}</h4>
                      <p className={styles.seasonMeta}>
                        {season.episodeCount} Episodes
                      </p>
                      {season.overview && (
                        <p className={styles.seasonOverview}>
                          {season.overview}
                        </p>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
