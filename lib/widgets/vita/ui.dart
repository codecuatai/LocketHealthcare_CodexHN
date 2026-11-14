import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../core/models/social.dart';
import '../../core/theme/vita_theme.dart';

export 'moments.dart' show reduceMotion;

/// Avatar tròn chữ cái đầu, màu riêng mỗi người.
class VitaAvatar extends StatelessWidget {
  const VitaAvatar(this.person, {super.key, this.size = 36, this.ring = false});
  final Person person;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: person.color,
          shape: BoxShape.circle,
          border: ring ? Border.all(color: VitaColors.bg, width: 2) : null,
        ),
        child: Text(person.initials,
            style: TextStyle(
                fontFamily: VitaFonts.body,
                fontWeight: FontWeight.w700,
                fontSize: size * .36,
                letterSpacing: -.3,
                color: const Color(0xFF141414))),
      );
}

/// Avatar của chính mình, bấm để mở màn Cá nhân.
class MeButton extends StatelessWidget {
  const MeButton({super.key, required this.person, required this.onTap});
  final Person person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Cá nhân',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: VitaColors.surfaceHighest),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: VitaColors.bg),
              child: VitaAvatar(person, size: 36),
            ),
          ),
        ),
      );
}

class AvatarStack extends StatelessWidget {
  const AvatarStack(this.people, {super.key, this.size = 26, this.border});
  final List<Person> people;
  final double size;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final shown = people.take(3).toList();
    return SizedBox(
      height: size,
      width: shown.isEmpty ? 0 : size + (shown.length - 1) * size * .65,
      child: Stack(children: [
        for (var i = 0; i < shown.length; i++)
          Positioned(
            left: i * size * .65,
            child: Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: border ?? VitaColors.surfaceHigh, width: 2)),
              child: VitaAvatar(shown[i], size: size - 4),
            ),
          ),
      ]),
    );
  }
}

/// Nút tròn 42px có biểu tượng, có thể kèm số đỏ.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
    this.filled = true,
    this.size = 42,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int badge;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: badge > 0 ? '$label, $badge chưa đọc' : label,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: size,
          child: Stack(clipBehavior: Clip.none, children: [
            Material(
              color: filled ? VitaColors.surfaceHigh : Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Center(
                    child: Icon(icon, size: 21, color: VitaColors.onSurface)),
              ),
            ),
            if (badge > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17),
                  height: 17,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: VitaColors.coral,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: VitaColors.bg, width: 2)),
                  child: Text('$badge',
                      style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
          ]),
        ),
      );
}

/// Chip Chuỗi ngày 🔥.
class StreakChip extends StatelessWidget {
  const StreakChip(this.days, {super.key});
  final int days;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Chuỗi $days ngày',
        excludeSemantics: true,
        child: Container(
          height: 34,
          padding: const EdgeInsets.fromLTRB(9, 0, 12, 0),
          decoration: BoxDecoration(
            color: VitaColors.coral.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: VitaColors.coral.withValues(alpha: .35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.local_fire_department_rounded,
                size: 18, color: VitaColors.coral),
            const SizedBox(width: 4),
            Text('$days',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: VitaColors.coralSoft)),
          ]),
        ),
      );
}

/// Thanh tiêu đề 56px: nút trái, tiêu đề giữa, nút phải.
class VitaTopBar extends StatelessWidget {
  const VitaTopBar({super.key, this.leading, this.title, this.trailing});
  final Widget? leading;
  final Widget? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(alignment: Alignment.center, children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 56),
                child: DefaultTextStyle(
                    style: const TextStyle(
                        fontFamily: VitaFonts.display,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: VitaColors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: title!),
              ),
            Row(children: [
              leading ?? const SizedBox(width: 42),
              const Spacer(),
              trailing ?? const SizedBox(width: 42),
            ]),
          ]),
        ),
      );
}

class BackButtonRound extends StatelessWidget {
  const BackButtonRound({super.key, this.icon = Icons.arrow_back_rounded});
  final IconData icon;

  @override
  Widget build(BuildContext context) => RoundIconButton(
      icon: icon,
      label: icon == Icons.close_rounded ? 'Đóng' : 'Quay lại',
      filled: icon == Icons.close_rounded,
      onTap: () => Navigator.of(context).maybePop());
}

/// Công tắc dạng viên thuốc theo DESIGN.md.
class VitaSwitch extends StatelessWidget {
  const VitaSwitch(
      {super.key, required this.value, required this.onChanged, this.label});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: value,
        label: label,
        button: true,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(!value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                color: value ? VitaColors.volt : VitaColors.surfaceHighest,
                borderRadius: BorderRadius.circular(99)),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? VitaColors.onVolt : Colors.white),
              ),
            ),
          ),
        ),
      );
}

/// Một lựa chọn trong [PillSegmented].
class Segment<T> {
  const Segment(this.value, this.label, [this.sublabel]);
  final T value;
  final String label;
  final String? sublabel;
}

/// Nhóm nút chọn một, dạng viên thuốc nằm trong rãnh tối.
class PillSegmented<T> extends StatelessWidget {
  const PillSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.height = 40,
  });

  final List<Segment<T>> segments;
  final T? value;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: VitaColors.bg,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: VitaColors.lineSoft)),
        child: Row(children: [
          for (final s in segments)
            Expanded(
              child: Semantics(
                selected: s.value == value,
                button: true,
                label:
                    s.sublabel == null ? s.label : '${s.label}, ${s.sublabel}',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(s.value);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: height,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: s.value == value
                            ? VitaColors.volt
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(99)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(s.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13.5,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                              color: s.value == value
                                  ? VitaColors.onVolt
                                  : VitaColors.onSurfaceVariant)),
                      if (s.sublabel != null)
                        Text(s.sublabel!,
                            style: TextStyle(
                                fontSize: 10,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                                color: s.value == value
                                    ? VitaColors.onVoltVariant
                                    : VitaColors.muted)),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      );
}

/// Nhãn chữ in hoa nhỏ phía trên một nhóm.
class CapsLabel extends StatelessWidget {
  const CapsLabel(this.text, {super.key, this.color = VitaColors.muted});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: VitaText.label.copyWith(color: color));
}

/// Khối nền tối có viền mảnh, bo lớn.
class VitaCard extends StatelessWidget {
  const VitaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 26,
    this.color = VitaColors.surfaceLow,
    this.borderColor = VitaColors.lineSoft,
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  final Color borderColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: gradient == null ? color : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor),
        ),
        child: child,
      );
}

/// Viên mờ kính đặt trên ảnh.
class GlassPill extends StatelessWidget {
  const GlassPill(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.symmetric(horizontal: 12),
      this.height = 32});
  final Widget child;
  final EdgeInsets padding;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: height,
            padding: padding,
            color: const Color(0x8C121212),
            child: DefaultTextStyle(
              style: const TextStyle(
                  fontFamily: VitaFonts.body,
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              child: IconTheme(
                  data: const IconThemeData(color: Colors.white, size: 15),
                  child:
                      Row(mainAxisSize: MainAxisSize.min, children: [child])),
            ),
          ),
        ),
      );
}

/// Thẻ nhắc thêm Thông tin sức khỏe.
class HealthNudge extends StatelessWidget {
  const HealthNudge({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: VitaColors.surfaceLow,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: VitaColors.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: VitaColors.volt.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.monitor_heart_outlined,
                    size: 19, color: VitaColors.volt),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thêm Thông tin sức khỏe',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: VitaColors.onSurface)),
                      Text(text,
                          style: VitaText.caption
                              .copyWith(color: VitaColors.onSurfaceVariant)),
                    ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: VitaColors.muted),
            ]),
          ),
        ),
      );
}

/// Mở bottom sheet theo DESIGN.md (nền mờ đặc, bo 32px, có tay cầm).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool expand = false,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: VitaColors.surfaceLow,
      barrierColor: const Color(0xB8121212),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * (expand ? .9 : .86)),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              decoration: BoxDecoration(
                  color: VitaColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(4))),
          Flexible(child: Builder(builder: builder)),
        ]),
      ),
    );

/// Thông báo ngắn dạng viên ở đầu màn hình.
void showVitaToast(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  SemanticsService.sendAnnouncement(
      View.of(context), message, TextDirection.ltr);
  late final OverlayEntry entry;
  entry = OverlayEntry(
      builder: (_) => _Toast(message: message, onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.onDone});
  final String message;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
        top: MediaQuery.paddingOf(context).top + 10,
        left: 24,
        right: 24,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, child) {
              final t = _c.value;
              final o = t < .1 ? t / .1 : (t > .88 ? (1 - t) / .12 : 1.0);
              return Opacity(
                opacity: o.clamp(0, 1),
                child: Transform.translate(
                    offset: Offset(0, (1 - o) * -14), child: child),
              );
            },
            child: Center(
              child: Material(
                color: VitaColors.onSurface,
                elevation: 8,
                shadowColor: Colors.black54,
                shape: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(7, 7, 18, 7),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                          color: VitaColors.volt, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          size: 18, color: VitaColors.onVolt),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(widget.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: VitaFonts.body,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF141414))),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
