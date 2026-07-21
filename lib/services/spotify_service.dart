import 'dart:convert';
import 'package:http/http.dart' as http;

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
  static final _searchUrl = Uri.parse(
    'https://lyre-spotify-search.yawenchua.workers.dev/search',
  );

  Future<List<SpotifyTrack>> searchTracks(String query) async {
    final response = await http.post(
      _searchUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode != 200) {
      throw Exception('Could not search Spotify right now.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tracks = data['tracks'] as List? ?? [];
    return tracks.map((track) {
      final map = Map<String, dynamic>.from(track as Map);
      return SpotifyTrack(
        trackId: map['trackId'] as String? ?? '',
        trackName: map['trackName'] as String? ?? '',
        artistName: map['artistName'] as String? ?? '',
        albumArtUrl: map['albumArtUrl'] as String? ?? '',
      );
    }).toList();
  }
}
