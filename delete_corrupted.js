const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const deleted = await prisma.watchlistItem.deleteMany({
      where: {
        mediaId: 'tmdb-movie-undefined'
      }
    });
    console.log(`Deleted ${deleted.count} corrupted items from watchlist.`);
  } catch (e) {
    console.error(e);
  } finally {
    await prisma.$disconnect();
  }
}

main();
