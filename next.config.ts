import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactCompiler: true,
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'image.tmdb.org',
        pathname: '/t/p/**',
      },
      {
        protocol: 'https',
        hostname: 's4.anilist.co',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'img.anili.st',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'wsrv.nl',
        pathname: '/**',
      },
    ],
  },
};

export default nextConfig;
