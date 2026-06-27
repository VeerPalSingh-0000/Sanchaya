const fetch = require('node-fetch') || globalThis.fetch;

async function anilistFetch(query, variables = {}, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const res = await fetch("https://graphql.anilist.co", {
        method: "POST",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({ query, variables })
      });
      if (!res.ok) throw new Error("bad status: " + res.status);
      const json = await res.json();
      return json.data;
    } catch (err) {
      if (i === retries - 1) throw err;
    }
  }
}

function resolveTitle(title) {
  return title.english ?? title.romaji ?? title.native ?? "Unknown";
}

async function getAnimeSeasons(id) {
  const timelineNodeFragment = `fragment TimelineNode on Media { id title { romaji english native } type format coverImage { extraLarge large medium color } bannerImage episodes averageScore startDate { year month day } }`;
  const gql = `${timelineNodeFragment} query GetTimelineNode($id: Int!) { Media(id: $id, type: ANIME) { ...TimelineNode relations { edges { relationType node { id type } } } } }`;
  const relationsQuery = `${timelineNodeFragment} query GetRelations($id_in: [Int]) { Page(page: 1, perPage: 50) { media(id_in: $id_in, type: ANIME) { ...TimelineNode relations { edges { relationType node { id type } } } } } }`;

  const numericId = parseInt(String(id).replace(/\D/g, ""), 10);
  const validRelationTypes = ["CURRENT", "SEQUEL", "PREQUEL", "SIDE_STORY", "PARENT", "ALTERNATIVE", "SPIN_OFF", "ADAPTATION", "SUMMARY"];

  const allNodesMap = new Map();
  const queue = [];
  const visited = new Set();

  const initialData = await anilistFetch(gql, { id: numericId });
  const rootMedia = initialData.Media;
  if (!rootMedia) return [];

  allNodesMap.set(rootMedia.id, { ...rootMedia, relationType: "CURRENT" });
  visited.add(rootMedia.id);

  const initialRelations = rootMedia.relations?.edges || [];
  for (const edge of initialRelations) {
    if (edge.node.type === "ANIME" && validRelationTypes.includes(edge.relationType) && !visited.has(edge.node.id)) {
      queue.push({ id: edge.node.id, relType: edge.relationType });
    }
  }

  while (queue.length > 0) {
    const batch = queue.splice(0, 50);
    const batchIds = batch.map((item) => item.id);
    batchIds.forEach((id) => visited.add(id));

    const batchData = await anilistFetch(relationsQuery, { id_in: batchIds });
    const mediaItems = batchData.Page?.media || [];

    for (const media of mediaItems) {
      const queuedItem = batch.find((b) => b.id === media.id);
      const actualRelation = queuedItem ? queuedItem.relType : "SEQUEL";

      if (!allNodesMap.has(media.id)) {
        allNodesMap.set(media.id, { ...media, relationType: actualRelation });
      }

      const relations = media.relations?.edges || [];
      for (const edge of relations) {
        if (edge.node.type === "ANIME" && validRelationTypes.includes(edge.relationType) && !visited.has(edge.node.id)) {
          queue.push({ id: edge.node.id, relType: edge.relationType });
        }
      }
    }
  }

  const allMediaInTimeline = Array.from(allNodesMap.values());
  const validMedia = allMediaInTimeline.filter((node) => validRelationTypes.includes(node.relationType));

  const sortedMedia = validMedia.sort((a, b) => {
    const dateA = a.startDate?.year ? new Date(a.startDate.year, (a.startDate.month || 1) - 1, a.startDate.day || 1).getTime() : Infinity;
    const dateB = b.startDate?.year ? new Date(b.startDate.year, (b.startDate.month || 1) - 1, b.startDate.day || 1).getTime() : Infinity;
    if (dateA !== dateB) return dateA - dateB;
    return a.id - b.id;
  });

  return sortedMedia.map(m => m.id + ' (' + m.format + ')' + ' - ' + resolveTitle(m.title));
}

(async () => {
  console.log("For 11061:");
  console.log(await getAnimeSeasons(11061));
  console.log("For 136:");
  console.log(await getAnimeSeasons(136));
})();
