const query = `query { Media(id: 11061, type: ANIME) { relations { edges { relationType node { id type title { romaji } } } } } }`;
fetch('https://graphql.anilist.co', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ query })
}).then(res => res.json()).then(res => console.log(JSON.stringify(res, null, 2)));
