import Link from 'next/link';
import { ExternalLink, Coffee } from 'lucide-react';

export default function Footer() {
  return (
    <footer className="relative w-full overflow-hidden mt-auto bg-surface-container/20 backdrop-blur-md border-t border-white/5">
      {/* Background glow effects */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full h-[1px] bg-gradient-to-r from-transparent via-primary/30 to-transparent"></div>
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[60%] h-[150px] bg-primary/5 blur-[100px] pointer-events-none"></div>

      <div className="relative z-10 max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop pt-8 pb-32 md:py-10">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 md:gap-6 items-center md:items-start">
          
          {/* Brand Section */}
          <div className="flex flex-col items-center md:items-start gap-3">
            <Link href="/" className="flex items-center gap-3 group">
              <svg className="w-7 h-7 transition-transform duration-500 group-hover:scale-110" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <defs>
                  <linearGradient id="logoGradFooter" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#ffc174" />
                    <stop offset="100%" stopColor="#ffb0cd" />
                  </linearGradient>
                </defs>
                <path d="M12 2L2 7l10 5 10-5-10-5z" fill="url(#logoGradFooter)" />
                <path d="M2 17l10 5 10-5" stroke="url(#logoGradFooter)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
                <path d="M2 12l10 5 10-5" stroke="url(#logoGradFooter)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
              <span className="font-display-xl text-[1.6rem] font-bold bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent tracking-tight">
                Sanchaya
              </span>
            </Link>
            <p className="text-on-surface-variant font-body-md text-[13px] max-w-[250px] text-center md:text-left leading-relaxed">
              Your personal entertainment universe. Track movies, series, and anime in one beautifully designed place.
            </p>
          </div>

          {/* Data Providers */}
          <div className="flex flex-col items-center md:items-center gap-3">
            <h3 className="text-on-surface font-bold text-[11px] tracking-widest uppercase opacity-80">Powered By</h3>
            <div className="flex flex-col gap-2 text-center">
              <a href="https://www.themoviedb.org/" target="_blank" rel="noopener noreferrer" className="text-on-surface-variant hover:text-primary transition-colors text-[14px] flex items-center justify-center md:justify-start gap-2 group font-medium">
                The Movie Database (TMDb)
                <ExternalLink className="w-4 h-4 opacity-0 -translate-x-2 group-hover:translate-x-0 group-hover:opacity-100 transition-all" />
              </a>
              <a href="https://anilist.co/" target="_blank" rel="noopener noreferrer" className="text-on-surface-variant hover:text-primary transition-colors text-[14px] flex items-center justify-center md:justify-start gap-2 group font-medium">
                AniList
                <ExternalLink className="w-4 h-4 opacity-0 -translate-x-2 group-hover:translate-x-0 group-hover:opacity-100 transition-all" />
              </a>
            </div>
          </div>

          {/* Socials & Links */}
          <div className="flex flex-col items-center md:items-end gap-3">
            <h3 className="text-on-surface font-bold text-[11px] tracking-widest uppercase opacity-80 hidden md:block">Connect</h3>
            <div className="flex items-center gap-3">
              <a href="https://github.com/VeerPalSingh-0000/Sanchaya" target="_blank" rel="noopener noreferrer" className="w-10 h-10 rounded-full bg-surface-container/50 border border-white/5 flex items-center justify-center text-on-surface-variant hover:text-white hover:bg-white/10 hover:border-white/20 transition-all duration-300 hover:-translate-y-1 hover:shadow-[0_10px_20px_rgba(255,255,255,0.05)]">
                 <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 .5C5.37.5 0 5.78 0 12.292c0 5.211 3.438 9.63 8.205 11.188.6.111.82-.254.82-.567 0-.28-.01-1.022-.015-2.005-3.338.711-4.042-1.582-4.042-1.582-.546-1.361-1.333-1.723-1.333-1.723-1.089-.731.083-.716.083-.716 1.205.082 1.838 1.215 1.838 1.215 1.07 1.803 2.809 1.282 3.493.98.108-.763.417-1.282.76-1.577-2.665-.295-5.466-1.309-5.466-5.827 0-1.287.465-2.339 1.235-3.164-.135-.298-.535-1.497.105-3.121 0 0 1.005-.316 3.3 1.209A11.616 11.616 0 0112 6.601c1.025.005 2.055.138 3.02.404 2.28-1.525 3.285-1.209 3.285-1.209.645 1.624.245 2.823.12 3.121.765.825 1.23 1.877 1.23 3.164 0 4.53-2.805 5.527-5.475 5.817.42.354.81 1.077.81 2.182 0 1.578-.015 2.846-.015 3.229 0 .309.21.682.825.567C20.565 21.917 24 17.5 24 12.292 24 5.78 18.627.5 12 .5z" />
                </svg>
              </a>
              <a href="https://discord.gg/AgRavcwbk" target="_blank" rel="noopener noreferrer" className="w-10 h-10 rounded-full bg-surface-container/50 border border-white/5 flex items-center justify-center text-on-surface-variant hover:text-[#5865F2] hover:bg-[#5865F2]/10 hover:border-[#5865F2]/30 transition-all duration-300 hover:-translate-y-1 hover:shadow-[0_10px_20px_rgba(88,101,242,0.15)] group">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" className="group-hover:scale-110 transition-transform">
                  <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.462-.63.874-1.295 1.226-1.994a.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.095 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.095 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z" />
                </svg>
              </a>
              <a href="https://buymeacoffee.com/veerpalsingh" target="_blank" rel="noopener noreferrer" className="w-10 h-10 rounded-full bg-surface-container/50 border border-white/5 flex items-center justify-center text-on-surface-variant hover:text-[#FFDD00] hover:bg-[#FFDD00]/10 hover:border-[#FFDD00]/30 transition-all duration-300 hover:-translate-y-1 hover:shadow-[0_10px_20px_rgba(255,221,0,0.1)] group">
                <Coffee className="w-5 h-5 group-hover:-rotate-12 transition-transform" />
              </a>
            </div>
          </div>
        </div>

        {/* Divider & Copyright */}
        <div className="mt-6 pt-6 border-t border-white/5 flex flex-col md:flex-row items-center justify-between gap-4 text-center">
          <p className="text-on-surface-variant/60 text-[12px] font-medium">
            &copy; {new Date().getFullYear()} Sanchaya. All rights reserved.
          </p>
          <p className="text-on-surface-variant/60 text-[11px] max-w-lg md:text-right leading-relaxed">
            This product uses the TMDb API but is not endorsed or certified by TMDb.
          </p>
        </div>
      </div>
    </footer>
  );
}
