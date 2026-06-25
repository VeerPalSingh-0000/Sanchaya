const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  const items = await prisma.watchlistItem.findMany({ where: { mediaType: 'anime' } });
  const quintuplets = items.filter(i => i.title.includes('Quintuplets') || i.title.includes('Gotoubun'));
  console.log(quintuplets.map(i => ({
    id: i.id,
    mediaId: i.mediaId,
    title: i.title,
    franchiseId: i.franchiseId,
    franchiseTitle: i.franchiseTitle
  })));
  await prisma.$disconnect();
}
run();
