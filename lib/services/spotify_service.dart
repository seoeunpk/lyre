import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  Future<void> _authenticate() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return;
    }

    final clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';

    final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));

    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode != 200) {
      throw Exception('spotify auth failed ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    _accessToken = data['access_token'] as String;
    _tokenExpiry = DateTime.now().add(const Duration(seconds: 3500));
  }

  Future<List<SpotifyTrack>> searchTracks(String query) async {
    await _authenticate();

    final uri = Uri.parse('https://api.spotify.com/v1/search').replace(
      queryParameters: {
        'q': query,
        'type': 'track',
        'limit': '10',
      },
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('search failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final items = data['tracks']['items'] as List<dynamic>;

    final tracks = <SpotifyTrack>[];
    for (final item in items) {
      final images = (item['album']?['images'] as List?) ?? [];
      final artists = item['artists'] as List;
      final artistName = artists.isNotEmpty ? artists[0]['name'] as String : '';
      final albumArtUrl = images.isNotEmpty ? images[0]['url'] as String : '';
      tracks.add(SpotifyTrack(
        trackId: item['id'] as String,
        trackName: item['name'] as String,
        artistName: artistName,
        albumArtUrl: albumArtUrl,
      ));
    }
    return tracks;
  }
}
