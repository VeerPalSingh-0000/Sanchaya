import { getTVDetails } from './src/lib/tmdb';

async function test() {
  const media = await getTVDetails('1429');
  console.log('originCountry:', media?.originCountry);
  console.log('genres:', media?.genres.map(g => g.name));
}

test().catch(console.error);
