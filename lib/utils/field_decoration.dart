import 'package:flutter/material.dart';
import 'app_colors.dart';

InputDecoration appFieldDecoration({
  String? hintText,
  String? labelText,
  double? hintFontSize,
  double radius = 12,
  Color fillColor = AppColors.background,
  Color focusColor = AppColors.primary,
  EdgeInsetsGeometry contentPadding =
      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  bool isDense = true,
  String? counterText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: const BorderSide(color: AppColors.border),
  );
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: AppColors.grey, fontSize: hintFontSize),
    labelText: labelText,
    labelStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
    filled: true,
    fillColor: fillColor,
    isDense: isDense,
    counterText: counterText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    contentPadding: contentPadding,
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: focusColor, width: 2),
    ),
  );
}

InputDecoration authFieldDecoration(String label) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none,
  );
  return InputDecoration(
    hintText: label,
    hintStyle: const TextStyle(color: AppColors.grey),
    filled: true,
    fillColor: AppColors.lightGrey,
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.pink, width: 2),
    ),
  );
}
