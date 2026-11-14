import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/vita_theme.dart';
import '../../providers/social_controllers.dart';
import '../../widgets/vita/ui.dart';

/// Bạn bè: mã kết bạn, lời mời đang chờ, danh sách bạn.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const FriendsScreen());

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _copy(String text, String toast) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showVitaToast(context, toast);
  }

  Future<void> _invite() async {
    final code = _code.text.trim().toUpperCase();
    if (code.isEmpty) {
      showVitaToast(context, 'Nhập mã kết bạn trước nhé');
      return;
    }
    final ok = await context.read<FriendsController>().sendInvite(code);
    if (!mounted) return;
    if (ok) _code.clear();
    showVitaToast(context,
        ok ? 'Đã gửi lời mời tới $code' : 'Mã chưa đúng dạng, ví dụ VITA-7K2Q');
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendsController>();
    final link = 'https://vitasnap.app/moi/${friends.myCode}';
    return Scaffold(
      backgroundColor: VitaColors.bg,
      body: SafeArea(
        child: Column(children: [
          const VitaTopBar(leading: BackButtonRound(), title: Text('Bạn bè')),
          Expanded(
            child:
                ListView(padding: const EdgeInsets.only(bottom: 30), children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: VitaCard(
                  radius: 28,
                  padding: const EdgeInsets.all(18),
                  borderColor: VitaColors.volt.withValues(alpha: .3),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      VitaColors.volt.withValues(alpha: .16),
                      VitaColors.surfaceLow,
                    ],
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CapsLabel('Mã kết bạn của cậu',
                            color: VitaColors.volt),
                        const SizedBox(height: 4),
                        SelectableText(friends.myCode,
                            style: VitaText.metric.copyWith(
                                fontSize: 32,
                                letterSpacing: 1.2,
                                color: VitaColors.onSurface)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _copy(link, 'Đã sao chép link mời'),
                              icon:
                                  const Icon(Icons.ios_share_rounded, size: 17),
                              label: const Text('Sao chép link mời'),
                              style: FilledButton.styleFrom(
                                  backgroundColor: VitaColors.volt,
                                  foregroundColor: VitaColors.onVolt,
                                  minimumSize: const Size.fromHeight(44),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => _copy(friends.myCode,
                                'Đã sao chép mã ${friends.myCode}'),
                            icon: const Icon(Icons.copy_rounded, size: 17),
                            label: const Text('Mã'),
                            style: FilledButton.styleFrom(
                                backgroundColor: VitaColors.surfaceHigh,
                                foregroundColor: VitaColors.onSurface,
                                minimumSize: const Size(0, 44),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5)),
                          ),
                        ]),
                      ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('friend-code'),
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _invite(),
                      style: const TextStyle(
                          fontSize: 15,
                          letterSpacing: .8,
                          color: VitaColors.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Nhập mã của bạn',
                        hintStyle: const TextStyle(
                            letterSpacing: 0, color: VitaColors.placeholder),
                        filled: true,
                        fillColor: VitaColors.surfaceLow,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(99),
                            borderSide:
                                const BorderSide(color: VitaColors.lineSoft)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(99),
                            borderSide:
                                const BorderSide(color: VitaColors.volt)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _invite,
                    style: FilledButton.styleFrom(
                        backgroundColor: VitaColors.surfaceHigh,
                        foregroundColor: VitaColors.onSurface,
                        minimumSize: const Size(0, 50),
                        textStyle:
                            const TextStyle(fontWeight: FontWeight.w700)),
                    child: const Text('Kết bạn'),
                  ),
                ]),
              ),
              if (friends.invites.isNotEmpty) ...[
                _Section('Lời mời đang chờ (${friends.invites.length})'),
                for (final p in friends.invites)
                  _PersonRow(
                    avatar: VitaAvatar(p, size: 46),
                    name: p.name,
                    sub: 'Muốn kết bạn với cậu',
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(
                        onPressed: () => friends.respond(p, accept: false),
                        style: TextButton.styleFrom(
                            foregroundColor: VitaColors.onSurfaceVariant),
                        child: const Text('Bỏ qua'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          await friends.respond(p, accept: true);
                          if (context.mounted) {
                            showVitaToast(context, 'Đã kết bạn với ${p.name}');
                          }
                        },
                        style: FilledButton.styleFrom(
                            backgroundColor: VitaColors.volt,
                            foregroundColor: VitaColors.onVolt,
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        child: const Text('Đồng ý'),
                      ),
                    ]),
                  ),
              ],
              _Section('Bạn bè (${friends.friends.length})'),
              for (final p in friends.friends)
                _PersonRow(
                    avatar: VitaAvatar(p, size: 46),
                    name: p.name,
                    sub: 'Bạn bè'),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 6),
        child: CapsLabel(text),
      );
}

class _PersonRow extends StatelessWidget {
  const _PersonRow(
      {required this.avatar,
      required this.name,
      required this.sub,
      this.trailing});
  final Widget avatar;
  final String name;
  final String sub;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          avatar,
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: VitaColors.onSurface)),
              Text(sub, style: VitaText.caption),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}
