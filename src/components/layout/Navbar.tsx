'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useSession, signIn, signOut } from 'next-auth/react';
import { Home, PlaySquare, Compass, User, Settings, LogOut, Star, Coffee, LogIn, ArrowRight, Sparkles } from 'lucide-react';

const NAV_LINKS = [
  { href: '/', label: 'Home', icon: Home },
  { href: '/watchlist', label: 'My List', icon: PlaySquare },
  { href: '/recommendations', label: 'For You', icon: Sparkles },
  { href: '/discover', label: 'Discover', icon: Compass },
] as const;

export default function Navbar() {
  const pathname = usePathname();
  const { data: session, status } = useSession();
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [guestName, setGuestName] = useState('Guest User');

  useEffect(() => {
    if (status !== 'loading' && !session) {
      const savedName = localStorage.getItem('sanchaya_guest_name');
      if (savedName) {
        setGuestName(savedName);
      }
    }
  }, [session, status]);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as Element;
      if (!target.closest('#profile-menu-container') && !target.closest('#profile-menu-container-mobile')) {
        setDropdownOpen(false);
      }
    };
    if (dropdownOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [dropdownOpen]);

  const isActive = (href: string) =>
    href === '/' ? pathname === '/' : pathname.startsWith(href);

  return (
    <>
      {/* Mobile Top Header (Only visible on mobile) */}
      <div className="md:hidden sticky top-0 z-50 flex items-center justify-between px-4 py-3 bg-[#06090e]/80 backdrop-blur-xl border-b border-white/5">
        <Link href="/" className="flex items-center gap-2">
          <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <linearGradient id="logoGradMob" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#ffc174" />
                <stop offset="100%" stopColor="#ffb0cd" />
              </linearGradient>
            </defs>
            <path d="M12 2L2 7l10 5 10-5-10-5z" fill="url(#logoGradMob)" />
            <path d="M2 17l10 5 10-5" stroke="url(#logoGradMob)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
            <path d="M2 12l10 5 10-5" stroke="url(#logoGradMob)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
          <span className="font-display font-bold text-lg text-white">Sanchaya</span>
        </Link>
        {status === 'loading' ? (
          <div className="w-8 h-8 rounded-full bg-white/10 animate-pulse" />
        ) : !session ? (
          <button 
            onClick={() => signIn()}
            className="text-sm font-semibold bg-primary text-black px-4 py-1.5 rounded-full hover:bg-primary/90 transition-colors"
          >
            Sign In
          </button>
        ) : (
          <div id="profile-menu-container-mobile" className="relative">
            <div 
              className="w-8 h-8 rounded-full bg-surface-container border border-white/10 overflow-hidden cursor-pointer hover:border-primary/50 transition-colors"
              onClick={() => setDropdownOpen(!dropdownOpen)}
            >
              {session.user?.image ? (
                <img className="w-full h-full object-cover" src={session.user.image} alt="Profile" />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-primary bg-primary/10">
                  <User className="w-4 h-4" />
                </div>
              )}
            </div>
            {dropdownOpen && (
              <div className="absolute right-0 mt-4 w-64 rounded-2xl bg-[#06090e] border border-white/10 shadow-2xl p-3 flex flex-col gap-2 z-50 transform origin-top-right transition-all">
                <div className="relative overflow-hidden rounded-2xl p-4 mb-2 bg-white/5 border border-white/5">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full border-2 border-primary/30 overflow-hidden flex-shrink-0">
                      {session.user?.image ? (
                         <img className="w-full h-full object-cover" src={session.user.image} alt="User Profile" />
                      ) : (
                         <div className="w-full h-full flex items-center justify-center text-primary bg-primary/10">
                           <User className="w-5 h-5" />
                         </div>
                      )}
                    </div>
                    <div className="flex flex-col min-w-0">
                      <p className="text-sm font-bold text-white truncate">{session.user?.name}</p>
                      <p className="text-[10px] text-white/50 truncate">{session.user?.email}</p>
                    </div>
                  </div>
                </div>
                <Link href="/settings" className="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-white/5 transition-all" onClick={() => setDropdownOpen(false)}>
                  <Settings className="w-[18px] h-[18px] text-white/50" />
                  <span className="text-sm font-medium text-white/80">Preferences</span>
                </Link>
                <a href="https://github.com/VeerPalSingh-0000/Sanchaya" target="_blank" rel="noopener noreferrer" className="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-[#2ea043]/10 group transition-all" onClick={() => setDropdownOpen(false)}>
                  <Star className="w-[18px] h-[18px] text-[#2ea043] group-hover:scale-110 transition-transform" />
                  <span className="text-sm font-medium text-white/80 group-hover:text-[#2ea043] transition-colors">Star on GitHub</span>
                </a>
                <a href="https://buymeacoffee.com/veerpalsingh" target="_blank" rel="noopener noreferrer" className="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-[#FFDD00]/10 group transition-all" onClick={() => setDropdownOpen(false)}>
                  <Coffee className="w-[18px] h-[18px] text-[#FFDD00] group-hover:-rotate-12 transition-transform" />
                  <span className="text-sm font-medium text-white/80 group-hover:text-[#FFDD00] transition-colors">Buy me a coffee</span>
                </a>
                <div className="h-px w-full bg-white/10 my-1"></div>
                <button 
                  className="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-error/10 transition-all text-left w-full" 
                  onClick={() => { setDropdownOpen(false); signOut(); }}
                >
                  <LogOut className="w-[18px] h-[18px] text-error/80" />
                  <span className="text-sm font-medium text-error/80">Sign Out</span>
                </button>
              </div>
            )}
          </div>
        )}
      </div>
      {/* TopNavBar (Desktop) */}
      <nav className="hidden md:flex sticky top-0 z-50 justify-between items-center px-margin-desktop py-4 w-full bg-surface/40 backdrop-blur-xl border-b border-white/10 shadow-2xl shadow-primary/5">
        <div className="flex items-center gap-12">
          {/* Brand */}
          <Link href="/" className="flex items-center gap-3 group">
            <svg className="w-8 h-8 transition-transform duration-500 group-hover:scale-110" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <linearGradient id="logoGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" stopColor="#ffc174" />
                  <stop offset="100%" stopColor="#ffb0cd" />
                </linearGradient>
              </defs>
              <path d="M12 2L2 7l10 5 10-5-10-5z" fill="url(#logoGrad)" />
              <path d="M2 17l10 5 10-5" stroke="url(#logoGrad)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M2 12l10 5 10-5" stroke="url(#logoGrad)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
            <span className="font-display-xl text-[1.8rem] font-bold bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent tracking-tight">
              Sanchaya
            </span>
          </Link>
          {/* Navigation Links */}
          <ul className="flex items-center gap-8 text-[1rem] font-body-md">
            {NAV_LINKS.map((link) => {
              const active = isActive(link.href);
              return (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className={`${
                      active
                        ? 'text-primary border-b-2 border-primary pb-1'
                        : 'text-on-surface-variant hover:text-on-surface'
                    } transition-colors hover:bg-white/5 duration-300 px-3 py-2 rounded-md`}
                  >
                    {link.label}
                  </Link>
                </li>
              );
            })}
          </ul>
        </div>
        {/* Trailing Actions */}
        <div className="flex items-center gap-6">
          <div id="profile-menu-container" className="relative">
            {status === 'loading' ? (
              <div className="w-10 h-10 rounded-full bg-white/5 animate-pulse" />
            ) : (
              <div 
                className="w-10 h-10 rounded-full bg-surface-container-high border border-white/10 overflow-hidden cursor-pointer hover:border-primary/50 transition-colors"
                onClick={() => setDropdownOpen(!dropdownOpen)}
              >
                {session?.user?.image ? (
                  <img className="w-full h-full object-cover" src={session.user.image} alt="User Profile" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-on-surface-variant bg-surface-variant">
                    <User className="w-5 h-5" />
                  </div>
                )}
              </div>
            )}

            {dropdownOpen && (
              <div className="absolute right-0 mt-4 w-72 rounded-2xl bg-surface border border-white/10 shadow-2xl p-3 flex flex-col gap-2 z-50 transform origin-top-right transition-all">
                
                {/* Profile Header */}
                <div className="relative overflow-hidden rounded-2xl p-4 mb-2 group border border-white/5 bg-white/5">
                  <div className="absolute inset-0 bg-gradient-to-br from-primary/20 via-surface-variant/10 to-transparent opacity-50 group-hover:opacity-100 transition-opacity duration-500"></div>
                  <div className="relative flex items-center gap-4">
                    <div className="w-12 h-12 rounded-full border-2 border-primary/30 overflow-hidden bg-surface flex-shrink-0">
                      {session?.user?.image ? (
                         <img className="w-full h-full object-cover" src={session.user.image} alt="User Profile" />
                      ) : (
                         <div className="w-full h-full flex items-center justify-center text-primary bg-primary/10">
                           <User className="w-6 h-6" />
                         </div>
                      )}
                    </div>
                    <div className="flex flex-col min-w-0">
                      <p className="text-base font-bold text-on-surface truncate group-hover:text-primary transition-colors">
                        {session?.user ? session.user.name : guestName}
                      </p>
                      <p className="text-xs text-on-surface-variant truncate">
                        {session?.user ? session.user.email : 'Sign in to save list'}
                      </p>
                    </div>
                  </div>
                </div>

                {/* Menu Items */}
                <Link href="/settings" className="flex items-center gap-4 px-3 py-3 rounded-xl hover:bg-white/5 group transition-all" onClick={() => setDropdownOpen(false)}>
                  <div className="w-9 h-9 rounded-full bg-surface-variant/50 flex items-center justify-center group-hover:bg-primary/20 transition-colors shadow-inner border border-white/5">
                    <Settings className="w-[18px] h-[18px] text-on-surface-variant group-hover:text-primary transition-colors group-hover:rotate-45 duration-300" />
                  </div>
                  <span className="text-sm font-medium text-on-surface group-hover:translate-x-1 transition-transform">Preferences</span>
                </Link>
                
                <a href="https://github.com/VeerPalSingh-0000/Sanchaya" target="_blank" rel="noopener noreferrer" className="flex items-center justify-between px-3 py-3 rounded-xl hover:bg-[#2ea043]/10 group transition-all">
                  <div className="flex items-center gap-4">
                    <div className="w-9 h-9 rounded-full bg-surface-variant/50 flex items-center justify-center group-hover:bg-[#2ea043]/20 transition-colors shadow-inner border border-white/5">
                      <Star className="w-[18px] h-[18px] text-[#2ea043] group-hover:scale-110 transition-transform" />
                    </div>
                    <span className="text-sm font-medium text-on-surface group-hover:text-[#2ea043] group-hover:translate-x-1 transition-transform">Star on GitHub</span>
                  </div>
                  <ArrowRight className="w-4 h-4 text-on-surface-variant opacity-0 -translate-x-2 group-hover:translate-x-0 group-hover:opacity-100 transition-all" />
                </a>

                <a href="https://buymeacoffee.com/veerpalsingh" target="_blank" rel="noopener noreferrer" className="flex items-center justify-between px-3 py-3 rounded-xl hover:bg-[#FFDD00]/10 group transition-all">
                  <div className="flex items-center gap-4">
                    <div className="w-9 h-9 rounded-full bg-surface-variant/50 flex items-center justify-center group-hover:bg-[#FFDD00]/20 transition-colors shadow-inner border border-white/5">
                      <Coffee className="w-[18px] h-[18px] text-[#FFDD00] group-hover:-rotate-12 transition-transform" />
                    </div>
                    <span className="text-sm font-medium text-on-surface group-hover:text-[#FFDD00] group-hover:translate-x-1 transition-transform">Buy me a coffee</span>
                  </div>
                  <ArrowRight className="w-4 h-4 text-on-surface-variant opacity-0 -translate-x-2 group-hover:translate-x-0 group-hover:opacity-100 transition-all" />
                </a>
                
                <div className="h-px w-full bg-gradient-to-r from-transparent via-white/10 to-transparent my-1"></div>
                
                {session ? (
                  <button 
                    className="flex items-center gap-4 px-3 py-3 rounded-xl hover:bg-error/10 group transition-all text-left w-full" 
                    onClick={() => { setDropdownOpen(false); signOut(); }}
                  >
                    <div className="w-9 h-9 rounded-full bg-surface-variant/50 flex items-center justify-center group-hover:bg-error/20 transition-colors shadow-inner border border-white/5">
                      <LogOut className="w-[18px] h-[18px] text-error group-hover:-translate-x-1 transition-transform" />
                    </div>
                    <span className="text-sm font-medium text-error group-hover:translate-x-1 transition-transform">Sign Out</span>
                  </button>
                ) : (
                  <button 
                    className="flex items-center gap-4 px-3 py-3 rounded-xl bg-primary/10 hover:bg-primary/20 group transition-all text-left w-full border border-primary/20 hover:border-primary/40 shadow-[0_0_15px_rgba(255,193,116,0.1)]" 
                    onClick={() => { setDropdownOpen(false); signIn(); }}
                  >
                    <div className="w-9 h-9 rounded-full bg-primary/20 flex items-center justify-center group-hover:bg-primary/30 transition-colors shadow-inner">
                      <LogIn className="w-[18px] h-[18px] text-primary group-hover:translate-x-1 transition-transform" />
                    </div>
                    <span className="text-sm font-bold text-primary group-hover:translate-x-1 transition-transform">Sign In</span>
                  </button>
                )}
              </div>
            )}
          </div>
        </div>
      </nav>

      {/* BottomNavBar (Mobile) */}
      {(!(!session && pathname === '/') && pathname !== '/auth/signin') && (
        <nav className="md:hidden fixed bottom-0 left-0 right-0 z-50 bg-[#0a0f18]/95 backdrop-blur-3xl border-t border-white/10 pb-[env(safe-area-inset-bottom)] pointer-events-auto shadow-[0_-8px_32px_rgba(0,0,0,0.5)]">
          <div className="flex items-center justify-around w-full h-16 px-2">
            {NAV_LINKS.map((link) => {
              const active = isActive(link.href);
              return (
                <Link 
                  key={link.href}
                  href={link.href}
                  className={`flex flex-col items-center justify-center gap-1 w-full h-full transition-colors duration-300 ${
                    active 
                      ? 'text-primary' 
                      : 'text-white/40 hover:text-white/80'
                  }`}
                >
                  <link.icon className={`w-5 h-5 ${active ? 'fill-current' : ''}`} />
                  <span className={`text-[10px] tracking-wide ${active ? 'font-bold' : 'font-medium'}`}>
                    {link.label}
                  </span>
                </Link>
              )
            })}
          </div>
        </nav>
      )}
    </>
  );
}
