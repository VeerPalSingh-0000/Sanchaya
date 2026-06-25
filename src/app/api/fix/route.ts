import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    const deleted = await prisma.watchlistItem.deleteMany({
      where: {
        mediaId: {
          contains: 'undefined'
        }
      }
    })
    return NextResponse.json({ success: true, message: `Deleted ${deleted.count} corrupted items from the database.` })
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 })
  }
}
