import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/vita_theme.dart';
import '../camera/camera_screen.dart';
import '../feed/feed_screen.dart';
import '../journal/journal_screen.dart';

enum HomeTab { feed, camera, journal }

/// Khung chính sau khi đăng nhập: Bảng tin · Chụp · Nhật ký. Mở vào Chụp.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static HomeShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomeShellState>();

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  HomeTab _tab = HomeTab.camera;
  HomeTab get tab => _tab;

  void go(HomeTab tab) {
    if (tab == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: VitaColors.bg,
          extendBody: true,
          body: IndexedStack(
            index: _tab.index,
            children: [
              FeedScreen(active: _tab == HomeTab.feed),
              CameraScreen(active: _tab == HomeTab.camera),
              const JournalScreen(),
            ],
          ),
          bottomNavigationBar: _TabBar(tab: _tab, onSelect: go),
        ),
      );
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tab, required this.onSelect});
  final HomeTab tab;
  final ValueChanged<HomeTab> onSelect;

  static const _items = [
    (HomeTab.feed, Icons.grid_view_rounded, 'Bảng tin'),
    (HomeTab.camera, Icons.photo_camera_rounded, 'Chụp'),
    (HomeTab.journal, Icons.menu_book_rounded, 'Nhật ký'),
  ];

  @override
  Widget build(BuildContext context) => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xE6131313),
              border: Border(top: BorderSide(color: VitaColors.lineSoft)),
            ),
            padding: EdgeInsets.only(
                top: 8, bottom: MediaQuery.paddingOf(context).bottom + 8),
            child: Row(children: [
              for (final (t, icon, label) in _items)
                Expanded(
                  child: Semantics(
                    selected: t == tab,
                    button: true,
                    label: label,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(t),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 58,
                          height: 30,
                          decoration: BoxDecoration(
                              color: t == tab
                                  ? VitaColors.volt
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(99)),
                          child: Icon(icon,
                              size: 21,
                              color: t == tab
                                  ? VitaColors.onVolt
                                  : VitaColors.muted),
                        ),
                        const SizedBox(height: 3),
                        Text(label,
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: t == tab
                                    ? VitaColors.onSurface
                                    : VitaColors.muted)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      );
}
