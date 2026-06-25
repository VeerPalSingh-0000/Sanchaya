import { NextResponse } from 'next/server'
import { auth } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function GET() {
  const session = await auth()
  if (!session?.user?.id) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const items = await prisma.watchlistItem.findMany({
      where: { userId: session.user.id },
      orderBy: { updatedAt: 'desc' },
    })
    return NextResponse.json(items)
  } catch (error: any) {
    console.error("Watchlist API GET Error:", error);
    return NextResponse.json({ error: 'Failed to fetch watchlist', details: error?.message || String(error) }, { status: 500 })
  }
}

export async function POST(req: Request) {
  const session = await auth()
  if (!session?.user?.id) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const body = await req.json()
    const { mediaId, mediaType, title, posterPath, status, rating, notes, franchiseId, franchiseTitle, franchisePosterUrl, progress, totalEpisodes } = body

    if (!mediaId || !mediaType || !title || !status) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
    }

    const item = await prisma.watchlistItem.upsert({
      where: {
        userId_mediaId_mediaType: {
          userId: session.user.id,
          mediaId: String(mediaId),
          mediaType: String(mediaType),
        }
      },
      update: {
        status,
        rating,
        notes,
        posterPath,
        franchiseId,
        franchiseTitle,
        franchisePosterUrl,
        progress,
        totalEpisodes,
      },
      create: {
        userId: session.user.id,
        mediaId: String(mediaId),
        mediaType: String(mediaType),
        title,
        posterPath,
        status,
        rating,
        notes,
        franchiseId,
        franchiseTitle,
        franchisePosterUrl,
        progress,
        totalEpisodes,
      }
    })

    return NextResponse.json(item)
  } catch (error) {
    console.error(error)
    return NextResponse.json({ error: 'Failed to add to watchlist' }, { status: 500 })
  }
}
