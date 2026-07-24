import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyre/models/journal_entry.dart';
import 'package:lyre/services/spotify_service.dart';

void main() {
  final date = DateTime(2026, 7, 24, 15, 30);
  final song = EntrySong(
    trackId: 'track-1',
    trackName: 'Track',
    artistName: 'Artist',
    albumArtUrl: 'https://example.com/art.jpg',
  );

  test('uses a stable date-only document id', () {
    final entry = JournalEntry(
      date: date,
      mood: 'Happy',
      note: 'A note',
      tags: const ['school'],
    );

    expect(entry.docId, '2026-07-24');
  });

  test('round-trips a song through a map', () {
    expect(EntrySong.fromMap(song.toMap()).trackName, 'Track');
    expect(EntrySong.fromMap(song.toMap()).artistName, 'Artist');
  });

  test('creates an entry song from a Spotify track', () {
    final track = SpotifyTrack(
      trackId: 'spotify-id',
      trackName: 'Song',
      artistName: 'Singer',
      albumArtUrl: 'art',
    );

    final entrySong = EntrySong.fromTrack(track);
    expect(entrySong.trackId, 'spotify-id');
    expect(entrySong.artistName, 'Singer');
  });

  test('serializes entry fields and restores them from Firestore data', () {
    final entry = JournalEntry(
      date: date,
      mood: 'Calm',
      note: 'Private note',
      tags: const ['home', 'evening'],
      song: song,
    );
    final saved = entry.toMap();

    expect(saved['date'], isA<Timestamp>());
    expect(saved['mood'], 'Calm');
    expect(saved['tags'], ['home', 'evening']);

    final restored = JournalEntry.fromMap({
      'date': Timestamp.fromDate(date),
      'mood': 'Calm',
      'tags': ['home', 'evening'],
      'song': song.toMap(),
      'note': 'Legacy note',
    });
    expect(restored.date, date);
    expect(restored.mood, 'Calm');
    expect(restored.tags, ['home', 'evening']);
    expect(restored.song?.trackId, 'track-1');
    expect(restored.note, isEmpty);
  });

  test('copyWith replaces only the note', () {
    final entry = JournalEntry(
      date: date,
      mood: 'Happy',
      note: 'Before',
      tags: const ['tag'],
      song: song,
    );

    final updated = entry.copyWith(note: 'After');
    expect(updated.note, 'After');
    expect(updated.song?.trackId, 'track-1');
    expect(updated.tags, ['tag']);
  });
}
