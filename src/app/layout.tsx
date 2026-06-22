import type { Metadata } from 'next';
import { Inter, Outfit } from 'next/font/google';
import Navbar from '@/components/layout/Navbar';
import Footer from '@/components/layout/Footer';
import { ToastProvider } from '@/components/ui/Toast';
import { WatchlistProvider } from '@/lib/contexts/WatchlistContext';
import { NextAuthProvider } from '@/components/providers/SessionProvider';
import '@/styles/globals.css';

const inter = Inter({
  subsets: ['latin'],
  weight: ['400', '500', '600', '700'],
  variable: '--font-inter',
  display: 'swap',
});

const outfit = Outfit({
  subsets: ['latin'],
  weight: ['600', '700'],
  variable: '--font-outfit',
  display: 'swap',
});

export const metadata: Metadata = {
  title: 'Sanchaya | Your Unified Media Tracker',
  description:
    'Track your favorite movies, TV series, and anime all in one place. Discover, rate, and organize your watchlist with Sanchaya.',
  keywords: ['media tracker', 'movies', 'anime', 'tv series', 'watchlist'],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${inter.variable} ${outfit.variable}`} data-scroll-behavior="smooth">
      <head>
        <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined" rel="stylesheet" />
      </head>
      <body className="bg-background text-on-background antialiased selection:bg-primary/30 selection:text-primary-container min-h-screen flex flex-col">
        <NextAuthProvider>
          <ToastProvider>
            <WatchlistProvider>
              <Navbar />
              <main className="flex-grow">{children}</main>
              <Footer />
            </WatchlistProvider>
          </ToastProvider>
        </NextAuthProvider>
      </body>
    </html>
  );
}
