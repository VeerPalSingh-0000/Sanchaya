import styles from './Footer.module.css';

export default function Footer() {
  return (
    <footer className={styles.footer}>
      <div className={styles.gradientLine} />
      <div className={styles.inner}>
        {/* Attribution (required by TMDb & AniList ToS) */}
        <div className={styles.attribution}>
          <p className={styles.brand}>
            Built with <span className={styles.brandName}>CINEVERSE</span>
          </p>
          <p className={styles.credits}>
            Data provided by{' '}
            <a
              href="https://www.themoviedb.org/"
              target="_blank"
              rel="noopener noreferrer"
              className={styles.creditLink}
            >
              TMDb
            </a>{' '}
            and{' '}
            <a
              href="https://anilist.co/"
              target="_blank"
              rel="noopener noreferrer"
              className={styles.creditLink}
            >
              AniList
            </a>
            . This product uses the TMDb API but is not endorsed or certified by TMDb.
          </p>
        </div>

        {/* Social row */}
        <div className={styles.socials}>
          <a href="#" className={styles.socialLink} aria-label="GitHub">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 .5C5.37.5 0 5.78 0 12.292c0 5.211 3.438 9.63 8.205 11.188.6.111.82-.254.82-.567 0-.28-.01-1.022-.015-2.005-3.338.711-4.042-1.582-4.042-1.582-.546-1.361-1.333-1.723-1.333-1.723-1.089-.731.083-.716.083-.716 1.205.082 1.838 1.215 1.838 1.215 1.07 1.803 2.809 1.282 3.493.98.108-.763.417-1.282.76-1.577-2.665-.295-5.466-1.309-5.466-5.827 0-1.287.465-2.339 1.235-3.164-.135-.298-.535-1.497.105-3.121 0 0 1.005-.316 3.3 1.209A11.616 11.616 0 0112 6.601c1.025.005 2.055.138 3.02.404 2.28-1.525 3.285-1.209 3.285-1.209.645 1.624.245 2.823.12 3.121.765.825 1.23 1.877 1.23 3.164 0 4.53-2.805 5.527-5.475 5.817.42.354.81 1.077.81 2.182 0 1.578-.015 2.846-.015 3.229 0 .309.21.682.825.567C20.565 21.917 24 17.5 24 12.292 24 5.78 18.627.5 12 .5z" />
            </svg>
          </a>
          <a href="#" className={styles.socialLink} aria-label="Twitter">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
              <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
            </svg>
          </a>
          <a href="#" className={styles.socialLink} aria-label="Discord">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
              <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.462-.63.874-1.295 1.226-1.994a.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.095 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.095 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z" />
            </svg>
          </a>
        </div>

        <p className={styles.copy}>
          &copy; {new Date().getFullYear()} CINEVERSE. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
