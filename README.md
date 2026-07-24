# LYRE

A mood-to-music journal for iOS and Android. Log how you feel, attach a song, and watch your month fill up with album art.



## Tech Stack

| Layer | Technology |
|---|---|
| UI / Client | Flutter (Dart) |
| Identity | Firebase Auth |
| Database | Cloud Firestore |
| Music data | Spotify Web API |
| Config | flutter_dotenv |



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
- A Spotify developer account
- An iOS/Android emulator or physical device

### Clone and install

```bash
git clone https://github.com/seoeunpk/lyre.git
cd lyre
flutter pub get
```

### Spotify credentials

Create an app in the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) and add your credentials to a `.env` file at the project root:

```
SPOTIFY_CLIENT_ID=your_client_id
SPOTIFY_CLIENT_SECRET=your_client_secret
```

### Firebase

Firebase configuration files are already included. To connect a different Firebase project, regenerate the config files with FlutterFire.

### Run

```bash
flutter run
```



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
├── firestore.rules
├── pubspec.yaml
└── .env                  (gitignored)
```
