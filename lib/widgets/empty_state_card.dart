import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class EmptyStateCard extends StatelessWidget {
  final String text;
  const EmptyStateCard(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.grey, fontSize: 13, height: 1.5),
      ),
    );
  }
}
