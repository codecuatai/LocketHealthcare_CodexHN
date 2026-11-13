import 'package:flutter/material.dart';

import '../../core/theme/vita_theme.dart';
import '../../core/validation/auth_validators.dart';

/// Vạch mảnh 4 nấc đo độ mạnh mật khẩu, kèm một dòng gợi ý còn thiếu gì.
class PasswordMeter extends StatelessWidget {
  const PasswordMeter({super.key, required this.password});
  final String password;

  static Color colorFor(PasswordStrength strength) => switch (strength) {
        PasswordStrength.empty => VitaColors.muted,
        PasswordStrength.weak => VitaColors.coral,
        PasswordStrength.fair => VitaColors.coralSoft,
        PasswordStrength.strong => VitaColors.voltDim,
        PasswordStrength.veryStrong => VitaColors.volt,
      };

  @override
  Widget build(BuildContext context) {
    final check = PasswordCheck(password);
    final level = check.strength.index;
    final color = colorFor(check.strength);
    return Semantics(
      label: 'Độ mạnh mật khẩu: ${check.hint}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(children: [
          for (var i = 1; i <= 4; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 3,
                decoration: BoxDecoration(
                  color: i <= level ? color : VitaColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 5),
          ],
          const SizedBox(width: 4),
          Text(check.hint,
              style: VitaText.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: check.isAcceptable ? color : VitaColors.muted)),
        ]),
      ),
    );
  }
}
