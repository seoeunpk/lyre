import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class SectionLabel extends StatelessWidget {
  final String title;
  const SectionLabel(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.grey,
        letterSpacing: 0.8,
      ),
    );
  }
}
