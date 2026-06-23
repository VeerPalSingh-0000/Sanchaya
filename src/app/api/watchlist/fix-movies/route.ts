import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getMovieDetails } from '@/lib/tmdb';

export async function GET() {
  try {
    console.log("Fetching all movies from DB to fix collections...");
    const movies = await prisma.watchlistItem.findMany({
      where: { mediaType: 'movie', franchiseId: null }
    });

    console.log(`Found ${movies.length} movies to process.`);
    let updatedCount = 0;

    for (const item of movies) {
      // getMovieDetails handles replacing the tmdb-movie- prefix internally
      const details = await getMovieDetails(item.mediaId);
      
      if (details && details.franchiseId) {
        await prisma.watchlistItem.update({
          where: { id: item.id },
          data: {
            franchiseId: details.franchiseId,
            franchiseTitle: details.franchiseTitle,
            franchisePosterUrl: details.franchisePosterUrl
          }
        });
        updatedCount++;
      }
      
      // small delay to respect rate limit
      await new Promise(r => setTimeout(r, 100));
    }

    return NextResponse.json({ success: true, updatedCount });
  } catch (error: any) {
    console.error("Fix Movies Error:", error);
    return NextResponse.json({ success: false, error: String(error) }, { status: 500 });
  }
}
