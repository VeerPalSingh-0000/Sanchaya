export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Handle CORS preflight requests
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
          "Access-Control-Allow-Headers": "*",
        },
      });
    }

    // Forward the exact same path and query to the real TMDB API
    const tmdbUrl = new URL("https://api.tmdb.org" + url.pathname + url.search);

    // Make the request to TMDB
    const response = await fetch(tmdbUrl, {
      method: request.method,
      headers: {
        "Accept": "application/json",
      },
    });

    // Create a new response to allow CORS
    const newResponse = new Response(response.body, response);
    newResponse.headers.set("Access-Control-Allow-Origin", "*");

    return newResponse;
  },
};
