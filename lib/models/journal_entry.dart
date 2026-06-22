import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/spotify_service.dart';

// the song saved with an entry
class EntrySong {
  final String trackId;
  final String trackName;
  final String artistName;
  final String albumArtUrl;

  EntrySong({
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.albumArtUrl,
  });

  factory EntrySong.fromTrack(SpotifyTrack t) => EntrySong(
        trackId: t.trackId,
        trackName: t.trackName,
        artistName: t.artistName,
        albumArtUrl: t.albumArtUrl,
      );

  factory EntrySong.fromMap(Map<String, dynamic> map) => EntrySong(
        trackId: map['trackId'] ?? '',
        trackName: map['trackName'] ?? '',
        artistName: map['artistName'] ?? '',
        albumArtUrl: map['albumArtUrl'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'trackId': trackId,
        'trackName': trackName,
        'artistName': artistName,
        'albumArtUrl': albumArtUrl,
      };
}

class JournalEntry {
  final DateTime date;
  final String mood;
  final String note;
  final List<String> tags;
  final EntrySong? song;

  JournalEntry({
    required this.date,
    required this.mood,
    required this.note,
    required this.tags,
    this.song,
  });

  // one entry per day, id is the date like 2026-06-22
  String get docId =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    final ts = map['date'];
    final songMap = map['song'];
    return JournalEntry(
      date: ts is Timestamp ? ts.toDate() : DateTime.now(),
      mood: map['mood'] ?? '',
      note: map['note'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      song: songMap is Map<String, dynamic>
          ? EntrySong.fromMap(songMap)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'mood': mood,
        'note': note,
        'tags': tags,
        'song': song?.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
