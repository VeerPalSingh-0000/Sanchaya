const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  const items = await prisma.watchlistItem.findMany({ take: 10 });
  console.log(JSON.stringify(items, null, 2));
}
main().catch(console.error).finally(() => prisma.$disconnect());
