'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useSession, signIn, signOut } from 'next-auth/react';

const NAV_LINKS = [
  { href: '/', label: 'Movies', icon: 'home' },
  { href: '/watchlist', label: 'My List', icon: 'subscriptions' },
  { href: '/discover', label: 'Discover', icon: 'search' },
] as const;

export default function Navbar() {
  const pathname = usePathname();
  const { data: session } = useSession();
  const [dropdownOpen, setDropdownOpen] = useState(false);

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
      {/* TopNavBar (Desktop) */}
      <nav className="hidden md:flex sticky top-0 z-50 justify-between items-center px-margin-desktop py-4 w-full bg-surface/40 backdrop-blur-xl border-b border-white/10 shadow-2xl shadow-primary/5">
        <div className="flex items-center gap-12">
          {/* Brand */}
          <Link href="/" className="font-display-xl text-[2rem] font-bold bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
            CINEVERSE
          </Link>
          {/* Navigation Links */}
          <ul className="flex items-center gap-8 font-headline-lg text-[1rem] font-body-md">
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
              <div className="absolute right-0 mt-3 w-64 rounded-2xl bg-surface-container-high/95 backdrop-blur-3xl border border-white/10 shadow-[0_20px_40px_rgba(0,0,0,0.8)] p-2 flex flex-col gap-1 z-50 transform origin-top-right transition-all">
                {session?.user ? (
                  <div className="px-4 py-4 border-b border-white/10 mb-2 bg-gradient-to-br from-primary/10 to-transparent rounded-t-xl">
                    <p className="text-sm font-bold text-on-surface">{session.user.name}</p>
                    <p className="text-xs text-on-surface-variant truncate">{session.user.email}</p>
                  </div>
                ) : (
                  <div className="px-4 py-4 border-b border-white/10 mb-2 flex items-center gap-3 bg-gradient-to-br from-surface-variant/50 to-transparent rounded-t-xl">
                    <div className="w-10 h-10 rounded-full bg-surface-variant flex items-center justify-center">
                      <span className="material-symbols-outlined text-[20px] text-on-surface-variant">person</span>
                    </div>
                    <div>
                      <p className="text-sm font-bold text-on-surface">Guest User</p>
                      <p className="text-xs text-on-surface-variant">Sign in to save list</p>
                    </div>
                  </div>
                )}
                
                <Link href="/settings" className="flex items-center gap-3 px-4 py-3 text-sm text-on-surface hover:bg-white/10 rounded-xl transition-all hover:pl-5" onClick={() => setDropdownOpen(false)}>
                  <span className="material-symbols-outlined text-[18px] text-primary">settings</span>
                  Preferences
                </Link>
                
                <a href="https://github.com/VeerPalSingh-0000/Sanchaya" target="_blank" rel="noopener noreferrer" className="flex items-center justify-between px-4 py-3 text-sm text-on-surface hover:bg-white/10 rounded-xl transition-all hover:pl-5">
                  <div className="flex items-center gap-3">
                    <span className="material-symbols-outlined text-[18px] text-[#2ea043]">star</span>
                    Star on GitHub
                  </div>
                  <span className="material-symbols-outlined text-[14px] text-on-surface-variant">open_in_new</span>
                </a>

                <a href="https://buymeacoffee.com/veerpalsingh" target="_blank" rel="noopener noreferrer" className="flex items-center justify-between px-4 py-3 text-sm text-on-surface hover:bg-[#FFDD00]/10 rounded-xl transition-all hover:pl-5">
                  <div className="flex items-center gap-3">
                    <span className="material-symbols-outlined text-[18px] text-[#FFDD00]">local_cafe</span>
                    Buy me a coffee
                  </div>
                  <span className="material-symbols-outlined text-[14px] text-on-surface-variant">open_in_new</span>
                </a>
                
                <div className="border-b border-white/10 my-1"></div>
                
                {session ? (
                  <button 
                    className="flex items-center gap-3 px-4 py-3 text-sm text-error hover:bg-error/10 rounded-xl transition-all hover:pl-5 text-left" 
                    onClick={() => { setDropdownOpen(false); signOut(); }}
                  >
                    <span className="material-symbols-outlined text-[18px]">logout</span>
                    Sign Out
                  </button>
                ) : (
                  <button 
                    className="flex items-center gap-3 px-4 py-3 text-sm text-primary hover:bg-primary/10 rounded-xl transition-all hover:pl-5 text-left font-bold" 
                    onClick={() => { setDropdownOpen(false); signIn(); }}
                  >
                    <span className="material-symbols-outlined text-[18px]">login</span>
                    Sign In
                  </button>
                )}
              </div>
            )}
          </div>
        </div>
      </nav>

      {/* BottomNavBar (Mobile) */}
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
    </>
  );
}
