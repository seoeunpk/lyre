let accessToken;
let tokenExpiresAt;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

async function getSpotifyToken(env) {
  if (accessToken && tokenExpiresAt && Date.now() < tokenExpiresAt) {
    return accessToken;
  }

  const credentials = btoa(
    `${env.SPOTIFY_CLIENT_ID}:${env.SPOTIFY_CLIENT_SECRET}`,
  );
  const response = await fetch('https://accounts.spotify.com/api/token', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${credentials}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  });

  if (!response.ok) return null;

  const data = await response.json();
  accessToken = data.access_token;
  tokenExpiresAt = Date.now() + (data.expires_in - 60) * 1000;
  return accessToken;
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }
    if (request.method !== 'POST') {
      return jsonResponse({ error: 'Use POST to search Spotify.' }, 405);
    }
    if (new URL(request.url).pathname !== '/search') {
      return jsonResponse({ error: 'Route not found.' }, 404);
    }

    let body;
    try {
      body = await request.json();
    } catch (_) {
      return jsonResponse({ error: 'Request body must be JSON.' }, 400);
    }

    const query = typeof body.query === 'string' ? body.query.trim() : '';
    if (query.length === 0 || query.length > 100) {
      return jsonResponse(
        { error: 'Enter a search between 1 and 100 characters.' },
        400,
      );
    }

    const token = await getSpotifyToken(env);
    if (!token) {
      return jsonResponse({ error: 'Could not connect to Spotify.' }, 502);
    }

    const url = new URL('https://api.spotify.com/v1/search');
    url.searchParams.set('q', query);
    url.searchParams.set('type', 'track');
    url.searchParams.set('limit', '10');

    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!response.ok) {
      return jsonResponse(
        { error: 'Could not search Spotify right now.' },
        502,
      );
    }

    const data = await response.json();
    const tracks = (data.tracks?.items ?? []).map((track) => {
      const images = track.album?.images ?? [];
      return {
        trackId: track.id ?? '',
        trackName: track.name ?? '',
        artistName: track.artists?.[0]?.name ?? '',
        albumArtUrl: images[0]?.url ?? '',
      };
    });

    return jsonResponse({ tracks });
  },
};
