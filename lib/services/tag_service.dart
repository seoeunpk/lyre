import 'package:cloud_firestore/cloud_firestore.dart';

class TagService {
  final _db = FirebaseFirestore.instance;

  Future<List<String>> getCustomTags(String uid) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc('_custom_tags')
        .get();
    final list = doc.data()?['tags'] as List? ?? [];
    return list.cast<String>();
  }

  Future<void> addCustomTag(String uid, String tag) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc('_custom_tags')
        .set({'tags': FieldValue.arrayUnion([tag])}, SetOptions(merge: true));
  }

  Future<void> deleteCustomTag(String uid, String tag) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc('_custom_tags')
        .set({'tags': FieldValue.arrayRemove([tag])}, SetOptions(merge: true));
  }
}
