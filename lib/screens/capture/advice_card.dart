import 'package:flutter/material.dart';

import '../../core/models/analysis.dart';
import '../../core/theme/vita_theme.dart';

const amber = Color(0xFFFFC24B);

/// Thẻ "Mức phù hợp với cậu": màu theo mức, lý do gắn Bệnh lý nền, cách ăn.
class AdviceCard extends StatelessWidget {
  const AdviceCard({
    super.key,
    required this.verdict,
    required this.eyebrow,
    required this.title,
    required this.reasons,
    this.tipsLabel,
    this.tips = const [],
  });

  factory AdviceCard.fit(FoodAnalysis a) => AdviceCard(
        verdict: a.verdict,
        eyebrow: 'Mức phù hợp với cậu',
        title: a.verdict.label,
        reasons: a.reasons,
        tipsLabel: a.verdict == FitVerdict.good
            ? 'Cách ăn tốt hơn'
            : 'Cách ăn giảm hại',
        tips: a.tips,
      );

  final FitVerdict verdict;
  final String eyebrow;
  final String title;
  final List<FitReason> reasons;
  final String? tipsLabel;
  final List<String> tips;

  Color get _tone => switch (verdict) {
        FitVerdict.good => VitaColors.volt,
        FitVerdict.adjust => amber,
        FitVerdict.avoid => VitaColors.coralSoft,
      };

  IconData get _icon => switch (verdict) {
        FitVerdict.good => Icons.check_rounded,
        FitVerdict.adjust => Icons.priority_high_rounded,
        FitVerdict.avoid => Icons.close_rounded,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _tone.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _tone.withValues(alpha: .4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: _tone, shape: BoxShape.circle),
              child: Icon(_icon, size: 19, color: const Color(0xFF141414)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow.toUpperCase(), style: VitaText.label),
                    Text(title,
                        style: TextStyle(
                            fontFamily: VitaFonts.display,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            color: _tone)),
                  ]),
            ),
          ]),
          const SizedBox(height: 12),
          for (final r in reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  margin: const EdgeInsets.only(top: 1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                      color: VitaColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(99)),
                  child: Text(r.tag,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: VitaColors.onSurfaceVariant)),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(r.text,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: VitaColors.onSurface))),
              ]),
            ),
          if (tips.isNotEmpty) ...[
            if (tipsLabel != null) ...[
              const SizedBox(height: 2),
              Text(tipsLabel!.toUpperCase(), style: VitaText.label),
              const SizedBox(height: 8),
            ],
            for (final t in tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_rounded, size: 18, color: _tone),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t, style: VitaText.bodySmall)),
                    ]),
              ),
          ],
        ]),
      );
}
