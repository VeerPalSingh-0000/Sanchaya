'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useSession, signIn, signOut } from 'next-auth/react';

const NAV_LINKS = [
  { href: '/', label: 'Home', icon: 'home' },
  { href: '/watchlist', label: 'My List', icon: 'subscriptions' },
  { href: '/discover', label: 'Discover', icon: 'explore' },
] as const;

export default function Navbar() {
  const pathname = usePathname();
  const { data: session } = useSession();
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [guestName, setGuestName] = useState('Guest User');

  useEffect(() => {
    if (!session) {
      const savedName = localStorage.getItem('sanchaya_guest_name');
      if (savedName) {
        setGuestName(savedName);
      }
    }
  }, [session]);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (!(event.target as Element).closest('#profile-menu-container')) {
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
        {!session ? (
          <button 
            onClick={() => signIn()}
            className="text-sm font-semibold bg-primary text-black px-4 py-1.5 rounded-full hover:bg-primary/90 transition-colors"
          >
            Sign In
          </button>
        ) : (
          <Link href="/settings">
            <div className="w-8 h-8 rounded-full bg-surface-container border border-white/10 overflow-hidden">
              {session.user?.image ? (
                <img className="w-full h-full object-cover" src={session.user.image} alt="Profile" />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-primary bg-primary/10">
                  <span className="material-symbols-outlined text-[16px]">person</span>
                </div>
              )}
            </div>
          </Link>
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
            <div 
              className="w-10 h-10 rounded-full bg-surface-container-high border border-white/10 overflow-hidden cursor-pointer hover:border-primary/50 transition-colors"
              onClick={() => setDropdownOpen(!dropdownOpen)}
            >
              {session?.user?.image ? (
                <img className="w-full h-full object-cover" src={session.user.image} alt="User Profile" />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-on-surface-variant bg-surface-variant">
                  <span className="material-symbols-outlined text-[20px]">person</span>
                </div>
              )}
            </div>

            {dropdownOpen && (
              <div className="absolute right-0 mt-4 w-72 rounded-3xl bg-[#0a0f18]/80 backdrop-blur-2xl border border-white/10 shadow-[0_0_40px_rgba(255,193,116,0.15)] p-3 flex flex-col gap-2 z-50 transform origin-top-right transition-all">
                
                {/* Profile Header */}
                <div className="relative overflow-hidden rounded-2xl p-4 mb-2 group border border-white/5 bg-white/5">
                  <div className="absolute inset-0 bg-gradient-to-br from-primary/20 via-surface-variant/10 to-transparent opacity-50 group-hover:opacity-100 transition-opacity duration-500"></div>
                  <div className="relative flex items-center gap-4">
                    <div className="w-12 h-12 rounded-full border-2 border-primary/30 overflow-hidden bg-surface flex-shrink-0">
                      {session?.user?.image ? (
                         <img className="w-full h-full object-cover" src={session.user.image} alt="User Profile" />
                      ) : (
                         <div className="w-full h-full flex items-center justify-center text-primary bg-primary/10">
                           <span className="material-symbols-outlined text-[24px]">person</span>
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
                    <span className="material-symbols-outlined text-[18px] text-on-surface-variant group-hover:text-primary transition-colors group-hover:rotate-45 duration-300">settings</span>
                  </div>
                  <span className="text-sm font-medium text-on-surface group-hover:translate-x-1 transition-transform">Preferences</span>
                </Link>
                
                <a href="https://github.com/VeerPalSingh-0000/Sanchaya" target="_blank" rel="noopener noreferrer" className="flex items-center justify-between px-3 py-3 rounded-xl hover:bg-[#2ea043]/10 group transition-all">
                  <div className="flex items-center gap-4">
                    <div className="w-9 h-9 rounded-full bg-surface-variant/50 flex items-center justify-center group-hover:bg-[#2ea043]/20 transition-colors shadow-inner border border-white/5">
                      <span className="material-symbols-outlined text-[18px] text-[#2ea043] group-hover:scale-110 transition-transform">star</span>
                    </div>
                    <span className="text-sm font-medium text-on-surface group-hover:text-[#2ea043] group-hover:translate-x-1 transition-transform">Star on GitHub</span>
                  </div>
                  <span className="material-symbols-outlined text-[16px] text-on-surface-variant opacity-0 -translate-x-2 group-hover:translate-x-0 group-hover:opacity-100 transition-all">arrow_forward</span>
                </a>

                <a href="https://buymeacoffee.com/veerpalsingh" target="_blank" rel="noopener noreferrer" className="flex items-center justify-between px-3 py-3 rounded-xl hover:bg-[#FFDD00]/10 group transition-all">
                  <div className="flex items-center gap-4">
                    <div className="w-9 h-9 rounded-full bg-surface-variant/50 flex items-center justify-center group-hover:bg-[#FFDD00]/20 transition-colors shadow-inner border border-white/5">
                      <span className="material-symbols-outlined text-[18px] text-[#FFDD00] group-hover:-rotate-12 transition-transform">local_cafe</span>
                    </div>
                    <span className="text-sm font-medium text-on-surface group-hover:text-[#FFDD00] group-hover:translate-x-1 transition-transform">Buy me a coffee</span>
                  </div>
                  <span className="material-symbols-outlined text-[16px] text-on-surface-variant opacity-0 -translate-x-2 group-hover:translate-x-0 group-hover:opacity-100 transition-all">arrow_forward</span>
                </a>
                
                <div className="h-px w-full bg-gradient-to-r from-transparent via-white/10 to-transparent my-1"></div>
                
                {session ? (
                  <button 
                    className="flex items-center gap-4 px-3 py-3 rounded-xl hover:bg-error/10 group transition-all text-left w-full" 
                    onClick={() => { setDropdownOpen(false); signOut(); }}
                  >
                    <div className="w-9 h-9 rounded-full bg-surface-variant/50 flex items-center justify-center group-hover:bg-error/20 transition-colors shadow-inner border border-white/5">
                      <span className="material-symbols-outlined text-[18px] text-error group-hover:-translate-x-1 transition-transform">logout</span>
                    </div>
                    <span className="text-sm font-medium text-error group-hover:translate-x-1 transition-transform">Sign Out</span>
                  </button>
                ) : (
                  <button 
                    className="flex items-center gap-4 px-3 py-3 rounded-xl bg-primary/10 hover:bg-primary/20 group transition-all text-left w-full border border-primary/20 hover:border-primary/40 shadow-[0_0_15px_rgba(255,193,116,0.1)]" 
                    onClick={() => { setDropdownOpen(false); signIn(); }}
                  >
                    <div className="w-9 h-9 rounded-full bg-primary/20 flex items-center justify-center group-hover:bg-primary/30 transition-colors shadow-inner">
                      <span className="material-symbols-outlined text-[18px] text-primary group-hover:translate-x-1 transition-transform">login</span>
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
      {(!(!session && pathname === '/')) && (
        <nav className="md:hidden fixed bottom-6 left-0 right-0 z-50 flex justify-around items-center px-4 pointer-events-none">
          <div className="bg-surface-container/60 backdrop-blur-lg rounded-full w-full max-w-sm mx-auto border border-white/10 shadow-[0_20px_40px_rgba(0,0,0,0.5)] flex justify-around items-center p-2 font-label-sm text-label-sm pointer-events-auto">
          {NAV_LINKS.map((link) => {
            const active = isActive(link.href);
            return (
              <Link 
                key={link.href}
                href={link.href}
                className={`flex flex-col items-center justify-center p-3 rounded-full transition-all active:scale-90 ${
                  active 
                    ? 'bg-primary-container text-on-primary-container animate-bounce-short' 
                    : 'text-on-surface-variant hover:bg-white/10'
                }`}
              >
                <span className="material-symbols-outlined mb-1 text-[20px]" style={active ? { fontVariationSettings: "'FILL' 1" } : {}}>
                  {link.icon}
                </span>
                <span>{link.label}</span>
              </Link>
            )
          })}
          
          <Link 
             href="/settings"
             className={`flex flex-col items-center justify-center p-3 rounded-full transition-all active:scale-90 ${
               isActive('/settings') 
                 ? 'bg-primary-container text-on-primary-container animate-bounce-short' 
                 : 'text-on-surface-variant hover:bg-white/10'
             }`}
          >
            <span className="material-symbols-outlined mb-1 text-[20px]" style={isActive('/settings') ? { fontVariationSettings: "'FILL' 1" } : {}}>
              person
            </span>
            <span>Profile</span>
          </Link>
        </div>
      </nav>
      )}
    </>
  );
}
