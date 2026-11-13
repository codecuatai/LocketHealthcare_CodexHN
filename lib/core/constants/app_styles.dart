import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppStyles {
  static const display = TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -2, color: AppColors.white);
  static const heading = TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1, color: AppColors.white);
  static const title = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white);
  static const body = TextStyle(fontSize: 16, color: AppColors.white);
  static const bodySmall = TextStyle(fontSize: 14, color: AppColors.muted);
  static const radius = 24.0;
  static const radiusLarge = 32.0;
}
