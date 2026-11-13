import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/models/nutrition_model.dart';
import '../../core/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_pill.dart';
import 'ai_result_sheet.dart';

class CameraHomeScreen extends StatelessWidget {
  const CameraHomeScreen(
      {super.key, required this.onShare, required this.onActivity});
  final VoidCallback onShare;
  final VoidCallback onActivity;

  void _showSwitcher(BuildContext context) {
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        builder: (sheetContext) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Đổi hồ sơ', style: AppStyles.title),
                      const SizedBox(height: 8),
                      const Text('Xem gợi ý cá nhân hóa cho từng người.',
                          style: AppStyles.bodySmall),
                      const SizedBox(height: 16),
                      _profileTile(
                          sheetContext, DemoPreset.userA, UserModel.demoA),
                      _profileTile(
                          sheetContext, DemoPreset.userB, UserModel.demoB),
                      const SizedBox(height: 8),
                      TextButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            context.read<AuthProvider>().logout();
                          },
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Đăng xuất')),
                    ]))));
  }

  Widget _profileTile(
          BuildContext sheetContext, DemoPreset preset, UserModel user) =>
      ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
              backgroundColor: AppColors.mint.withOpacity(.14),
              child: const Icon(Icons.person, color: AppColors.mint)),
          title: Text(user.name),
          subtitle: Text(user.preset == DemoPreset.userA
              ? 'Khớp gối + Huyết áp · 1.800 kcal'
              : 'Gymmer · 2.600 kcal'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            sheetContext.read<AuthProvider>().switchDemoUser(preset);
            Navigator.pop(sheetContext);
          });

  void _snap(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        builder: (sheetContext) => AiResultSheet(onShare: () {
          Navigator.pop(sheetContext);
          onShare();
        }),
      );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    return SafeArea(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                  child: CustomPill(
                      onTap: () => _showSwitcher(context),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.person_outline,
                            color: AppColors.mint, size: 18),
                        const SizedBox(width: 7),
                        Flexible(
                            child: Text(
                                user.preset == DemoPreset.userA
                                    ? '${user.name} (Khớp gối)'
                                    : user.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12))),
                        const SizedBox(width: 7),
                        const Text('· Đổi',
                            style: TextStyle(
                                color: AppColors.mint,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ]))),
              const SizedBox(height: 25),
              const Text('Chụp bữa ăn', style: AppStyles.heading),
              const SizedBox(height: 5),
              const Text('Một tấm ảnh, hiểu rõ hơn về bữa ăn của bạn.',
                  style: AppStyles.bodySmall),
              const SizedBox(height: 24),
              Expanded(
                  child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusLarge),
                      child: Stack(fit: StackFit.expand, children: [
                        Image.asset(NutritionModel.phoBoTai.assetPath,
                            fit: BoxFit.cover),
                        Container(color: Colors.black.withOpacity(.33)),
                        CustomPaint(painter: _ReticlePainter()),
                        const Center(
                            child: Icon(Icons.center_focus_strong,
                                size: 38, color: Colors.white70)),
                        const Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Center(
                                child: CustomPill(
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                  Icon(Icons.auto_awesome,
                                      color: AppColors.mint, size: 16),
                                  SizedBox(width: 7),
                                  Flexible(
                                      child: Text('Đưa món ăn vào khung hình',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 12)))
                                ])))),
                      ]))),
              const SizedBox(height: 25),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                SizedBox(
                    width: 92,
                    child: TextButton.icon(
                        onPressed: onActivity,
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.zero),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Hoạt động',
                            style: TextStyle(fontSize: 11)))),
                Semantics(
                    label: 'Chụp ảnh bữa ăn',
                    button: true,
                    child: GestureDetector(
                        onTap: () => _snap(context),
                        child: Container(
                            width: 80,
                            height: 80,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.white, width: 3)),
                            child: const DecoratedBox(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.white))))),
                const SizedBox(
                    width: 92,
                    child: Center(
                        child: CustomPill(
                            padding: EdgeInsets.symmetric(
                                horizontal: 9, vertical: 9),
                            child: Text('-350 kcal',
                                style: TextStyle(
                                    color: AppColors.mint,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11))))),
              ]),
            ])));
  }
}

class _ReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withOpacity(.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const inset = 25.0;
    const length = 29.0;
    for (final x in [inset, size.width - inset]) {
      for (final y in [inset, size.height - inset]) {
        final dx = x == inset ? 1.0 : -1.0;
        final dy = y == inset ? 1.0 : -1.0;
        final path = Path()
          ..moveTo(x, y + dy * length)
          ..lineTo(x, y + dy * 9)
          ..quadraticBezierTo(x, y, x + dx * 9, y)
          ..lineTo(x + dx * length, y);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
