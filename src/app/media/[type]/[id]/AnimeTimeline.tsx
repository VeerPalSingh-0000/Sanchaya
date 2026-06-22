"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { Season, Media } from "@/types/media";
import styles from "./mediaDetail.module.css";

interface AnimeTimelineProps {
  seasons: Season[];
  type: string;
  media: Media | null;
}

export default function AnimeTimeline({
  seasons,
  type,
  media,
}: AnimeTimelineProps) {
  const [mainStoryOnly, setMainStoryOnly] = useState(false);

  const isAnime =
    type === "anime" ||
    (media?.originCountry === "JP" &&
      media?.genres.some((g) => g.name === "Animation"));

  // Clean, metadata-driven filtering
  const displayedSeasons = mainStoryOnly
    ? seasons.filter((s) => {
        // If we have AniList metadata, use it as the source of truth
        if (s.relationType) {
          // These 4 relationships dictate the Canon "Main" Timeline
          const canonRelations = ["CURRENT", "PREQUEL", "SEQUEL", "PARENT"];
          return canonRelations.includes(s.relationType.toUpperCase());
        }
        
        // Fallback for non-anime TMDB data that lacks AniList graphs
        return true;
      })
    : seasons;

  if (!seasons || seasons.length === 0) return null;

  return (
    <div className={styles.minimalTimelineSection}>
      <div className={styles.minimalHeader}>
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: "16px",
            width: "100%",
          }}
        >
          <div style={{ display: "flex", alignItems: "baseline", gap: "16px" }}>
            <h3 className={styles.minimalTitle}>
              {isAnime ? "Franchise" : "Seasons"}
            </h3>
            <p className={styles.minimalSubtitle}>Watch order</p>
          </div>

          {isAnime && (
            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <button
                onClick={() => setMainStoryOnly(false)}
                style={{
                  background: !mainStoryOnly
                    ? "linear-gradient(135deg, #ffc174, #f59e0b)"
                    : "rgba(255, 255, 255, 0.05)",
                  color: !mainStoryOnly ? "#000" : "rgba(255, 255, 255, 0.7)",
                  border: !mainStoryOnly
                    ? "1px solid #f59e0b"
                    : "1px solid rgba(255, 255, 255, 0.1)",
                  padding: "8px 18px",
                  borderRadius: "20px",
                  fontSize: "0.9rem",
                  fontWeight: 600,
                  cursor: "pointer",
                  transition: "all 0.3s ease",
                  boxShadow: !mainStoryOnly
                    ? "0 4px 12px rgba(245, 158, 11, 0.3)"
                    : "none",
                }}
              >
                <span style={{ marginRight: "6px" }}>📺</span>
                All Content
              </button>
              <button
                onClick={() => setMainStoryOnly(true)}
                style={{
                  background: mainStoryOnly
                    ? "linear-gradient(135deg, #ffc174, #f59e0b)"
                    : "rgba(255, 255, 255, 0.05)",
                  color: mainStoryOnly ? "#000" : "rgba(255, 255, 255, 0.7)",
                  border: mainStoryOnly
                    ? "1px solid #f59e0b"
                    : "1px solid rgba(255, 255, 255, 0.1)",
                  padding: "8px 18px",
                  borderRadius: "20px",
                  fontSize: "0.9rem",
                  fontWeight: 600,
                  cursor: "pointer",
                  transition: "all 0.3s ease",
                  boxShadow: mainStoryOnly
                    ? "0 4px 12px rgba(245, 158, 11, 0.3)"
                    : "none",
                }}
              >
                <span style={{ marginRight: "6px" }}>✨</span>
                Main Story Only
              </button>
            </div>
          )}
        </div>
      </div>

      <div className={styles.minimalScrollContainer}>
        <div className={styles.minimalTrack}>
          {displayedSeasons.map((season, idx) => {
            const CardContent = (
              <>
                <div className={styles.minimalNumberBackground}>
                  {String(idx + 1).padStart(2, "0")}
                </div>

                <div className={styles.minimalCard}>
                  <div className={styles.minimalPosterContainer}>
                    {season.posterUrl ? (
                      <Image
                        src={season.posterUrl}
                        alt={season.name}
                        fill
                        sizes="16rem"
                        className={styles.minimalPosterImage}
                        priority={idx < 4}
                      />
                    ) : (
                      <div className={styles.backdropFallback} />
                    )}
                  </div>

                  <div className={styles.minimalInfo}>
                    <span className={styles.minimalStepBadge}>
                      Part {String(idx + 1).padStart(2, "0")}
                      {season.format ? ` • ${season.format}` : ""}
                    </span>
                    <h4 className={styles.minimalSeasonTitle}>{season.name}</h4>
                    {season.episodeCount > 0 && (
                      <span className={styles.minimalEpisodeCount}>
                        {season.episodeCount} Episodes
                      </span>
                    )}
                  </div>
                </div>
              </>
            );

            return season.mediaId && season.mediaType ? (
              <Link
                key={season.number}
                href={`/media/${season.mediaType}/${season.mediaId}`}
                className={styles.minimalCardWrapper}
                style={{ textDecoration: "none" }}
              >
                {CardContent}
              </Link>
            ) : (
              <div key={season.number} className={styles.minimalCardWrapper}>
                {CardContent}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}