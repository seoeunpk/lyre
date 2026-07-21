# Spotify search Worker

This Worker keeps Spotify credentials outside the Flutter app and exposes one endpoint:

```text
POST /search
{ "query": "song or artist" }
```

## Deploy the Worker

1. In the Cloudflare dashboard, open the `lyre-spotify-search` Worker.
2. Replace the Worker code with `src/index.js` and deploy it.
3. In **Settings** → **Variables and Secrets**, add these as secrets:

   - `SPOTIFY_CLIENT_ID`
   - `SPOTIFY_CLIENT_SECRET`

The secret values must not be committed to this repository or added to Flutter assets.
