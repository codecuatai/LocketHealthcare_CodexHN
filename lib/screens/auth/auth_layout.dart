import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../core/theme/vita_theme.dart';
import '../../widgets/vita/moments.dart';
import '../../widgets/vita/vita_brand.dart';
import '../../widgets/vita/vita_buttons.dart';

/// Khung chung cho Đăng nhập / Đăng ký: form nằm trên cùng, không phải cuộn;
/// phần trống phía dưới là dải Khoảnh khắc trang trí. Khi bàn phím mở, tiêu đề
/// thu gọn và [form] nhận `keyboardOpen = true` để ẩn bớt phần phụ.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.form,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> Function(bool keyboardOpen) form;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: VitaColors.bg,
        resizeToAvoidBottomInset: true,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.bottomCenter,
              radius: 1.1,
              colors: [Color(0x1AC3F400), Color(0x00131313)],
              stops: [0, .7],
            ),
          ),
          child: SafeArea(
            bottom: false,
            // Form có chiều cao thật; phần trang trí chỉ lấp chỗ còn trống. Màn
            // hình quá thấp thì cuộn được, để không bao giờ cắt mất form.
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          alignment: Alignment.topLeft,
                          child: keyboardOpen
                              ? Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 12, 20, 14),
                                  child: Row(children: [
                                    const VitaMark(size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Semantics(
                                        header: true,
                                        child: Text(title,
                                            style: VitaText.headline
                                                .copyWith(fontSize: 22)),
                                      ),
                                    ),
                                  ]),
                                )
                              : Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 14, 20, 16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const VitaBrand(),
                                        const SizedBox(height: 14),
                                        Semantics(
                                            header: true,
                                            child: Text(title,
                                                style: VitaText.headline)),
                                        if (subtitle != null) ...[
                                          const SizedBox(height: 6),
                                          Text(subtitle!,
                                              style: VitaText.bodySmall),
                                        ],
                                      ]),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: form(keyboardOpen)),
                        ),
                        const SizedBox(height: 16),
                      ]),
                ),
                if (!keyboardOpen)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ZeroIntrinsic(child: AuthDecoration()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hai dải Khoảnh khắc chạy ngược chiều nhau, tự co theo chỗ trống còn lại.
class AuthDecoration extends StatelessWidget {
  const AuthDecoration({super.key});

  static const _top = [
    MomentSample.pho,
    MomentSample.walk,
    MomentSample.yoga,
    MomentSample.salad,
    MomentSample.water,
    MomentSample.smoothie,
    MomentSample.steps,
  ];
  static const _bottom = [
    MomentSample.steps,
    MomentSample.salad,
    MomentSample.smoothie,
    MomentSample.pho,
    MomentSample.yoga,
    MomentSample.walk,
    MomentSample.water,
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ExcludeSemantics(
      child: LayoutBuilder(builder: (context, constraints) {
        const gap = 10.0;
        final room = constraints.maxHeight - 24 - bottomInset;
        if (room < 56) return const SizedBox.shrink();
        final twoRows = room >= 56 * 2 + gap;
        final size =
            (twoRows ? (room - gap) / 2 : room).clamp(56.0, 116.0).toDouble();
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black],
            stops: [0, .45],
          ).createShader(rect),
          child: Padding(
            padding: EdgeInsets.only(bottom: 24 + bottomInset),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              MomentStrip(samples: _top, size: size),
              if (twoRows) ...[
                const SizedBox(height: gap),
                MomentStrip(
                    samples: _bottom,
                    size: size,
                    reverse: true,
                    period: const Duration(seconds: 44)),
              ],
            ]),
          ),
        );
      }),
    );
  }
}

/// Vạch "HOẶC" giữa nút chính và nút Google.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Row(children: [
          const Expanded(child: Divider(color: VitaColors.lineSoft, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('HOẶC', style: VitaText.label.copyWith(fontSize: 11)),
          ),
          const Expanded(child: Divider(color: VitaColors.lineSoft, height: 1)),
        ]),
      );
}

/// Dòng chuyển qua lại giữa Đăng nhập và Đăng ký.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink(
      {super.key,
      required this.prompt,
      required this.action,
      required this.onTap});
  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(prompt, style: VitaText.bodySmall),
          VitaLink(action,
              onTap: onTap, style: VitaText.link.copyWith(fontSize: 14)),
        ],
      );
}

/// SliverFillRemaining đo chiều cao "tự nhiên" của nội dung để quyết định có
/// cần cuộn không. Phần trang trí chỉ lấp chỗ trống nên khai chiều cao tự nhiên
/// bằng 0, để nó không bao giờ là lý do khiến form phải cuộn.
class _ZeroIntrinsic extends SingleChildRenderObjectWidget {
  const _ZeroIntrinsic({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderZeroIntrinsic();
}

class _RenderZeroIntrinsic extends RenderProxyBox {
  @override
  double computeMinIntrinsicHeight(double width) => 0;
  @override
  double computeMaxIntrinsicHeight(double width) => 0;
  @override
  double computeMinIntrinsicWidth(double height) => 0;
  @override
  double computeMaxIntrinsicWidth(double height) => 0;
}
