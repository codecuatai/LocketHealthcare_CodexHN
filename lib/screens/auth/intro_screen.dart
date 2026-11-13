import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/vita_theme.dart';
import '../../widgets/vita/moments.dart';
import '../../widgets/vita/vita_brand.dart';
import '../../widgets/vita/vita_buttons.dart';
import 'intro_scenes.dart';

enum IntroExit { register, login }

class _Slide {
  const _Slide(this.title, this.accent, this.body, this.scene);
  final String title;
  final String accent;
  final String body;
  final Widget Function(bool active) scene;
}

final _slides = [
  _Slide(
      'Khoảnh khắc khỏe, ',
      'cùng bạn thân.',
      'Chia sẻ bữa ăn và buổi vận động với vài người bạn thân. Chỉ ảnh ăn uống và vận động, nên bảng tin luôn đúng chủ đề.',
      (active) => MomentsScene(active: active)),
  _Slide(
      'Chụp là biết ',
      'calo.',
      'AI nhận ra món ăn, kể cả phở hay cơm tấm, rồi ước lượng calo, đạm, tinh bột và chất béo cho bạn.',
      (active) => ScanScene(active: active)),
  _Slide(
      'Gợi ý hợp với ',
      'cơ thể bạn.',
      'Có bệnh lý nền? Mọi gợi ý ăn uống và vận động đều tránh điều không an toàn, kèm lý do rõ ràng.',
      (active) => SafeSwapScene(active: active)),
  _Slide(
      'Bạn bè chỉ thấy ',
      'điều bạn muốn.',
      'Cân nặng, bệnh lý nền và số calo luôn ẩn khỏi bạn bè, trừ khi bạn tự bật chia sẻ.',
      (active) => PrivacyScene(active: active)),
];

/// Màn Giới thiệu, chỉ hiện ở lần mở app đầu tiên.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.onFinish});
  final ValueChanged<IntroExit> onFinish;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pages = PageController();
  int _index = 0;
  Timer? _auto;

  // Khu điều khiển cố định để chấm trang không bao giờ bị đẩy lên xuống.
  static const _rowHeight = 60.0;
  static const _finalHeight = 118.0;
  static const _controlsHeight = _rowHeight + 14 + _finalHeight + 24;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  void _schedule({bool afterUser = false}) {
    _auto?.cancel();
    if (_isLast || reduceMotion(context)) return;
    _auto = Timer(Duration(milliseconds: afterUser ? 7000 : 5200), () {
      if (mounted) _goTo(_index + 1);
    });
  }

  void _goTo(int index) => _pages.animateToPage(index,
      duration: const Duration(milliseconds: 480), curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _auto?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: VitaColors.bg,
        body: Stack(children: [
          Listener(
            onPointerDown: (_) => _auto?.cancel(),
            onPointerUp: (_) => _schedule(afterUser: true),
            child: PageView.builder(
              controller: _pages,
              itemCount: _slides.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _schedule(afterUser: true);
              },
              itemBuilder: (context, i) => _IntroPage(
                slide: _slides[i],
                active: i == _index,
                index: i,
                padding: EdgeInsets.only(
                    top: padding.top + 64,
                    bottom: padding.bottom + _controlsHeight),
              ),
            ),
          ),
          Positioned(
            top: padding.top + 10,
            left: 20,
            right: 20,
            child: Row(children: [
              const VitaBrand(),
              const Spacer(),
              TextButton(
                onPressed: () => widget.onFinish(IntroExit.register),
                style: TextButton.styleFrom(
                  backgroundColor: VitaColors.surfaceHigh.withValues(alpha: .8),
                  foregroundColor: VitaColors.onSurface,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 36),
                  textStyle: const TextStyle(
                      fontFamily: VitaFonts.body,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                child: const Text('Bỏ qua'),
              ),
            ]),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: padding.bottom + 24,
            height: _controlsHeight - 24,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: _rowHeight,
                    child: Row(children: [
                      _Dots(count: _slides.length, index: _index, onTap: _goTo),
                      const Spacer(),
                      IgnorePointer(
                        ignoring: _isLast,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isLast ? 0 : 1,
                          child: _NextButton(onTap: () => _goTo(_index + 1)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: _finalHeight,
                    child: IgnorePointer(
                      ignoring: !_isLast,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _isLast ? 1 : 0,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          offset: _isLast ? Offset.zero : const Offset(0, .08),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                VitaPrimaryButton(
                                    label: 'Tạo tài khoản',
                                    onPressed: () =>
                                        widget.onFinish(IntroExit.register)),
                                const SizedBox(height: 10),
                                VitaGhostButton(
                                    label: 'Tôi đã có tài khoản',
                                    onPressed: () =>
                                        widget.onFinish(IntroExit.login)),
                              ]),
                        ),
                      ),
                    ),
                  ),
                ]),
          ),
        ]),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.slide,
    required this.active,
    required this.index,
    required this.padding,
  });

  final _Slide slide;
  final bool active;
  final int index;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FittedBox(
                child: SizedBox.fromSize(
                    size: introSceneSize,
                    child: ExcludeSemantics(child: slide.scene(active))),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: Semantics(
              header: true,
              label:
                  'Thẻ ${index + 1} trên ${_slides.length}. ${slide.title}${slide.accent}',
              excludeSemantics: true,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: slide.title),
                  TextSpan(
                      text: slide.accent,
                      style: const TextStyle(color: VitaColors.volt)),
                ]),
                style: VitaText.heroTitle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Text(slide.body, style: VitaText.body),
          ),
        ]),
      );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.onTap});
  final int count;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < count; i++)
          Semantics(
            button: true,
            selected: i == index,
            label: 'Thẻ ${i + 1}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: i == index ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == index
                        ? VitaColors.volt
                        : VitaColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
      ]);
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Thẻ tiếp theo',
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: const BoxDecoration(
              shape: BoxShape.circle, boxShadow: VitaShadows.glow),
          child: Material(
            color: VitaColors.volt,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: const SizedBox.square(
                dimension: 60,
                child: Icon(Icons.arrow_forward_rounded,
                    color: VitaColors.onVolt, size: 24),
              ),
            ),
          ),
        ),
      );
}
