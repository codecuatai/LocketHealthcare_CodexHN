import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/vita_theme.dart';
import '../../widgets/vita/moments.dart';

/// Kích thước thiết kế của mỗi cảnh; cảnh được thu nhỏ vừa màn hình thật.
const introSceneSize = Size(320, 340);

double _iv(double t, double begin, double end,
        [Curve curve = Curves.easeOut]) =>
    curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

/// Chạy một dòng thời gian khi cảnh đang được xem; tua về đầu khi rời đi.
/// Khi người dùng bật giảm chuyển động, cảnh hiện ngay trạng thái cuối.
class _Timeline extends StatefulWidget {
  const _Timeline({
    required this.active,
    required this.duration,
    required this.builder,
    this.repeat = false,
  });

  final bool active;
  final Duration duration;
  final bool repeat;
  final Widget Function(BuildContext context, double t, bool still) builder;

  @override
  State<_Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<_Timeline>
    with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(vsync: this, duration: widget.duration);
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = reduceMotion(context);
    _sync();
  }

  @override
  void didUpdateWidget(covariant _Timeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync();
  }

  void _sync() {
    if (_still) {
      _controller.value = 1;
    } else if (widget.active) {
      widget.repeat ? _controller.repeat() : _controller.forward(from: 0);
    } else {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          widget.builder(context, _controller.value, _still));
}

/// Thẻ 1: lưới Khoảnh khắc của bạn bè, reaction bay lên.
class MomentsScene extends StatelessWidget {
  const MomentsScene({super.key, required this.active});
  final bool active;

  static const _reactions = ['🔥', '🥗', '🏃', '💪', '🔥', '🥗'];
  static const _x = [.14, .36, .58, .76, .26, .66];

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.transparent],
            stops: [.72, 1],
          ).createShader(r),
          child: Stack(children: [
            const Positioned.fill(child: MomentWall()),
            Positioned.fill(
              child: _Timeline(
                active: active,
                repeat: true,
                duration: const Duration(milliseconds: 3200),
                builder: (context, t, still) {
                  if (still) return const SizedBox.shrink();
                  return Stack(children: [
                    for (var i = 0; i < _reactions.length; i++)
                      Builder(builder: (_) {
                        final p = (t + i * .17) % 1;
                        final opacity = p < .15 ? p / .15 : 1 - (p - .15) / .85;
                        return Positioned(
                          left: introSceneSize.width * _x[i],
                          bottom: 40 + p * 240,
                          child: Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: p < .15 ? .6 + p / .15 * .5 : 1.1 - p * .2,
                              child: Text(_reactions[i],
                                  style: const TextStyle(
                                      fontSize: 26,
                                      shadows: [
                                        Shadow(
                                            color: Color(0x80000000),
                                            blurRadius: 10)
                                      ])),
                            ),
                          ),
                        );
                      }),
                  ]);
                },
              ),
            ),
          ]),
        ),
      );
}

/// Thẻ 2: quét bát phở, hiện calo và thanh dinh dưỡng.
class ScanScene extends StatelessWidget {
  const ScanScene({super.key, required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => _Timeline(
        active: active,
        duration: const Duration(milliseconds: 4400),
        builder: (context, t, _) {
          final scanning = t > .068 && t < .705;
          final pass = ((t - .068) / .637 * 2) % 1;
          final result = _iv(t, .68, .8);
          final bars = _iv(t, .77, .95, Curves.easeOutCubic);
          return Stack(clipBehavior: Clip.none, children: [
            Positioned(
              top: 6,
              left: (introSceneSize.width - 220) / 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: SizedBox.square(
                  dimension: 220,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.asset(phoAsset,
                        fit: BoxFit.cover,
                        cacheWidth: 660,
                        semanticLabel: 'Bát phở bò tái'),
                    const _Corners(),
                    if (scanning)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -60 + pass * 280,
                        height: 60,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x00C3F400), Color(0x59C3F400)]),
                            border: Border(
                                bottom: BorderSide(
                                    color: VitaColors.volt, width: 2)),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
            Positioned(
              left: 17,
              right: 17,
              bottom: 0,
              child: Opacity(
                opacity: result,
                child: Transform.translate(
                  offset: Offset(0, (1 - result) * 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: const Color(0xEB1C1B1B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: VitaColors.lineSoft),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Expanded(
                            child: Text('Phở bò tái',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: VitaColors.onSurface)),
                          ),
                          Text('480',
                              style: VitaText.metric.copyWith(
                                  fontSize: 26, color: VitaColors.onSurface)),
                          const SizedBox(width: 3),
                          const Text('kcal',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: VitaColors.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _MacroBar('Đạm', '32 g', .62, VitaColors.volt, bars),
                      const SizedBox(height: 6),
                      _MacroBar(
                          'Tinh bột', '58 g', .78, VitaColors.coralSoft, bars),
                      const SizedBox(height: 6),
                      _MacroBar('Chất béo', '12 g', .30, VitaColors.cyan, bars),
                    ]),
                  ),
                ),
              ),
            ),
          ]);
        },
      );
}

class _Corners extends StatelessWidget {
  const _Corners();

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: VitaColors.volt, width: 3);
    Widget corner(Alignment a) => Align(
          alignment: a,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              border: Border(
                top: a.y < 0 ? side : BorderSide.none,
                bottom: a.y > 0 ? side : BorderSide.none,
                left: a.x < 0 ? side : BorderSide.none,
                right: a.x > 0 ? side : BorderSide.none,
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(children: [
        corner(Alignment.topLeft),
        corner(Alignment.topRight),
        corner(Alignment.bottomLeft),
        corner(Alignment.bottomRight),
      ]),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar(this.label, this.value, this.fill, this.color, this.progress);
  final String label;
  final String value;
  final double fill;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: VitaColors.onSurfaceVariant))),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
                color: VitaColors.surfaceHighest,
                borderRadius: BorderRadius.circular(6)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fill * progress,
              child: Container(
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(6))),
            ),
          ),
        ),
        SizedBox(
            width: 44,
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: VitaColors.onSurface,
                    fontFeatures: [FontFeature.tabularFigures()]))),
      ]);
}

/// Thẻ 3: gợi ý không an toàn bị gạch, gợi ý hợp bệnh lý nền trượt vào.
class SafeSwapScene extends StatelessWidget {
  const SafeSwapScene({super.key, required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => _Timeline(
        active: active,
        duration: const Duration(milliseconds: 3000),
        builder: (context, t, _) {
          final strike = _iv(t, .27, .42);
          final dim = 1 - .55 * _iv(t, .40, .53);
          final tag = _iv(t, .37, .47, Curves.easeOutBack);
          final good = _iv(t, .57, .73);
          final why = _iv(t, .77, .93);
          return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 34,
                  padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
                  decoration: BoxDecoration(
                    color: VitaColors.surfaceLow,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: VitaColors.coralSoft.withValues(alpha: .35)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: VitaColors.coralPale, shape: BoxShape.circle),
                      child: const Text('L',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3B0900))),
                    ),
                    const SizedBox(width: 8),
                    const Text('Hồ sơ của Lan · Đau khớp gối',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: VitaColors.coralSoft)),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VitaColors.surfaceLow,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: VitaColors.lineSoft),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('GỢI Ý VẬN ĐỘNG HÔM NAY',
                            style: VitaText.label
                                .copyWith(color: VitaColors.volt)),
                        const SizedBox(height: 12),
                        Stack(clipBehavior: Clip.none, children: [
                          Opacity(
                            opacity: dim,
                            child: _Option(
                              emoji: '🏃',
                              title: 'Chạy bộ 5 km',
                              caption: '≈ 320 kcal',
                              background: VitaColors.surface,
                              iconBackground: VitaColors.surfaceHigh,
                              strike: strike,
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: -10,
                            child: Transform.scale(
                              scale: .8 + .2 * tag,
                              child: Opacity(
                                opacity: tag.clamp(0.0, 1.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: VitaColors.coral,
                                      borderRadius: BorderRadius.circular(99)),
                                  child: const Text('Nặng cho khớp gối',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Opacity(
                          opacity: good,
                          child: Transform.translate(
                            offset: Offset(0, (1 - good) * 14),
                            child: const _Option(
                              emoji: '🚴',
                              title: 'Đạp xe tĩnh 25 phút',
                              caption: '≈ 190 kcal · nhẹ nhàng cho khớp',
                              background: VitaColors.volt,
                              iconBackground: Color(0x1F161E00),
                              dark: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Opacity(
                          opacity: why,
                          child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.verified_user_outlined,
                                      size: 16, color: VitaColors.volt),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      'Đổi vì Lan bị đau khớp gối. Vẫn đốt đủ phần calo dư của hôm qua.',
                                      style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: VitaColors.onSurfaceVariant)),
                                ),
                              ]),
                        ),
                      ]),
                ),
              ]);
        },
      );
}

class _Option extends StatelessWidget {
  const _Option({
    required this.emoji,
    required this.title,
    required this.caption,
    required this.background,
    required this.iconBackground,
    this.dark = false,
    this.strike = 0,
  });

  final String emoji;
  final String title;
  final String caption;
  final Color background;
  final Color iconBackground;
  final bool dark;
  final double strike;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: iconBackground, borderRadius: BorderRadius.circular(12)),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(alignment: Alignment.centerLeft, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(
                        fontFamily: VitaFonts.display,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color:
                            dark ? VitaColors.onVolt : VitaColors.onSurface)),
                Text(caption,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: dark
                            ? VitaColors.onVoltVariant
                            : VitaColors.onSurfaceVariant)),
              ]),
              if (strike > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 11,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: strike,
                      child: Container(height: 2, color: VitaColors.coral),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      );
}

/// Thẻ 4: công tắc chia sẻ chỉ số tự tắt, các chỉ số trên ảnh mờ đi.
class PrivacyScene extends StatelessWidget {
  const PrivacyScene({super.key, required this.active});
  final bool active;

  static const _stats = ['390 kcal', '54 kg', 'Huyết áp cao'];

  @override
  Widget build(BuildContext context) => _Timeline(
        active: active,
        duration: const Duration(milliseconds: 3000),
        builder: (context, t, _) {
          final off = _iv(t, .40, .50);
          final seen = _iv(t, .77, .9);
          return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: SizedBox.square(
                dimension: 220,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(saladAsset,
                      fit: BoxFit.cover,
                      cacheWidth: 660,
                      semanticLabel: 'Đĩa salad gà'),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 12,
                    child: Wrap(spacing: 6, runSpacing: 6, children: [
                      for (var i = 0; i < _stats.length; i++)
                        Builder(builder: (_) {
                          final h = _iv(t, .53 + i * .05, .73 + i * .05);
                          return ImageFiltered(
                            imageFilter:
                                ImageFilter.blur(sigmaX: 6 * h, sigmaY: 6 * h),
                            child: Opacity(
                              opacity: 1 - .75 * h,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                    color: const Color(0xC7121212),
                                    borderRadius: BorderRadius.circular(99)),
                                child: Text(_stats[i],
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ),
                            ),
                          );
                        }),
                    ]),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Row(children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: VitaColors.cyan, shape: BoxShape.circle),
                        child: const Text('M',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111))),
                      ),
                      const SizedBox(width: 6),
                      const Text('Mai · 12:30',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Color(0x99000000), blurRadius: 4)
                              ])),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 286,
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
              decoration: BoxDecoration(
                color: VitaColors.surfaceLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VitaColors.lineSoft),
              ),
              child: Row(children: [
                const Expanded(
                  child: Text('Chia sẻ chỉ số sức khỏe',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: VitaColors.onSurface)),
                ),
                _Switch(progress: off),
              ]),
            ),
            const SizedBox(height: 14),
            Opacity(
              opacity: seen,
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_outline_rounded,
                    size: 15, color: VitaColors.volt),
                SizedBox(width: 6),
                Text('Bạn bè chỉ thấy ảnh và tên món',
                    style: TextStyle(
                        fontSize: 12.5, color: VitaColors.onSurfaceVariant)),
              ]),
            ),
          ]);
        },
      );
}

class _Switch extends StatelessWidget {
  const _Switch({required this.progress});

  /// 0 = đang bật, 1 = đã tắt.
  final double progress;

  @override
  Widget build(BuildContext context) => Container(
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color:
              Color.lerp(VitaColors.volt, VitaColors.surfaceHighest, progress),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Align(
          alignment: Alignment(math.max(-1, 1 - 2 * progress), 0),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Color.lerp(VitaColors.onVolt, Colors.white, progress),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
}
