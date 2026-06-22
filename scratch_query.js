const query = `
query GetAnimeSeasons($id: Int!) {
  Media(id: $id, type: ANIME) {
    id
    title { english }
    relations {
      edges {
        relationType
        node {
          id
          title { english }
          relations {
            edges {
              relationType
              node {
                id
                title { english }
                relations {
                  edges {
                    relationType
                    node {
                      id
                      title { english }
                      relations {
                        edges {
                          relationType
                          node {
                            id
                            title { english }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}`;

fetch('https://graphql.anilist.co', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ query, variables: { id: 16498 } })
})
.then(r => r.json())
.then(d => console.log(JSON.stringify(d).substring(0, 500)));
