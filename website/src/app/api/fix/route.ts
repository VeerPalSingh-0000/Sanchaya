import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    // Reset all franchise IDs for anime to force a clean grouping on next reload
    const updated = await prisma.watchlistItem.updateMany({
      where: { mediaType: 'anime' },
      data: { franchiseId: null, franchiseTitle: null, franchisePosterUrl: null }
    });

    return NextResponse.json({ success: true, message: `Successfully reset franchise groups for ${updated.count} anime.` });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }
}
