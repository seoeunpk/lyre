import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/avatar_colors.dart';

String initialsFor(String name) {
  final letters = name
      .trim()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0])
      .join()
      .toUpperCase();
  return letters.isEmpty ? '?' : letters;
}

class AvatarCircle extends StatelessWidget {
  final String id;
  final String name;
  final double size;

  const AvatarCircle({
    super.key,
    required this.id,
    required this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AvatarColors.forId(id),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initialsFor(name),
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}
