import 'package:flutter/material.dart';

import '../../core/theme/vita_theme.dart';
import '../../data/intro/intro_store.dart';
import 'intro_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

enum _Page { intro, login, register }

/// Luồng khi chưa đăng nhập: Giới thiệu (lần đầu) → Đăng ký / Đăng nhập.
/// Đăng nhập thành công thì AuthController đổi trạng thái và cổng ngoài
/// tự chuyển sang app.
class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key, required this.introStore});
  final IntroStore introStore;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  late _Page _page = widget.introStore.seen ? _Page.login : _Page.intro;
  String _email = '';

  void _show(_Page page, [String email = '']) => setState(() {
        _page = page;
        _email = email;
      });

  void _finishIntro(IntroExit exit) {
    widget.introStore.markSeen();
    _show(exit == IntroExit.register ? _Page.register : _Page.login);
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: vitaTheme(),
        child: PopScope(
          // Nút Back trên Android: từ Đăng ký quay về Đăng nhập.
          canPop: _page != _Page.register,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _show(_Page.login);
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, .03), end: Offset.zero)
                    .animate(animation),
                child: child,
              ),
            ),
            child: switch (_page) {
              _Page.intro => IntroScreen(
                  key: const ValueKey('intro'), onFinish: _finishIntro),
              _Page.login => LoginScreen(
                  key: ValueKey('login:$_email'),
                  initialEmail: _email,
                  onRegister: (email) => _show(_Page.register, email)),
              _Page.register => RegisterScreen(
                  key: ValueKey('register:$_email'),
                  initialEmail: _email,
                  onLogin: (email) => _show(_Page.login, email)),
            },
          ),
        ),
      );
}
