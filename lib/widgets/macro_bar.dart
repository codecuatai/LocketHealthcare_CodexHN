import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class MacroBar extends StatelessWidget {
  const MacroBar({super.key, required this.label, required this.grams,
    required this.color, required this.progress});
  final String label;
  final int grams;
  final Color color;
  final double progress;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      const Spacer(), Text('${grams}g', style: const TextStyle(fontWeight: FontWeight.w700))]),
    const SizedBox(height: 8),
    ClipRRect(borderRadius: BorderRadius.circular(20),
      child: LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 7,
        backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(color))),
  ]);
}
