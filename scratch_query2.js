const query = `
query GetAnimeSeasons {
  Media(id: 53390, type: MANGA) {
    id
    title { english }
    relations {
      edges {
        relationType
        node {
          id
          title { english }
          type
        }
      }
    }
  }
}`;

fetch('https://graphql.anilist.co', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ query })
})
.then(r => r.json())
.then(d => console.log(JSON.stringify(d, null, 2)));
