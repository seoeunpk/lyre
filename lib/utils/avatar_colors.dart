import 'package:flutter/material.dart';
import 'app_colors.dart';

class AvatarColors {
  static const List<Color> palette = [
    AppColors.pink,
    AppColors.darkPink,
    AppColors.mint,
  ];

  static Color forId(String id) {
    if (id.isEmpty) return palette[0];
    final hash = id.codeUnits.fold<int>(0, (sum, c) => sum + c);
    return palette[hash % palette.length];
  }
}
