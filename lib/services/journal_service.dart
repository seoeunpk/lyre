import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';

class JournalService {
  final _db = FirebaseFirestore.instance;

  // save the entry. the doc id is the date so saving again overwrites it
  Future<void> saveEntry(String userId, JournalEntry entry) async {
    print('saving entry ${entry.docId}'); // debug
    await _db
        .collection('users')
        .doc(userId)
        .collection('entries')
        .doc(entry.docId)
        .set(entry.toMap());
  }

  // get the entry for one day, null if there isnt one yet
  Future<JournalEntry?> getEntryForDate(String userId, DateTime date) async {
    final docId =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('entries')
        .doc(docId)
        .get();
    if (!doc.exists) return null;
    return JournalEntry.fromMap(doc.data()!);
  }

  Future<void> deleteEntry(String userId, String docId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('entries')
        .doc(docId)
        .delete();
  }

  Stream<List<JournalEntry>> getEntries(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('entries')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return JournalEntry.fromMap(doc.data());
      }).toList();
    });
  }
}
