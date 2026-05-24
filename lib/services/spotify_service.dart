import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
  String? _accessToken;

  Future<void> _authenticate() async {
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
    print('spotify token ok'); // debug
  }

  Future<List<SpotifyTrack>> searchTracks(String query) async {
    // TODO: cache the token instead of re-authing every time
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

    return items.map((item) {
      final json = item as Map<String, dynamic>;
      final album = json['album'] as Map<String, dynamic>?;
      final images = (album?['images'] as List<dynamic>?) ?? [];
      final imageUrl = images.isNotEmpty ? images[0]['url'] as String : '';

      final artists = json['artists'] as List<dynamic>;
      final artistName = artists.isNotEmpty ? artists[0]['name'] as String : '';

      return SpotifyTrack(
        trackId: json['id'] as String,
        trackName: json['name'] as String,
        artistName: artistName,
        albumArtUrl: imageUrl,
      );
    }).toList();
  }
}
