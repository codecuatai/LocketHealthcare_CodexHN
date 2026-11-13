import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/vita_theme.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/vita/moments.dart';
import '../../widgets/vita/vita_brand.dart';
import '../../widgets/vita/vita_buttons.dart';

/// Hiện trong lúc kiểm tra phiên đăng nhập đã lưu hoặc đang tải Hồ sơ.
class AuthSplashScreen extends StatelessWidget {
  const AuthSplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Theme(
        data: vitaTheme(),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light
              .copyWith(statusBarColor: Colors.transparent),
          child: Scaffold(
            backgroundColor: VitaColors.bg,
            body: Stack(fit: StackFit.expand, children: [
              const Opacity(
                  opacity: .2, child: ExcludeSemantics(child: MomentWall())),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                      colors: [Color(0xE6131313), Color(0x80131313)],
                      radius: .8),
                ),
              ),
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: .6, end: 1),
                    duration: reduceMotion(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 650),
                    curve: Curves.easeOutBack,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: const VitaMark(size: 76),
                  ),
                  const SizedBox(height: 18),
                  Text('VITASNAP',
                      style: VitaText.brand
                          .copyWith(fontSize: 44, letterSpacing: -1.3)),
                  const SizedBox(height: 6),
                  const Text('Khoảnh khắc khỏe, cùng bạn bè.',
                      style: VitaText.body),
                ]),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.paddingOf(context).bottom + 64,
                child: Center(
                  child: SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        value: reduceMotion(context) ? .4 : null,
                        color: VitaColors.volt,
                        backgroundColor: VitaColors.surfaceHigh,
                        semanticsLabel: 'Đang mở VitaSnap',
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}

/// Có Tài khoản nhưng chưa tải được Hồ sơ (thường do mất mạng).
class ProfileErrorScreen extends StatefulWidget {
  const ProfileErrorScreen({super.key});

  @override
  State<ProfileErrorScreen> createState() => _ProfileErrorScreenState();
}

class _ProfileErrorScreenState extends State<ProfileErrorScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await context.read<AuthController>().retryProfile();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Theme(
      data: vitaTheme(),
      child: Scaffold(
        backgroundColor: VitaColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                      alignment: Alignment.centerLeft, child: VitaBrand()),
                  const Spacer(),
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: VitaColors.surfaceHigh, shape: BoxShape.circle),
                    child: const Icon(Icons.cloud_off_rounded,
                        color: VitaColors.coralSoft, size: 30),
                  ),
                  const SizedBox(height: 20),
                  const Text('Chưa tải được hồ sơ', style: VitaText.headline),
                  const SizedBox(height: 10),
                  Text(
                      auth.profileFailure?.message ??
                          'Kiểm tra mạng rồi thử lại.',
                      style: VitaText.body),
                  const Spacer(flex: 2),
                  VitaPrimaryButton(
                      label: 'Thử lại',
                      showArrow: false,
                      loading: _retrying,
                      onPressed: _retry),
                  const SizedBox(height: 10),
                  VitaGhostButton(label: 'Đăng xuất', onPressed: auth.signOut),
                ]),
          ),
        ),
      ),
    );
  }
}

/// Hiện khi app chưa được cắm cấu hình Firebase/Supabase.
class SetupRequiredApp extends StatelessWidget {
  const SetupRequiredApp({super.key, required this.details});
  final String details;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: vitaTheme(),
        home: Scaffold(
          body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const Align(alignment: Alignment.centerLeft, child: VitaBrand()),
              const SizedBox(height: 28),
              const Text('Chưa cấu hình backend', style: VitaText.headline),
              const SizedBox(height: 12),
              const Text(
                  'Làm theo docs/setup-backend.md để tạo project Firebase và Supabase, '
                  'rồi chạy lại app với file env.',
                  style: VitaText.body),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: VitaColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: VitaColors.lineSoft)),
                child: SelectableText(details, style: VitaText.bodySmall),
              ),
            ]),
          ),
        ),
      );
}
