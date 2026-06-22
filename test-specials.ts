import { getAnimeSeasons } from './src/lib/anilist';

async function anilistFetch(query: string, variables: any) {
  const res = await fetch('https://graphql.anilist.co', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query, variables })
  });
  const json = await res.json();
  return json.data;
}

const gql = `
query GetAnimeSeasons($id: Int!) {
  Media(id: $id, type: ANIME) {
    id
    title { romaji }
    relations {
      edges {
        relationType
        node {
          id
          title { romaji }
        }
      }
    }
  }
}
`;

async function test() {
  const data = await anilistFetch(gql, { id: 163327 }); // Specials
  console.log("Specials (163327) relations:");
  for (const edge of data.Media.relations.edges) {
    console.log(`- ${edge.relationType} -> ${edge.node.title.romaji} (${edge.node.id})`);
  }
}

test().catch(console.error);
