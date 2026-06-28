import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/mood.dart';

class MoodService {
  final _db = FirebaseFirestore.instance;

  Future<List<Mood>> getCustomMoods(String uid) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc('_custom_moods')
        .get();
    final list = doc.data()?['moods'] as List? ?? [];
    return list.map((m) => Mood(
      label: m['label'] as String,
      emoji: m['emoji'] as String,
      color: Color(m['colorValue'] as int),
    )).toList();
  }

  Future<void> addCustomMood(String uid, Mood mood) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc('_custom_moods')
        .set({
      'moods': FieldValue.arrayUnion([{
        'label': mood.label,
        'emoji': mood.emoji,
        'colorValue': mood.color.toARGB32(),
      }]),
    }, SetOptions(merge: true));
  }
}
