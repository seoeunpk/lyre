import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';

class JournalService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _notesDoc(String userId) => _db
      .collection('users')
      .doc(userId)
      .collection('private')
      .doc('notes');

  Future<void> saveEntry(String userId, JournalEntry entry) async {
    await Future.wait([
      _db
          .collection('users')
          .doc(userId)
          .collection('entries')
          .doc(entry.docId)
          .set(entry.toMap()),
      _notesDoc(userId).set(
        {entry.docId: entry.note},
        SetOptions(merge: true),
      ),
    ]);
  }

  Future<JournalEntry?> getEntryForDate(String userId, DateTime date) async {
    final docId =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('entries')
        .doc(docId)
        .get()
        .timeout(const Duration(seconds: 10));
    if (!doc.exists) return null;
    final entry = JournalEntry.fromMap(doc.data()!);
    final note = await _noteFor(userId, docId, legacyMap: doc.data()!);
    return entry.copyWith(note: note);
  }

  Future<void> deleteEntry(String userId, String docId) async {
    await Future.wait([
      _db
          .collection('users')
          .doc(userId)
          .collection('entries')
          .doc(docId)
          .delete(),
      _notesDoc(userId).set(
        {docId: FieldValue.delete()},
        SetOptions(merge: true),
      ),
    ]);
  }

  static String _resolveNote(
    String docId,
    Map<String, dynamic> notesMap,
    Map<String, dynamic>? legacyMap,
  ) {
    return notesMap[docId] as String? ?? legacyMap?['note'] as String? ?? '';
  }

  Future<String> _noteFor(
    String userId,
    String docId, {
    Map<String, dynamic>? legacyMap,
  }) async {
    final notesDoc = await _notesDoc(userId).get();
    return _resolveNote(docId, notesDoc.data() ?? {}, legacyMap);
  }

  Stream<List<JournalEntry>> getEntries(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('entries')
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          Map<String, dynamic> notesMap = {};
          try {
            final notesDoc = await _notesDoc(userId).get();
            notesMap = notesDoc.data() ?? {};
          } catch (_) {}
          final entries = <JournalEntry>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final entry = JournalEntry.fromMap(data);
            final note = _resolveNote(doc.id, notesMap, data);
            entries.add(entry.copyWith(note: note));
          }
          return entries;
        });
  }

  Stream<List<JournalEntry>> getSharedEntries(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('entries')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          final entries = <JournalEntry>[];
          for (final doc in snapshot.docs) {
            entries.add(JournalEntry.fromMap(doc.data()));
          }
          return entries;
        });
  }
}
