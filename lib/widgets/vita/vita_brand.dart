import 'package:flutter/material.dart';

import '../../core/theme/vita_theme.dart';

/// Logo VitaSnap: nút chụp (vòng tròn) với nhịp tim chạy ngang.
class VitaMark extends StatelessWidget {
  const VitaMark({super.key, this.size = 30});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
      dimension: size, child: CustomPaint(painter: _MarkPainter()));
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    canvas.scale(s);
    canvas.drawCircle(
        const Offset(20, 20), 19, Paint()..color = VitaColors.volt);
    final stroke = Paint()
      ..color = VitaColors.onVolt
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(const Offset(20, 20), 11.5, stroke..strokeWidth = 3.2);
    final pulse = Path()
      ..moveTo(11.5, 20.5)
      ..lineTo(15.5, 20.5)
      ..lineTo(17.7, 15.9)
      ..lineTo(21.3, 24.5)
      ..lineTo(23.5, 20.5)
      ..lineTo(28.4, 20.5);
    canvas.drawPath(pulse, stroke..strokeWidth = 2.4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VitaBrand extends StatelessWidget {
  const VitaBrand({super.key, this.showWordmark = true});
  final bool showWordmark;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'VitaSnap',
        child: ExcludeSemantics(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const VitaMark(),
            if (showWordmark) ...[
              const SizedBox(width: 10),
              const Text('VITASNAP', style: VitaText.brand),
            ],
          ]),
        ),
      );
}
