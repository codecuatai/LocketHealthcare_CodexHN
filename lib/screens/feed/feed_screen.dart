import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/social.dart';
import '../../core/theme/vita_theme.dart';
import '../../providers/session_scope.dart';
import '../../providers/social_controllers.dart';
import '../../widgets/vita/ui.dart';
import '../../widgets/vita/vita_buttons.dart';
import '../capture/share_panel.dart' show PickRow;
import '../chat/inbox_screen.dart';
import '../personal/friends_screen.dart';
import '../personal/personal_screen.dart';
import '../shell/home_shell.dart';
import 'moment_card.dart';

/// Bảng tin: mỗi Khoảnh khắc một thẻ, vuốt dọc từng thẻ một.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.active});

  /// Tab đang hiện; chỉ tính "đã xem" khi người dùng thật sự đang nhìn.
  final bool active;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const seenAfter = Duration(milliseconds: 1500);

  final _pages = PageController();
  int _page = 0;
  Timer? _seenTimer;
  String? _lastFilter;

  @override
  void didUpdateWidget(FeedScreen old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) _scheduleSeen();
  }

  @override
  void dispose() {
    _seenTimer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _scheduleSeen() {
    _seenTimer?.cancel();
    if (!widget.active) return;
    final moments = context.read<MomentsController>();
    final list = moments.visible;
    if (_page >= list.length) return;
    final m = list[_page];
    if (!m.unseen) return;
    _seenTimer = Timer(seenAfter, () {
      if (mounted && widget.active) moments.markSeen(m);
    });
  }

  Future<void> _pickFriend() async {
    final moments = context.read<MomentsController>();
    final picked = await showAppSheet<_Filter>(context,
        builder: (_) => const _FriendFilterSheet());
    if (picked == null || !mounted) return;
    moments.filter = picked.personId;
  }

  @override
  Widget build(BuildContext context) {
    final moments = context.watch<MomentsController>();
    final friends = context.watch<FriendsController>().friends;
    final unread = context.watch<ChatController>().unreadCount;
    final list = moments.visible;
    final person = moments.filter == null
        ? null
        : friends.where((f) => f.id == moments.filter).firstOrNull;

    // PageView có key theo bộ lọc nên tự về thẻ đầu khi đổi bạn.
    if (_lastFilter != moments.filter) {
      _lastFilter = moments.filter;
      _page = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scheduleSeen();
      });
    }

    final title = person?.name ?? 'Tất cả bạn bè (${friends.length})';
    return SafeArea(
      bottom: false,
      child: Column(children: [
        VitaTopBar(
          leading: MeButton(
              person: context.read<Me>().person,
              onTap: () => Navigator.of(context).push(PersonalScreen.route())),
          title: Center(
            child: _FilterButton(
                title: title,
                hasNew: moments.unseen.isNotEmpty,
                onTap: _pickFriend),
          ),
          trailing: RoundIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Tin nhắn',
            badge: unread,
            onTap: () => Navigator.of(context).push(InboxScreen.route()),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? _Empty(person: person)
              : LayoutBuilder(builder: (context, box) {
                  return PageView.builder(
                    key: ValueKey(moments.filter),
                    controller: _pages,
                    scrollDirection: Axis.vertical,
                    itemCount: list.length + 1,
                    onPageChanged: (i) {
                      _page = i;
                      _scheduleSeen();
                    },
                    itemBuilder: (context, i) {
                      final child = i == list.length
                          ? const _EndCard()
                          : MomentCard(
                              key: ValueKey(list[i].id),
                              moment: list[i],
                              showSwipeHint: i == 0 && list.length > 1,
                              maxPhoto: box.maxHeight - 170,
                            );
                      return _DeckItem(
                          controller: _pages, index: i, child: child);
                    },
                  );
                }),
        ),
        SizedBox(height: 70 + MediaQuery.paddingOf(context).bottom),
      ]),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleSeen();
    });
  }
}

/// Thẻ phóng nhẹ lên khi vuốt tới, theo đúng vị trí ngón tay.
class _DeckItem extends StatelessWidget {
  const _DeckItem(
      {required this.controller, required this.index, required this.child});
  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    return AnimatedBuilder(
      animation: controller,
      child: RepaintBoundary(child: child),
      builder: (_, child) {
        var d = 0.0;
        if (controller.hasClients && controller.position.haveDimensions) {
          d = ((controller.page ?? 0) - index).abs().clamp(0.0, 1.0);
        }
        return Opacity(
          opacity: 1 - d * .45,
          child: Transform.scale(scale: 1 - d * .1, child: child),
        );
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton(
      {required this.title, required this.hasNew, required this.onTap});
  final String title;
  final bool hasNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Đang xem $title. Bấm để chọn bạn',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
            decoration: BoxDecoration(
                color: VitaColors.surfaceHigh,
                borderRadius: BorderRadius.circular(99)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: VitaFonts.body,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: VitaColors.onSurface)),
              ),
              if (hasNew) ...[
                const SizedBox(width: 6),
                Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: VitaColors.volt, shape: BoxShape.circle)),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded,
                  size: 20, color: VitaColors.onSurfaceVariant),
            ]),
          ),
        ),
      );
}

class _Filter {
  const _Filter(this.personId);
  final String? personId;
}

class _FriendFilterSheet extends StatelessWidget {
  const _FriendFilterSheet();

  @override
  Widget build(BuildContext context) {
    final moments = context.watch<MomentsController>();
    final friends = context.watch<FriendsController>().friends;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Xem Khoảnh khắc của', style: VitaText.sheetTitle),
            const SizedBox(height: 10),
            Flexible(
              child: ListView(shrinkWrap: true, children: [
                PickRow(
                  leading: const _Circle(icon: Icons.group_rounded),
                  title: 'Tất cả bạn bè',
                  subtitle: '${friends.length} người',
                  checked: moments.filter == null,
                  onTap: () => Navigator.of(context).pop(const _Filter(null)),
                ),
                for (final f in friends)
                  PickRow(
                    leading: VitaAvatar(f, size: 40),
                    title: f.name,
                    subtitle: moments.hasUnseenFrom(f.id)
                        ? 'Có Khoảnh khắc mới'
                        : moments.countFrom(f.id) > 0
                            ? '${moments.countFrom(f.id)} Khoảnh khắc gần đây'
                            : 'Chưa chia sẻ gì gần đây',
                    subtitleColor:
                        moments.hasUnseenFrom(f.id) ? VitaColors.volt : null,
                    checked: moments.filter == f.id,
                    onTap: () => Navigator.of(context).pop(_Filter(f.id)),
                  ),
                PickRow(
                  leading: const _Circle(icon: Icons.person_add_alt_1_rounded),
                  title: 'Thêm bạn bè',
                  subtitle: 'Bằng mã hoặc link mời',
                  onTap: () {
                    Navigator.of(context)
                      ..pop()
                      ..push(FriendsScreen.route());
                  },
                ),
              ]),
            ),
          ]),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
            color: VitaColors.surfaceHigh, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: VitaColors.volt),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.person});
  final Person? person;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const _Art(icon: Icons.group_rounded),
            const SizedBox(height: 18),
            Text(
                person == null
                    ? 'Chưa có Khoảnh khắc nào'
                    : '${person!.name} chưa chia sẻ gì',
                textAlign: TextAlign.center,
                style: VitaText.sheetTitle.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
                person == null
                    ? 'Mời bạn bè dùng VitaSnap để xem bữa ăn và lúc vận động của nhau.'
                    : 'Khi ${person!.shortName} chia sẻ Khoảnh khắc, cậu sẽ thấy ở đây.',
                textAlign: TextAlign.center,
                style: VitaText.bodySmall),
            if (person == null) ...[
              const SizedBox(height: 18),
              VitaPrimaryButton(
                  label: 'Mời bạn bè',
                  showArrow: false,
                  onPressed: () =>
                      Navigator.of(context).push(FriendsScreen.route())),
            ],
          ]),
        ),
      );
}

class _EndCard extends StatelessWidget {
  const _EndCard();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const _Art(icon: Icons.check_rounded),
            const SizedBox(height: 18),
            Text('Cậu đã xem hết',
                style: VitaText.sheetTitle.copyWith(fontSize: 22)),
            const SizedBox(height: 6),
            const Text('Tới lượt cậu chia sẻ một Khoảnh khắc.',
                textAlign: TextAlign.center, style: VitaText.bodySmall),
            const SizedBox(height: 18),
            SizedBox(
              width: 200,
              child: VitaPrimaryButton(
                  label: 'Chụp ngay',
                  showArrow: false,
                  onPressed: () => HomeShell.of(context)?.go(HomeTab.camera)),
            ),
          ]),
        ),
      );
}

/// Ba ô bài xếp lệch, ô giữa màu volt.
class _Art extends StatelessWidget {
  const _Art({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    Widget tile(double angle, Color color, [Widget? child]) => Transform.rotate(
          angle: angle,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: VitaColors.lineSoft)),
            child: child,
          ),
        );
    return SizedBox(
      width: 120,
      height: 100,
      child: Stack(children: [
        Positioned(left: 0, top: 22, child: tile(-.2, VitaColors.surfaceHigh)),
        Positioned(right: 0, top: 22, child: tile(.2, VitaColors.surfaceHigh)),
        Positioned(
            left: 25,
            top: 0,
            child: tile(0, VitaColors.volt,
                Icon(icon, color: VitaColors.onVolt, size: 30))),
      ]),
    );
  }
}
