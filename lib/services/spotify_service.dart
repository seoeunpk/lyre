// MOCK SPOTIFY SERVICE
// fake spotify search so we can build the search bar in the new entry screen
// without needing real spotify api keys.
// Person A will replace this with the real one in milestone 2.

// represents a song from spotify
class SpotifyTrack {
  final String trackId;
  final String trackName;
  final String artistName;
  final String albumArtUrl;

  SpotifyTrack({
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.albumArtUrl,
  });
}

class SpotifyService {
  // pretend song database
  static final List<SpotifyTrack> _fakeSongs = [
    SpotifyTrack(
      trackId: "1",
      trackName: "Anti-Hero",
      artistName: "Taylor Swift",
      albumArtUrl: "",
    ),
    SpotifyTrack(
      trackId: "2",
      trackName: "Blinding Lights",
      artistName: "The Weeknd",
      albumArtUrl: "",
    ),
    SpotifyTrack(
      trackId: "3",
      trackName: "As It Was",
      artistName: "Harry Styles",
      albumArtUrl: "",
    ),
    SpotifyTrack(
      trackId: "4",
      trackName: "Vienna",
      artistName: "Billy Joel",
      albumArtUrl: "",
    ),
    SpotifyTrack(
      trackId: "5",
      trackName: "August",
      artistName: "Taylor Swift",
      albumArtUrl: "",
    ),
    SpotifyTrack(
      trackId: "6",
      trackName: "Heat Waves",
      artistName: "Glass Animals",
      albumArtUrl: "",
    ),
  ];

  // search for tracks matching the query
  Future<List<SpotifyTrack>> searchTracks(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (query.trim().isEmpty) return [];

    final q = query.toLowerCase();
    return _fakeSongs.where((song) {
      return song.trackName.toLowerCase().contains(q) ||
          song.artistName.toLowerCase().contains(q);
    }).toList();
  }
}
