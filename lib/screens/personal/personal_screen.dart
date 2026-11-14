import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme/vita_theme.dart';
import '../../providers/auth_controller.dart';
import '../../providers/health_controller.dart';
import '../../providers/journal_controller.dart';
import '../../providers/session_scope.dart';
import '../../providers/social_controllers.dart';
import '../../widgets/vita/ui.dart';
import 'friends_screen.dart';
import 'health_info_screen.dart';

/// Màn Cá nhân (mở bằng avatar): Hồ sơ, Bạn bè, Thông tin sức khỏe.
class PersonalScreen extends StatelessWidget {
  const PersonalScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const PersonalScreen());

  @override
  Widget build(BuildContext context) {
    final me = context.read<Me>();
    final health = context.watch<HealthController>().info;
    final friends = context.watch<FriendsController>();
    final mine = context.watch<MomentsController>().mine;
    final streak = context.watch<JournalController>().streak;
    final conditions = health?.conditions.keys.map((c) => c.label).toList();
    return Scaffold(
      backgroundColor: VitaColors.bg,
      body: SafeArea(
        child: Column(children: [
          const VitaTopBar(leading: BackButtonRound(), title: Text('Cá nhân')),
          Expanded(
            child:
                ListView(padding: const EdgeInsets.only(bottom: 34), children: [
              Column(children: [
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: VitaColors.volt, shape: BoxShape.circle),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: VitaColors.bg, shape: BoxShape.circle),
                    child: VitaAvatar(me.person, size: 80),
                  ),
                ),
                const SizedBox(height: 10),
                Text(me.profile.displayName,
                    style: VitaText.headline.copyWith(fontSize: 26)),
                Text(me.profile.email, style: VitaText.caption),
                const SizedBox(height: 10),
                StreakChip(streak),
                const SizedBox(height: 10),
                const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_outlined,
                          size: 14, color: VitaColors.muted),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                            'Bạn bè thấy tên, ảnh đại diện, chuỗi ngày và Khoảnh khắc',
                            style: VitaText.caption),
                      ),
                    ]),
              ]),
              const SizedBox(height: 18),
              _Menu(children: [
                _MenuRow(
                  icon: Icons.monitor_heart_outlined,
                  color: VitaColors.volt,
                  title: 'Thông tin sức khỏe',
                  subtitle: health == null
                      ? 'Chưa thiết lập · AI đang dùng gợi ý chung'
                      : '${conditions!.isEmpty ? 'Không có bệnh lý nền' : conditions.join(', ')} · ${formatInt(health.targetKcal)} kcal/ngày',
                  warn: health == null,
                  onTap: () =>
                      Navigator.of(context).push(HealthInfoScreen.route()),
                ),
                _MenuRow(
                  icon: Icons.group_outlined,
                  color: VitaColors.cyan,
                  title: 'Bạn bè',
                  subtitle:
                      '${friends.friends.length} bạn${friends.invites.isEmpty ? '' : ' · ${friends.invites.length} lời mời đang chờ'}',
                  onTap: () =>
                      Navigator.of(context).push(FriendsScreen.route()),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 10),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Expanded(
                        child: Text('Khoảnh khắc của tôi',
                            style: TextStyle(
                                fontFamily: VitaFonts.display,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: VitaColors.onSurface)),
                      ),
                      Text('${mine.length} ảnh', style: VitaText.caption),
                    ]),
              ),
              if (mine.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                      'Chưa chia sẻ Khoảnh khắc nào. Bật "Chia sẻ cho bạn bè" khi ghi để chúng hiện ở đây.',
                      style: VitaText.bodySmall),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    children: [
                      for (final m in mine)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image(
                              image: m.photo.image,
                              fit: BoxFit.cover,
                              semanticLabel: m.label),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              _Menu(children: [
                _MenuRow(
                  icon: Icons.logout_rounded,
                  color: VitaColors.error,
                  title: 'Đăng xuất',
                  danger: true,
                  onTap: () => context.read<AuthController>().signOut(),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
              color: VitaColors.surfaceLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: VitaColors.lineSoft)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (final (i, c) in children.indexed) ...[
              if (i > 0)
                const Divider(
                    height: 1, thickness: 1, color: VitaColors.lineSoft),
              c,
            ],
          ]),
        ),
      );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.warn = false,
    this.danger = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool warn;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: VitaColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: danger
                                ? VitaColors.error
                                : VitaColors.onSurface)),
                    if (subtitle != null)
                      Text(subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: VitaText.caption.copyWith(
                              color: warn ? const Color(0xFFFFC24B) : null)),
                  ]),
            ),
            if (!danger)
              const Icon(Icons.chevron_right_rounded, color: VitaColors.muted),
          ]),
        ),
      );
}
