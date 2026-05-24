import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';

class JournalService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveEntry(String userId, JournalEntry entry) async {
    final data = entry.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(userId).collection('entries').add(data);
  }

  Stream<List<JournalEntry>> getEntries(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('entries')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return JournalEntry.fromMap(
          doc.data(),
          id: doc.id,
        );
      }).toList();
    });
  }
}
