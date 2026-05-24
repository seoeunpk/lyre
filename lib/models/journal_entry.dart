import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String? id; // firestore doc id, not saved in the document itself
  final String trackId;
  final String trackName;
  final String artistName;
  final String albumArt;
  final String mood;
  final String note;
  final List<String> tags;
  final Timestamp createdAt;

  JournalEntry({
    this.id,
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.albumArt,
    required this.mood,
    required this.note,
    required this.tags,
    required this.createdAt,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map, {String? id}) {
    final tagList = List<String>.from(map['tags'] ?? []);

    return JournalEntry(
      id: id,
      trackId: map['trackId'] ?? '',
      trackName: map['trackName'] ?? '',
      artistName: map['artistName'] ?? '',
      albumArt: map['albumArt'] ?? '',
      mood: map['mood'] ?? '',
      note: map['note'] ?? '',
      tags: tagList,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackId': trackId,
      'trackName': trackName,
      'artistName': artistName,
      'albumArt': albumArt,
      'mood': mood,
      'note': note,
      'tags': tags,
      'createdAt': createdAt,
    };
  }
}
