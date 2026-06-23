'use client';

import styles from './landing.module.css';
import { Media } from '@/types/media';

interface LandingHeroProps {
  heroItems: Media[];
}

export default function LandingHero({ heroItems }: LandingHeroProps) {
  const handleScrollDown = () => {
    // Scroll to the trending section smoothly
    const trendingSection = document.getElementById('explore-section');
    if (trendingSection) {
      trendingSection.scrollIntoView({ behavior: 'smooth' });
    }
  };

  // Ensure we have 4 valid items with posters
  const validItems = heroItems.filter(item => item.posterUrl).slice(0, 4);

  return (
    <div className={styles.heroContainer}>
      {/* Background Orbs */}
      <div className={styles.backgroundOrbs}>
        <div className={styles.orb1}></div>
        <div className={styles.orb2}></div>
        <div className={styles.orb3}></div>
      </div>

      {/* Floating Cards */}
      <div className={styles.floatingCards}>
        {validItems.map((item, index) => (
          <div key={item.externalId} className={`${styles.card} ${styles[`card${index + 1}`]}`}>
            <img src={item.posterUrl} alt={item.title} />
          </div>
        ))}
      </div>

      {/* Main Content */}
      <div className={styles.content}>
        <div className={styles.badge}>
          <span className="material-symbols-outlined" style={{ fontSize: '18px', color: 'var(--primary)' }}>auto_awesome</span>
          <span>Your Entertainment Universe</span>
        </div>
        
        <h1 className={styles.title}>
          Track Everything <br />
          <span className={styles.titleHighlight}>You Watch</span>
        </h1>
        
        <p className={styles.subtitle}>
          Discover, save, and track your favorite movies, TV series, and anime all in one beautifully designed place.
        </p>

        <div className={styles.actions}>
          <button className={styles.primaryButton} onClick={handleScrollDown}>
            <span className="material-symbols-outlined">explore</span>
            Start Exploring
          </button>
          
          <a href="https://github.com/VeerPalSingh-0000/Sanchaya" target="_blank" rel="noopener noreferrer" className={styles.secondaryButton}>
            <span className="material-symbols-outlined">code</span>
            View on GitHub
          </a>
        </div>
      </div>

      {/* Scroll Indicator */}
      <div className={styles.scrollIndicator} onClick={handleScrollDown}>
        <span>Scroll to Explore</span>
        <div className={styles.scrollIcon}>
          <div className={styles.scrollDot}></div>
        </div>
      </div>
    </div>
  );
}
