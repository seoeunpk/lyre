import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friendship.dart';
import '../models/sharing_settings.dart';

class SharingService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid).collection('settings').doc('sharing');

  Future<SharingSettings> getSettings(String uid) async {
    final doc = await _doc(uid).get();
    return SharingSettings.fromMap(doc.data());
  }

  Future<void> ensureDefaultSharing(String uid, List<Friendship> accepted) async {
    if (accepted.isEmpty) return;
    final current = await getSettings(uid);
    final newlyAccepted = accepted
        .where((f) => !current.autoShareApplied.contains(f.id))
        .toList();
    if (newlyAccepted.isEmpty) return;

    final update = <String, dynamic>{
      'autoShareApplied':
          FieldValue.arrayUnion(newlyAccepted.map((f) => f.id).toList()),
    };
    for (final f in newlyAccepted) {
      update['perFriend.${f.otherUid(uid)}'] = const FriendSharePrefs().toMap();
    }
    await _doc(uid).set(update, SetOptions(merge: true));
  }

  Stream<SharingSettings> watchSettings(String uid) {
    return _doc(uid).snapshots().map((doc) => SharingSettings.fromMap(doc.data()));
  }

  Future<void> updateSettings(String uid, SharingSettings settings) async {
    await _doc(uid).set(settings.toMap());
  }
}
