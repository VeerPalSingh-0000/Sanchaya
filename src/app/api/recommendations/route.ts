import { NextResponse } from 'next/server'
import { auth } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getMovieDetails, getTVDetails, discoverByGenres, getTrending, getTmdbGenreIdByName } from '@/lib/tmdb'
import { getAnimeDetails, discoverAnimeByGenres, getTrendingAnime } from '@/lib/anilist'
import type { Media, RecommendationResult } from '@/types/media'

export async function GET() {
  const session = await auth()
  if (!session?.user?.id) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    // 1. Get all items to build exclude list and analyze types
    const allItems = await prisma.watchlistItem.findMany({
      where: { userId: session.user.id },
      select: { mediaId: true, mediaType: true, status: true, rating: true, updatedAt: true, reaction: true },
      orderBy: [
        { rating: 'desc' },
        { updatedAt: 'desc' }
      ]
    })

    const excludeIds = allItems.map(item => item.mediaId)

    // Analyze media types
    const counts = { movie: 0, series: 0, anime: 0 }
    allItems.forEach(item => {
      counts[item.mediaType as keyof typeof counts]++
    })

    // 2. Select top seed items (completed or highly rated, or explicitly loved/good)
    const seedItems = allItems
      .filter(item => item.reaction === 'LOVE' || item.reaction === 'GOOD' || item.status === 'completed' || (item.rating && item.rating >= 7))
      .filter(item => item.reaction !== 'BAD') // Don't use BAD items as positive seeds
      .slice(0, 10)
    
    // Also select some 'BAD' items to penalize their genres
    const badItems = allItems.filter(item => item.reaction === 'BAD').slice(0, 5)
    
    // Fallback if no highly rated/completed items: just take the most recently added ones
    const itemsToFetch = seedItems.length > 0 ? seedItems : allItems.filter(item => item.reaction !== 'BAD').slice(0, 10)

    // If still no items, return trending as fallback
    if (itemsToFetch.length === 0) {
      const [movies, series, anime] = await Promise.all([
        getTrending('movie'),
        getTrending('tv'),
        getTrendingAnime()
      ])
      
      const fallbackResults: RecommendationResult[] = [
        ...movies.slice(0, 5),
        ...series.slice(0, 5),
        ...anime.slice(0, 5)
      ].map(media => ({
        media,
        matchedGenres: [],
        matchScore: 0,
        reason: 'Trending now'
      }))
      
      // Shuffle fallback results
      fallbackResults.sort(() => Math.random() - 0.5)
      return NextResponse.json({ results: fallbackResults, topGenres: [] })
    }

    // 3. Fetch details for seed items to extract genres
    const detailPromises = itemsToFetch.map(item => {
      if (item.mediaType === 'movie') return getMovieDetails(item.mediaId)
      if (item.mediaType === 'series') return getTVDetails(item.mediaId)
      if (item.mediaType === 'anime') return getAnimeDetails(`anilist-${item.mediaId}`)
      return null
    })

    const detailedMedia = (await Promise.all(detailPromises)).filter(Boolean) as Media[]
    
    // Fetch details for BAD items to penalize
    const badDetailPromises = badItems.map(item => {
      if (item.mediaType === 'movie') return getMovieDetails(item.mediaId)
      if (item.mediaType === 'series') return getTVDetails(item.mediaId)
      if (item.mediaType === 'anime') return getAnimeDetails(`anilist-${item.mediaId}`)
      return null
    })
    const badDetailedMedia = (await Promise.all(badDetailPromises)).filter(Boolean) as Media[]

    // 4. Calculate genre weights
    const genreWeights: Record<string, number> = {}
    detailedMedia.forEach(media => {
      const dbItem = itemsToFetch.find(i => i.mediaId === media.externalId)
      let weight = dbItem?.rating || 7 // Default weight
      if (dbItem?.reaction === 'LOVE') weight = 15;
      if (dbItem?.reaction === 'GOOD') weight = 10;
      
      media.genres.forEach(genre => {
        genreWeights[genre.name] = (genreWeights[genre.name] || 0) + weight
      })
    })

    // Subtract weights for BAD items
    badDetailedMedia.forEach(media => {
      media.genres.forEach(genre => {
        // Penalize genres that appear in bad items
        genreWeights[genre.name] = (genreWeights[genre.name] || 0) - 10
      })
    })

    // 5. Select top genres (must have positive weight)
    const sortedGenres = Object.entries(genreWeights)
      .filter(entry => entry[1] > 0)
      .sort((a, b) => b[1] - a[1])
      .map(entry => entry[0])
    
    const topGenres = sortedGenres.slice(0, 4)
    
    if (topGenres.length === 0) {
      return NextResponse.json({ error: 'Not enough data to generate recommendations' }, { status: 400 })
    }

    // Map to TMDb IDs
    const tmdbGenreIds = topGenres
      .map(getTmdbGenreIdByName)
      .filter((id): id is number => id !== undefined)

    // 6. Discover by genres
    // Proportional requests based on user's watchlist composition
    const totalItems = allItems.length || 1
    const movieRatio = counts.movie / totalItems
    const seriesRatio = counts.series / totalItems
    const animeRatio = counts.anime / totalItems

    const fetchPromises = []
    
    if (movieRatio > 0.1 || counts.movie > 0) {
      fetchPromises.push(discoverByGenres('movie', tmdbGenreIds, 1, excludeIds))
    }
    if (seriesRatio > 0.1 || counts.series > 0) {
      fetchPromises.push(discoverByGenres('tv', tmdbGenreIds, 1, excludeIds))
    }
    if (animeRatio > 0.1 || counts.anime > 0) {
      fetchPromises.push(discoverAnimeByGenres(topGenres, 1, excludeIds))
    }

    // Default to all if everything is 0 (shouldn't happen with the check above, but safe)
    if (fetchPromises.length === 0) {
      fetchPromises.push(
        discoverByGenres('movie', tmdbGenreIds, 1, excludeIds),
        discoverByGenres('tv', tmdbGenreIds, 1, excludeIds),
        discoverAnimeByGenres(topGenres, 1, excludeIds)
      )
    }

    const searchResults = await Promise.all(fetchPromises)
    
    // 7. Aggregate and score results
    let recommendedMedia: Media[] = []
    searchResults.forEach(result => {
      if (result && result.results) {
        recommendedMedia = [...recommendedMedia, ...result.results]
      }
    })

    // Score based on how many top genres match
    const scoredResults: RecommendationResult[] = recommendedMedia.map(media => {
      const mediaGenreNames = media.genres.map(g => g.name)
      const matchedGenres = topGenres.filter(g => mediaGenreNames.includes(g))
      const matchScore = matchedGenres.length * 10 + (media.rating || 0)
      
      const reason = matchedGenres.length > 0 
        ? `Because you enjoy ${matchedGenres.join(' and ')}`
        : `Recommended based on your watchlist`

      return {
        media,
        matchedGenres,
        matchScore,
        reason
      }
    })

    // Remove duplicates just in case
    const uniqueResults = []
    const seenIds = new Set()
    for (const res of scoredResults) {
      if (!seenIds.has(res.media.externalId)) {
        seenIds.add(res.media.externalId)
        uniqueResults.push(res)
      }
    }

    // Sort by match score and return top 60
    const finalResults = uniqueResults
      .sort((a, b) => b.matchScore - a.matchScore)
      .slice(0, 60)

    return NextResponse.json({
      results: finalResults,
      topGenres
    })
  } catch (error) {
    console.error('Recommendation Engine Error:', error)
    return NextResponse.json({ error: 'Failed to generate recommendations' }, { status: 500 })
  }
}
