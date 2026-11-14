import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/analysis.dart';
import '../../core/models/photo.dart';
import '../../core/theme/vita_theme.dart';
import '../../data/app_services.dart';
import '../../providers/health_controller.dart';
import '../../widgets/vita/ui.dart';
import '../../widgets/vita/vita_buttons.dart';
import '../personal/health_info_screen.dart';
import 'activity_result_screen.dart';
import 'meal_result_screen.dart';

/// Bắt đầu từ một tấm ảnh vừa chụp hoặc chọn: nhắc thiết lập (một lần),
/// rồi để AI xem ảnh. Các màn kết quả tự báo "Đã ghi" khi lưu.
Future<void> startCapture(BuildContext context, Photo photo) async {
  final health = context.read<HealthController>();
  if (health.shouldPromptBeforeCapture) {
    final setUp = await showAppSheet<bool>(context,
        builder: (_) => const HealthPromptSheet());
    health.markPromptShown();
    if (!context.mounted || setUp == null) return;
    if (setUp) {
      await Navigator.of(context).push(HealthInfoScreen.route());
      return;
    }
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(AnalyzeScreen.route(photo));
}

/// Lời nhắc trước lần chụp đầu khi chưa có Thông tin sức khỏe.
class HealthPromptSheet extends StatelessWidget {
  const HealthPromptSheet({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Cho AI biết đôi chút về cậu', style: VitaText.sheetTitle),
          const SizedBox(height: 8),
          const Text(
              'Mất khoảng 1 phút. Calo món ăn vẫn tính được ngay, nhưng có Thông tin sức khỏe thì AI làm được nhiều hơn:',
              style: VitaText.bodySmall),
          const SizedBox(height: 16),
          for (final (icon, title, text) in const [
            (
              Icons.shield_outlined,
              'Cảnh báo theo bệnh lý nền',
              'Món nào nên điều chỉnh, món nào nên tránh'
            ),
            (
              Icons.local_fire_department_outlined,
              'Calo tiêu hao khi vận động',
              'Cần cân nặng của cậu để tính'
            ),
            (
              Icons.flag_outlined,
              'Mục tiêu calo mỗi ngày',
              'Tính theo cơ thể và mục tiêu của cậu'
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: VitaColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 19, color: VitaColors.volt),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: VitaColors.onSurface)),
                        Text(text, style: VitaText.caption),
                      ]),
                ),
              ]),
            ),
          const SizedBox(height: 4),
          const Row(children: [
            Icon(Icons.lock_outline_rounded, size: 14, color: VitaColors.muted),
            SizedBox(width: 6),
            Expanded(
                child: Text('Chỉ cậu và AI dùng. Bạn bè không bao giờ thấy.',
                    style: VitaText.caption)),
          ]),
          const SizedBox(height: 18),
          VitaPrimaryButton(
              label: 'Thiết lập ngay',
              showArrow: false,
              onPressed: () => Navigator.of(context).pop(true)),
          const SizedBox(height: 8),
          VitaGhostButton(
              label: 'Để sau',
              onPressed: () => Navigator.of(context).pop(false)),
        ]),
      );
}

/// "Đang xem ảnh…": AI lọc ảnh rồi chuyển sang màn kết quả phù hợp.
class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key, required this.photo});
  final Photo photo;

  static Route<void> route(Photo photo) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => AnalyzeScreen(photo: photo),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      );

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300));
  String? _status;
  bool _hit = false;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!reduceMotion(context)) _sweep.repeat(reverse: true);
      _run();
    });
  }

  @override
  void dispose() {
    _cancelled = true;
    _sweep.dispose();
    super.dispose();
  }

  void _show(String status, {bool hit = false}) => setState(() {
        _status = status;
        _hit = hit;
      });

  AppServices get _services => context.read<AppServices>();

  Future<void> _run() async {
    final verdict = await _services.vision.classify(widget.photo);
    if (_cancelled || !mounted) return;
    _sweep.stop();
    switch (verdict) {
      case FoodPhoto(:final label):
        _show('Món ăn · $label', hit: true);
        await _openMeal();
      case ActivityPhoto(:final type):
        _show('Vận động${type == null ? '' : ' · ${type.label}'}', hit: true);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (_cancelled || !mounted) return;
        Navigator.of(context)
            .pushReplacement(ActivityResultScreen.route(widget.photo, type));
      case UncertainPhoto(:final detail):
        _show('Chưa chắc chắn');
        await _askUncertain(detail);
      case RejectedPhoto():
        _show('Không thấy món ăn hay vận động');
        await _askRejected();
    }
  }

  Future<void> _openMeal() async {
    final health = context.read<HealthController>().info;
    final analysis =
        await _services.vision.analyzeFood(widget.photo, health: health);
    if (_cancelled || !mounted) return;
    Navigator.of(context)
        .pushReplacement(MealResultScreen.route(widget.photo, analysis));
  }

  void _openActivity() => Navigator.of(context)
      .pushReplacement(ActivityResultScreen.route(widget.photo, null));

  Future<void> _askUncertain(String detail) async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      barrierColor: const Color(0xA8121212),
      builder: (_) => _GateDialog(
        photo: widget.photo,
        title: 'Đây là ảnh lúc cậu vận động?',
        body: detail,
        actions: const [
          ('activity', 'Đúng, ghi hoạt động', true),
          ('food', 'Không, đây là đồ uống', false),
          ('retake', 'Chụp lại', false),
        ],
      ),
    );
    await _follow(choice);
  }

  Future<void> _askRejected() async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      barrierColor: const Color(0xA8121212),
      builder: (_) => _GateDialog(
        photo: widget.photo,
        rejected: true,
        title: 'Ảnh này không có món ăn hay lúc vận động',
        body:
            'VitaSnap chỉ nhận ảnh bữa ăn, đồ uống và lúc tập luyện, để Bảng tin của cậu và bạn bè luôn đúng chủ đề.',
        actions: const [
          ('retake', 'Chụp lại', true),
          ('food', 'Đây là món ăn', false),
          ('activity', 'Đây là lúc vận động', false),
        ],
      ),
    );
    await _follow(choice);
  }

  Future<void> _follow(String? choice) async {
    if (!mounted) return;
    switch (choice) {
      case 'food':
        _show('Đang tính calo…', hit: false);
        await _openMeal();
      case 'activity':
        _openActivity();
      default:
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VitaColors.bg,
        body: SafeArea(
          child: Column(children: [
            const VitaTopBar(
                leading: BackButtonRound(icon: Icons.close_rounded)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Stack(fit: StackFit.expand, children: [
                    Image(image: widget.photo.image, fit: BoxFit.cover),
                    if (_status == null)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (_, c) => AnimatedBuilder(
                            animation: _sweep,
                            builder: (_, child) => Transform.translate(
                                offset: Offset(0,
                                    -120 + (c.maxHeight + 120) * _sweep.value),
                                child: child),
                            child: const Align(
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                height: 120,
                                width: double.infinity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0x00C3F400),
                                          Color(0x47C3F400)
                                        ]),
                                    border: Border(
                                        bottom: BorderSide(
                                            color: VitaColors.volt, width: 2)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 18,
                      child: Center(
                          child: _StatusPill(status: _status, hit: _hit)),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(
              height: 64,
              child: Center(
                  child: Text('AI đang kiểm tra ảnh trước khi phân tích',
                      style: VitaText.caption)),
            ),
          ]),
        ),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.hit});
  final String? status;
  final bool hit;

  @override
  Widget build(BuildContext context) {
    final text = status ?? 'Đang xem ảnh…';
    final content = Row(mainAxisSize: MainAxisSize.min, children: [
      if (status == null && reduceMotion(context))
        const Icon(Icons.hourglass_top_rounded, size: 17, color: Colors.white)
      else if (status == null)
        const SizedBox.square(
            dimension: 15,
            child: CircularProgressIndicator(
                strokeWidth: 2.2, color: Colors.white))
      else
        Icon(hit ? Icons.check_rounded : Icons.info_outline_rounded,
            size: 17, color: hit ? VitaColors.onVolt : Colors.white),
      const SizedBox(width: 8),
      Text(text,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: hit ? VitaColors.onVolt : Colors.white)),
    ]);
    return Semantics(
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: hit
          ? Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: VitaColors.volt,
                  borderRadius: BorderRadius.circular(99)),
              child: content)
          : GlassPill(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: content),
    );
  }
}

class _GateDialog extends StatelessWidget {
  const _GateDialog({
    required this.photo,
    required this.title,
    required this.body,
    required this.actions,
    this.rejected = false,
  });

  final Photo photo;
  final String title;
  final String body;

  /// (giá trị trả về, nhãn, là nút chính)
  final List<(String, String, bool)> actions;
  final bool rejected;

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: VitaColors.surfaceLow,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: VitaColors.lineSoft)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 140,
                    child: ColorFiltered(
                      colorFilter: rejected
                          ? const ColorFilter.mode(
                              Color(0x99000000), BlendMode.darken)
                          : const ColorFilter.mode(
                              Colors.transparent, BlendMode.dst),
                      child: Image(image: photo.image, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (rejected) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          color: VitaColors.error.withValues(alpha: .12),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: VitaColors.error),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(title, style: VitaText.sheetTitle.copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                Text(body, style: VitaText.bodySmall),
                const SizedBox(height: 18),
                for (final (value, label, primary) in actions) ...[
                  if (primary)
                    VitaPrimaryButton(
                        label: label,
                        showArrow: false,
                        onPressed: () => Navigator.of(context).pop(value))
                  else if (actions.last.$1 != value)
                    VitaGhostButton(
                        label: label,
                        onPressed: () => Navigator.of(context).pop(value))
                  else
                    Center(
                      child: VitaLink(label,
                          onTap: () => Navigator.of(context).pop(value)),
                    ),
                  const SizedBox(height: 8),
                ],
              ]),
        ),
      );
}
