import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lyre/services/spotify_service.dart';

class FakeClient extends http.BaseClient {
  FakeClient(this.statusCode, this.body);

  final int statusCode;
  final String body;
  http.BaseRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest sentRequest) async {
    request = sentRequest;
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  test('sends a JSON search query and maps tracks from the response', () async {
    final client = FakeClient(
        200,
        jsonEncode({
          'tracks': [
            {
              'trackId': 'id-1',
              'trackName': 'Track one',
              'artistName': 'Artist one',
              'albumArtUrl': 'https://example.com/art.jpg',
            }
          ]
        }));

    final tracks = await SpotifyService(client: client).searchTracks('focus');

    expect(client.request?.method, 'POST');
    expect(
        jsonDecode((client.request as http.Request).body), {'query': 'focus'});
    expect(tracks, hasLength(1));
    expect(tracks.single.trackName, 'Track one');
  });

  test('returns an empty list when the response has no tracks', () async {
    final tracks = await SpotifyService(client: FakeClient(200, '{}'))
        .searchTracks('none');
    expect(tracks, isEmpty);
  });

  test('uses empty strings for optional track fields', () async {
    final tracks = await SpotifyService(
      client: FakeClient(
          200,
          jsonEncode({
            'tracks': [{}]
          })),
    ).searchTracks('partial');
    expect(tracks.single.trackId, isEmpty);
  });

  test('throws a user-safe error for an unsuccessful response', () async {
    final search =
        SpotifyService(client: FakeClient(500, '{}')).searchTracks('focus');
    await expectLater(search, throwsA(isA<Exception>()));
  });
}
