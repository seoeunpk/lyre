# LYRE

A mood-to-music journal for iOS and Android. Log how you feel, attach a song, and watch your month fill up with album art.



## Tech Stack

| Layer | Technology |
|---|---|
| UI / Client | Flutter (Dart) |
| Identity | Firebase Auth |
| Database | Cloud Firestore |
| Music data | Spotify Web API (proxied through a Cloudflare Worker) |



## Features

- **Calendar view** — Monthly grid where each day shows the album art of your entry
- **Journal entries** — Write a reflection, pick a mood, and attach a Spotify track
- **Custom moods** — Add your own mood labels with an emoji and colour
- **Tagging** — Tag entries (e.g. `school`, `cozy`) for richer filtering
- **History** — Chronological list of all entries with search and mood/tag filters
- **Insights** — Most frequent moods, songs, artists, and tags *(in progress)*
- **Social** — Share your calendar with friends *(planned)*



## Getting Started

### Requirements

- Flutter SDK
- Git
- An iOS/Android emulator or physical device

### Clone and install

```bash
git clone https://github.com/seoeunpk/lyre.git
cd lyre
flutter pub get
```

### Spotify credentials

Spotify search is proxied through a Cloudflare Worker (see [`worker/`](worker/)), so the Flutter app itself never holds a client ID or secret — there's no `.env` file to set up. The Worker owns the credentials and exposes a single `/search` endpoint that the app calls.

If you're standing up your own backend, create an app in the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard), deploy the Worker in `worker/`, and add the client ID/secret as Worker secrets (never as app config). See [`worker/README.md`](worker/README.md) for deploy steps, then point `SpotifyService` at your Worker URL.

### Firebase

Firebase configuration files are already included. To connect a different Firebase project, regenerate the config files with FlutterFire.

### Run

```bash
flutter run
```

### Quality checks

Run the automated unit and widget tests locally with:

```bash
flutter analyze
flutter test
```

GitHub Actions runs both commands on every push and pull request. The suite
uses mocked HTTP responses for Spotify and does not access live Firebase data.



## Project Structure

```
lyre/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── home_screen.dart
│   │   ├── new_entry_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── history_screen.dart
│   │   └── insights_screen.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── journal_service.dart
│   │   ├── mood_service.dart
│   │   └── spotify_service.dart
│   └── utils/
│       └── app_colors.dart
├── worker/                (Cloudflare Worker proxying Spotify API calls)
│   ├── src/index.js
│   └── wrangler.toml
├── firestore.rules
└── pubspec.yaml
```
