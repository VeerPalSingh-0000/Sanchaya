import { NextResponse } from 'next/server'
import { auth } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function PATCH(req: Request, props: { params: Promise<{ id: string }> }) {
  const params = await props.params
  const session = await auth()
  if (!session?.user?.id) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const body = await req.json()
    const { status, rating, notes, progress, totalEpisodes, reaction } = body

    await prisma.watchlistItem.updateMany({
      where: {
        mediaId: params.id,
        userId: session.user.id,
      },
      data: {
        ...(status && { status }),
        ...(rating !== undefined && { rating }),
        ...(notes !== undefined && { notes }),
        ...(progress !== undefined && { progress }),
        ...(totalEpisodes !== undefined && { totalEpisodes }),
        ...(reaction !== undefined && { reaction }),
      }
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update item' }, { status: 500 })
  }
}

export async function DELETE(req: Request, props: { params: Promise<{ id: string }> }) {
  const params = await props.params
  const session = await auth()
  if (!session?.user?.id) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    await prisma.watchlistItem.deleteMany({
      where: {
        mediaId: params.id,
        userId: session.user.id,
      }
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to delete item' }, { status: 500 })
  }
}
