import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class Mood {
  final String label;
  final String emoji;
  final Color color;

  const Mood({
    required this.label,
    required this.emoji,
    required this.color,
  });
}

class Moods {
  static const List<Mood> all = [
    Mood(label: 'Happy', emoji: '😊', color: Color(0xFFF6C744)),
    Mood(label: 'Calm', emoji: '😌', color: AppColors.mint),
    Mood(label: 'Grateful', emoji: '🥰', color: AppColors.pink),
    Mood(label: 'Excited', emoji: '🤩', color: Color(0xFFF38B4A)),
    Mood(label: 'Sad', emoji: '😢', color: Color(0xFF7FA7D9)),
    Mood(label: 'Anxious', emoji: '😰', color: Color(0xFFB69CD8)),
    Mood(label: 'Angry', emoji: '😠', color: Color(0xFFE57373)),
    Mood(label: 'Tired', emoji: '😴', color: Color(0xFFA9B0B8)),
  ];

  static Mood? byLabel(String? label) {
    if (label == null || label.isEmpty) return null;
    for (final m in all) {
      if (m.label == label) return m;
    }
    return null;
  }
}
