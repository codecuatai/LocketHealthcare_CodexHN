import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/vita_theme.dart';

/// Nút hành động chính: viên thuốc volt cao 56px, có quầng sáng.
class VitaPrimaryButton extends StatelessWidget {
  const VitaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? '$label, đang xử lý' : label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onPressed == null && !loading ? .5 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: VitaShadows.glow),
          child: Material(
            color: VitaColors.volt,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled
                  ? () {
                      HapticFeedback.lightImpact();
                      onPressed!();
                    }
                  : null,
              splashColor: VitaColors.onVolt.withValues(alpha: .12),
              child: SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: loading
                        ? const Row(mainAxisSize: MainAxisSize.min, children: [
                            SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: VitaColors.onVolt)),
                            SizedBox(width: 10),
                            Text('Đang xử lý',
                                style: TextStyle(
                                    fontFamily: VitaFonts.display,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    color: VitaColors.onVolt)),
                          ])
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            Flexible(
                              child: Text(label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: VitaText.button
                                      .copyWith(color: VitaColors.onVolt)),
                            ),
                            if (showArrow) ...[
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 20, color: VitaColors.onVolt),
                            ],
                          ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút phụ: viền mảnh, nền trong suốt.
class VitaGhostButton extends StatelessWidget {
  const VitaGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool loading;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onPressed != null && !loading,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(
              side: BorderSide(color: VitaColors.surfaceHighest, width: 1.5)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: loading ? null : onPressed,
            highlightColor: VitaColors.surfaceHighest,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (loading)
                  const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                else if (leading != null)
                  leading!,
                if (loading || leading != null) const SizedBox(width: 12),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: VitaFonts.body,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: VitaColors.onSurface)),
                ),
              ]),
            ),
          ),
        ),
      );
}

class GoogleButton extends StatelessWidget {
  const GoogleButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  static const _logo =
      '<svg viewBox="0 0 48 48"><path fill="#FFC107" d="M43.6 20.5H42V20H24v8h11.3C33.7 32.7 29.2 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.4-.4-3.5z"/><path fill="#FF3D00" d="m6.3 14.7 6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 16.3 4 9.7 8.3 6.3 14.7z"/><path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.2 0-9.6-3.3-11.3-7.9l-6.5 5C9.5 39.6 16.2 44 24 44z"/><path fill="#1976D2" d="M43.6 20.5H42V20H24v8h11.3c-.8 2.2-2.2 4.2-4.1 5.6l6.2 5.2C37 39.2 44 34 44 24c0-1.3-.1-2.4-.4-3.5z"/></svg>';

  @override
  Widget build(BuildContext context) => VitaGhostButton(
        label: label,
        onPressed: onPressed,
        loading: loading,
        leading: SvgPicture.string(_logo, width: 20, height: 20),
      );
}

/// Link chữ volt, vùng chạm tối thiểu 44px theo chiều cao.
class VitaLink extends StatelessWidget {
  const VitaLink(this.label,
      {super.key, required this.onTap, this.style = VitaText.link});
  final String label;
  final VoidCallback onTap;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
        link: true,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(widthFactor: 1, child: Text(label, style: style)),
            ),
          ),
        ),
      );
}
