import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_shell.dart';

/// Navigator riêng của phiên đăng nhập: mọi màn mở sau khi đăng nhập nằm
/// trong đây, bên dưới dữ liệu phiên. Đăng xuất là huỷ gọn cả phiên lẫn các
/// màn đang mở.
class SessionNavigator extends StatefulWidget {
  const SessionNavigator({super.key});

  @override
  State<SessionNavigator> createState() => _SessionNavigatorState();
}

class _SessionNavigatorState extends State<SessionNavigator> {
  final _nav = GlobalKey<NavigatorState>();
  final _shell = GlobalKey<HomeShellState>();

  /// Back của Android: đóng màn đang mở, rồi về tab Chụp, rồi mới thoát app.
  void _onBack() {
    final nav = _nav.currentState;
    if (nav == null) return;
    if (nav.canPop()) {
      nav.maybePop();
      return;
    }
    final shell = _shell.currentState;
    if (shell != null && shell.tab != HomeTab.camera) {
      shell.go(HomeTab.camera);
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: Navigator(
          key: _nav,
          onGenerateInitialRoutes: (_, __) => [
            MaterialPageRoute(builder: (_) => HomeShell(key: _shell)),
          ],
        ),
      );
}
