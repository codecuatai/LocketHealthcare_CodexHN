import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CustomPill extends StatelessWidget {
  const CustomPill({super.key, required this.child, this.onTap, this.padding});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(100),
    child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Material(color: AppColors.surface.withOpacity(.83),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100),
          side: BorderSide(color: AppColors.white.withOpacity(.12))),
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(100),
          child: Padding(padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 11), child: child)))));
}
