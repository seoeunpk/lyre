import 'package:flutter_test/flutter_test.dart';
import 'package:lyre/models/journal_entry.dart';
import 'package:lyre/screens/insights_screen.dart';

JournalEntry entry({
  required DateTime date,
  String mood = '',
  List<String> tags = const [],
  String note = '',
  EntrySong? song,
}) =>
    JournalEntry(date: date, mood: mood, note: note, tags: tags, song: song);

EntrySong song(String track, String artist) => EntrySong(
      trackId: track,
      trackName: track,
      artistName: artist,
      albumArtUrl: '',
    );

void main() {
  final entries = [
    entry(
        date: DateTime(2026, 7, 1),
        mood: 'Happy',
        tags: ['school'],
        song: song('Song A', 'Artist A')),
    entry(
        date: DateTime(2026, 7, 2),
        mood: 'Calm',
        tags: ['school', 'evening'],
        song: song('Song A', 'Artist A')),
    entry(
        date: DateTime(2026, 7, 3),
        mood: 'Happy',
        tags: ['evening'],
        song: song('Song B', 'Artist B')),
  ];

  test('counts moods, tags, artists, and songs', () {
    expect(countMoods(entries), {'Happy': 2, 'Calm': 1});
    expect(countTags(entries), {'school': 2, 'evening': 2});
    expect(countArtists(entries), {'Artist A': 2, 'Artist B': 1});
    const dash = '\u2014';
    expect(countSongs(entries), {
      'Song A $dash Artist A': 2,
      'Song B $dash Artist B': 1,
    });
  });

  test('omits empty mood, tag, and song values from counts', () {
    final blank = entry(date: DateTime(2026, 7, 4), song: song('', ''));
    expect(countMoods([blank]), isEmpty);
    expect(countTags([blank]), isEmpty);
    expect(countArtists([blank]), isEmpty);
    expect(countSongs([blank]), isEmpty);
  });

  test('finds a top item and sorts counts descending', () {
    final counts = {'second': 1, 'first': 3, 'third': 2};
    expect(getTopItem(counts), 'first');
    expect(sortedItems(counts).map((item) => item.key),
        ['first', 'third', 'second']);
  });

  test('summarizes music coverage', () {
    expect(musicSubtitle(entries), '3 entries include a song (100%)');
    expect(musicSubtitle([]), 'No entries in this period');
  });

}
