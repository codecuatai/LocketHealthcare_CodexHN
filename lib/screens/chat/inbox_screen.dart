import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/models/social.dart';
import '../../core/theme/vita_theme.dart';
import '../../providers/social_controllers.dart';
import '../../widgets/vita/ui.dart';
import 'chat_screen.dart';

/// Danh sách cuộc trò chuyện. Tin nhắn bắt đầu khi trả lời một Khoảnh khắc.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const InboxScreen());

  @override
  Widget build(BuildContext context) {
    final convos = context.watch<ChatController>().conversations;
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: VitaColors.bg,
      body: SafeArea(
        child: Column(children: [
          const VitaTopBar(leading: BackButtonRound(), title: Text('Tin nhắn')),
          Expanded(
            child: convos.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                          'Chưa có tin nhắn. Nhắn trả lời một Khoảnh khắc trên Bảng tin để bắt đầu.',
                          textAlign: TextAlign.center,
                          style: VitaText.bodySmall),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      for (final c in convos) _Row(convo: c, now: now),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(32, 16, 32, 24),
                        child: Text(
                            'Tin nhắn bắt đầu khi cậu hoặc bạn bè trả lời một Khoảnh khắc.',
                            textAlign: TextAlign.center,
                            style: VitaText.caption),
                      ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.convo, required this.now});
  final Conversation convo;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final last = convo.messages.isEmpty ? null : convo.messages.last;
    final quote = convo.messages.reversed
        .where((m) => m.quote != null)
        .firstOrNull
        ?.quote;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(ChatScreen.route(convo.friend)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(children: [
          VitaAvatar(convo.friend, size: 50),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(convo.friend.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: VitaColors.onSurface)),
                ),
                if (convo.unread) ...[
                  const SizedBox(width: 6),
                  Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: VitaColors.volt, shape: BoxShape.circle)),
                ],
              ]),
              if (last != null)
                Text(
                    convo.friendTyping
                        ? 'Đang soạn tin…'
                        : '${last.fromMe ? 'Cậu: ' : ''}${last.text}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            convo.unread ? FontWeight.w600 : FontWeight.w400,
                        color: convo.unread
                            ? VitaColors.onSurface
                            : VitaColors.muted)),
              if (last != null)
                Text(relativeTime(last.at, now),
                    style: VitaText.caption.copyWith(fontSize: 11.5)),
            ]),
          ),
          if (quote != null) ...[
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image(
                  image: quote.photo.image,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover),
            ),
          ],
        ]),
      ),
    );
  }
}
