import { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000';

  // We are returning static pages for now.
  // In a real production app with many movies, you'd fetch the latest/top movies
  // from your DB/API and map them to sitemap entries here.
  return [
    {
      url: `${baseUrl}`,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    {
      url: `${baseUrl}/discover`,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 0.8,
    },
    {
      url: `${baseUrl}/watchlist`,
      lastModified: new Date(),
      changeFrequency: 'always',
      priority: 0.5,
    },
    {
      url: `${baseUrl}/recommendations`,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 0.5,
    },
  ];
}
