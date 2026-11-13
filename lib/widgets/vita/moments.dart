import 'package:flutter/material.dart';

import '../../core/theme/vita_theme.dart';

/// Các ô Khoảnh khắc minh họa (dữ liệu mẫu) dùng để trang trí luồng vào app.
enum MomentSample { pho, salad, walk, yoga, water, steps, smoothie }

const phoAsset = 'assets/images/moments/pho.jpg';
const saladAsset = 'assets/images/moments/salad.jpg';

class MomentTile extends StatelessWidget {
  const MomentTile(this.sample, {super.key, this.size = 110});
  final MomentSample sample;
  final double size;

  @override
  Widget build(BuildContext context) {
    final k = size / 110; // tỉ lệ so với kích thước thiết kế
    final radius = BorderRadius.circular(24 * k);
    Widget body;
    switch (sample) {
      case MomentSample.pho:
      case MomentSample.salad:
        body = Image.asset(
          sample == MomentSample.pho ? phoAsset : saladAsset,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
          width: size,
          height: size,
        );
      case MomentSample.walk:
        body = Stack(fit: StackFit.expand, children: [
          const ColoredBox(color: Color(0xFF171A12)),
          CustomPaint(painter: _RoutePainter()),
          _metric('5,2 km', 'Đi bộ sáng', VitaColors.volt, k),
        ]);
      case MomentSample.yoga:
        body = _gradient(const [Color(0xFFFF7A4D), Color(0xFFC2310D)],
            _metric('20′', 'Yoga tối', Colors.white, k));
      case MomentSample.water:
        body = _gradient(const [Color(0xFF0F3A3D), Color(0xFF0B2224)],
            _metric('1,6 L', 'Nước hôm nay', VitaColors.cyan, k));
      case MomentSample.steps:
        body = ColoredBox(
            color: VitaColors.volt,
            child: _metric('8.214', 'Bước chân', VitaColors.onVolt, k));
      case MomentSample.smoothie:
        body = _gradient(const [Color(0xFF3D4A12), Color(0xFF1B2108)],
            _metric('310', 'kcal · Sinh tố bơ', const Color(0xFFE6F7A8), k));
    }
    final (name, time, avatar, reaction) = _meta[sample]!;
    final onLight = sample == MomentSample.steps;
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(fit: StackFit.expand, children: [
          body,
          if (reaction != null)
            Positioned(
              right: 7 * k,
              top: 7 * k,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 7 * k, vertical: 3 * k),
                decoration: BoxDecoration(
                    color: const Color(0xB3121212),
                    borderRadius: BorderRadius.circular(99)),
                child: Text(reaction,
                    style: TextStyle(
                        fontSize: 10 * k,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          Positioned(
            left: 7 * k,
            right: 7 * k,
            bottom: 7 * k,
            child: Row(children: [
              Container(
                width: 16 * k,
                height: 16 * k,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: avatar, shape: BoxShape.circle),
                child: Text(name[0],
                    style: TextStyle(
                        fontSize: 8 * k,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111))),
              ),
              SizedBox(width: 5 * k),
              Flexible(
                child: Text('$name · $time',
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                        fontFamily: VitaFonts.body,
                        fontSize: 10 * k,
                        fontWeight: FontWeight.w600,
                        color: onLight ? VitaColors.onVolt : Colors.white,
                        shadows: onLight
                            ? null
                            : const [
                                Shadow(color: Color(0x99000000), blurRadius: 4)
                              ])),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  static Widget _gradient(List<Color> colors, Widget child) => DecoratedBox(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors)),
      child: child);

  static Widget _metric(String value, String caption, Color color, double k) =>
      Padding(
        padding: EdgeInsets.all(12 * k),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style:
                      VitaText.metric.copyWith(fontSize: 26 * k, color: color)),
              SizedBox(height: 4 * k),
              Text(caption.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                      fontFamily: VitaFonts.body,
                      fontSize: 9.5 * k,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8 * k,
                      color: color)),
            ]),
      );

  static const _meta = <MomentSample, (String, String, Color, String?)>{
    MomentSample.pho: ('Lan', '12:04', VitaColors.coralSoft, '🔥 6'),
    MomentSample.salad: ('Mai', '12:30', VitaColors.cyan, '🥗 3'),
    MomentSample.walk: ('Huy', '6:40', VitaColors.volt, null),
    MomentSample.yoga: ('Thảo', '21:10', VitaColors.coralPale, '🔥 4'),
    MomentSample.water: ('Minh', '15:00', VitaColors.cyan, null),
    MomentSample.steps: ('Khoa', '18:22', Colors.white, null),
    MomentSample.smoothie: ('Vy', '9:15', VitaColors.volt, '🏃 2'),
  };
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s);
    final grid = Paint()
      ..color = const Color(0xFF2A2F1C)
      ..strokeWidth = 1 / s;
    for (final v in [25.0, 50.0, 75.0]) {
      canvas.drawLine(Offset(0, v), Offset(100, v), grid);
      canvas.drawLine(Offset(v, 0), Offset(v, 100), grid);
    }
    final route = Path()
      ..moveTo(14, 78)
      ..cubicTo(24, 74, 26, 58, 38, 56)
      ..cubicTo(50, 54, 52, 66, 64, 60)
      ..cubicTo(76, 54, 70, 34, 86, 30);
    canvas.drawPath(
        route,
        Paint()
          ..color = VitaColors.volt.withValues(alpha: .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(const Offset(86, 30), 4.5,
        Paint()..color = VitaColors.volt.withValues(alpha: .6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Trả về true nếu người dùng bật giảm chuyển động (hoặc đang chạy test).
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Dải Khoảnh khắc trôi ngang vô tận.
class MomentStrip extends StatefulWidget {
  const MomentStrip({
    super.key,
    required this.samples,
    this.size = 92,
    this.gap = 10,
    this.reverse = false,
    this.period = const Duration(seconds: 36),
  });

  final List<MomentSample> samples;
  final double size;
  final double gap;
  final bool reverse;
  final Duration period;

  @override
  State<MomentStrip> createState() => _MomentStripState();
}

class _MomentStripState extends State<MomentStrip>
    with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final half = widget.samples.length * (widget.size + widget.gap);
    final tiles = [
      for (var i = 0; i < 2; i++)
        for (final s in widget.samples)
          Padding(
            padding: EdgeInsets.only(right: widget.gap),
            child: MomentTile(s, size: widget.size),
          ),
    ];
    return ClipRect(
      child: SizedBox(
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            final t =
                widget.reverse ? 1 - _controller.value : _controller.value;
            return Transform.translate(
                offset: Offset(-t * half, 0), child: child);
          },
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: 0,
            maxWidth: double.infinity,
            child: RepaintBoundary(
                child: Row(mainAxisSize: MainAxisSize.min, children: tiles)),
          ),
        ),
      ),
    );
  }
}

/// Lưới 3 cột Khoảnh khắc trôi dọc (cột giữa trôi ngược chiều).
class MomentWall extends StatefulWidget {
  const MomentWall({super.key, this.gap = 10});
  final double gap;

  @override
  State<MomentWall> createState() => _MomentWallState();
}

class _MomentWallState extends State<MomentWall>
    with SingleTickerProviderStateMixin {
  // Một vòng dài 1 giờ; mỗi cột tự tính chu kỳ riêng nên không bị giật.
  late final _controller =
      AnimationController(vsync: this, duration: const Duration(hours: 1));
  static const _periods = [38.0, 46.0, 42.0];

  static const _columns = [
    [
      MomentSample.pho,
      MomentSample.walk,
      MomentSample.smoothie,
      MomentSample.water
    ],
    [
      MomentSample.yoga,
      MomentSample.salad,
      MomentSample.steps,
      MomentSample.pho
    ],
    [
      MomentSample.water,
      MomentSample.steps,
      MomentSample.pho,
      MomentSample.yoga,
      MomentSample.salad
    ],
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final size = (c.maxWidth - widget.gap * 2) / 3;
        return ClipRect(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) SizedBox(width: widget.gap),
              SizedBox(
                width: size,
                height: c.maxHeight,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    var t = (_controller.value * 3600 / _periods[i]) % 1;
                    if (i == 1) t = 1 - t;
                    final half = _columns[i].length * (size + widget.gap);
                    return Transform.translate(
                        offset: Offset(0, -t * half), child: child);
                  },
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: RepaintBoundary(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        for (var r = 0; r < 2; r++)
                          for (final s in _columns[i])
                            Padding(
                              padding: EdgeInsets.only(bottom: widget.gap),
                              child: MomentTile(s, size: size),
                            ),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        );
      });
}
