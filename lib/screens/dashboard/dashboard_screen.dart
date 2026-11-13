import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/models/profile.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/custom_pill.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _activity = TextEditingController();
  int _extraBurned = 0;
  @override
  void dispose() {
    _activity.dispose();
    super.dispose();
  }

  void _addActivity() {
    if (_activity.text.trim().isEmpty) return;
    setState(() {
      _extraBurned += 120;
      _activity.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã thêm hoạt động · -120 kcal (ước tính)')));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().profile!;
    final buildingMuscle = user.goal == HealthGoal.gainMuscle;
    final intake = buildingMuscle ? 2100 : 1450;
    final burned = (buildingMuscle ? 2300 : 1820) + _extraBurned;
    final balance = intake - burned;
    return SafeArea(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 25, 24, 28),
            children: [
          const Text('Tổng quan', style: AppStyles.heading),
          const SizedBox(height: 5),
          Text('Mục tiêu: ${user.effectiveTargetKcal} kcal · ${user.goalLabel}',
              style: AppStyles.bodySmall),
          const SizedBox(height: 27),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
                  border: Border.all(color: AppColors.border)),
              child: Column(children: [
                const Text('CÂN BẰNG HÔM NAY',
                    style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
                const SizedBox(height: 18),
                SizedBox(
                    width: 210,
                    height: 210,
                    child: Stack(alignment: Alignment.center, children: [
                      CustomPaint(
                          size: const Size(210, 210),
                          painter: _GaugePainter(progress: intake / burned)),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.bolt, color: AppColors.mint, size: 20),
                        const SizedBox(height: 4),
                        Text('${balance > 0 ? '+' : ''}$balance',
                            style: const TextStyle(
                                fontSize: 39,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.8)),
                        const Text('kcal', style: AppStyles.bodySmall),
                      ]),
                    ])),
                const SizedBox(height: 20),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metric('NẠP', '$intake', AppColors.amber),
                      Container(width: 1, height: 39, color: AppColors.border),
                      _metric('TIÊU', '$burned', AppColors.mint),
                    ]),
              ])),
          const SizedBox(height: 28),
          const Text('Hoạt động nhanh', style: AppStyles.title),
          const SizedBox(height: 11),
          TextField(
              controller: _activity,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addActivity(),
              decoration: InputDecoration(
                  hintText: "Gõ hoạt động (VD: 'Dọn nhà 30p')...",
                  hintStyle:
                      const TextStyle(fontSize: 13, color: AppColors.muted),
                  suffixIcon: IconButton(
                      onPressed: _addActivity,
                      tooltip: 'Thêm hoạt động',
                      icon: const Icon(Icons.arrow_upward_rounded,
                          color: AppColors.mint)))),
          const SizedBox(height: 10),
          const Align(
              alignment: Alignment.centerLeft,
              child: CustomPill(
                  child: Text('Dọn nhà 30p  ·  -120 kcal',
                      style: TextStyle(
                          color: AppColors.mint,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)))),
          const SizedBox(height: 28),
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.mint.withOpacity(.08),
                  borderRadius: BorderRadius.circular(AppStyles.radius),
                  border: Border.all(color: AppColors.mint.withOpacity(.35))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.auto_awesome, color: AppColors.mint, size: 19),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text('AI COACH · GỢI Ý HÔM NAY',
                              style: TextStyle(
                                  color: AppColors.mint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.3)))
                    ]),
                    const SizedBox(height: 14),
                    Text(
                        user.conditions.contains(MedicalCondition.jointPain)
                            ? 'Khớp gối cần nghỉ: Hôm nay hãy ĐẠP XE TĨNH 20 PHÚT thay vì chạy bộ.'
                            : buildingMuscle
                                ? 'Để hỗ trợ mục tiêu tăng cơ, hãy bổ sung một bữa giàu protein sau buổi tập.'
                                : 'Đi bộ nhanh 30 phút hôm nay để giữ nhịp vận động đều đặn.',
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            height: 1.45,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    const Text('Nội dung minh họa cho bản demo.',
                        style: AppStyles.bodySmall),
                  ])),
        ]));
  }

  Widget _metric(String label, String value, Color color) => Column(children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.muted, fontSize: 11, letterSpacing: 1.5)),
        const SizedBox(height: 5),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.w800)),
      ]);
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    final base = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = AppColors.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi * .75, math.pi * 1.5, false, base);
    canvas.drawArc(rect, -math.pi * .75, math.pi * 1.5 * progress.clamp(0, 1),
        false, fill);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
