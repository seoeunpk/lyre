import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/friendship.dart';
import '../utils/friend_code_words.dart';

class FriendService {
  final _db = FirebaseFirestore.instance;

  String friendshipId(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> ensureProfile(String uid, String name) async {
    final ref = _db.collection('users').doc(uid);
    final doc = await ref.get();
    final existingCode = doc.data()?['friendCode'] as String?;
    final needsNewCode = existingCode == null ||
        existingCode.isEmpty ||
        existingCode.startsWith('LYRE-');
    if (!needsNewCode) {
      if (doc.data()?['name'] != name) {
        await ref.set({'name': name}, SetOptions(merge: true));
      }
      return;
    }
    final code = await _reserveFriendCode(uid);
    await ref.set({'name': name, 'friendCode': code}, SetOptions(merge: true));
  }

  Future<String> _reserveFriendCode(String uid) async {
    final rand = Random();
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = FriendCodeWords.animals[rand.nextInt(FriendCodeWords.animals.length)] +
          FriendCodeWords.things[rand.nextInt(FriendCodeWords.things.length)] +
          FriendCodeWords.colors[rand.nextInt(FriendCodeWords.colors.length)];
      final codeRef = _db.collection('friendCodes').doc(code);
      final reserved = await _db.runTransaction<bool>((tx) async {
        final snap = await tx.get(codeRef);
        if (snap.exists) return false;
        tx.set(codeRef, {'uid': uid});
        return true;
      });
      if (reserved) return code;
    }
    throw Exception('Could not generate a unique friend code');
  }

  Future<UserProfile?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(uid, doc.data()!);
  }

  Future<String?> sendRequestByCode(String uid, String rawCode) async {
    final code = rawCode.trim().toLowerCase();
    if (code.isEmpty) return "Enter a friend code.";

    final codeDoc = await _db.collection('friendCodes').doc(code).get();
    if (!codeDoc.exists) return "No user found with that code.";

    final targetUid = codeDoc.data()?['uid'] as String?;
    if (targetUid == null) return "No user found with that code.";
    if (targetUid == uid) return "That's your own code.";

    final id = friendshipId(uid, targetUid);
    final ref = _db.collection('friendships').doc(id);
    final existing = await ref.get();
    if (existing.exists) {
      final status = existing.data()?['status'];
      if (status == 'accepted') return "You're already friends.";
      if (status == 'pending') return "A request is already pending.";
      await ref.update({
        'status': 'pending',
        'requestedBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': FieldValue.delete(),
      });
      return null;
    }

    await ref.set({
      'users': [uid, targetUid]..sort(),
      'requestedBy': uid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return null;
  }

  Future<void> respondToRequest(String id, bool accept) async {
    final ref = _db.collection('friendships').doc(id);
    await ref.update({
      'status': accept ? 'accepted' : 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> retryRequest(String id, String uid) async {
    final ref = _db.collection('friendships').doc(id);
    await ref.update({
      'status': 'pending',
      'requestedBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'respondedAt': FieldValue.delete(),
    });
  }

  Future<void> dismissRequest(String id) async {
    await _db.collection('friendships').doc(id).delete();
  }

  Stream<List<Friendship>> friendshipsFor(String uid) {
    return _db
        .collection('friendships')
        .where('users', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Friendship.fromMap(d.id, d.data()))
            .toList());
  }
}
