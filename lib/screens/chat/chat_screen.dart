import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/social.dart';
import '../../core/theme/vita_theme.dart';
import '../../providers/social_controllers.dart';
import '../../widgets/vita/ui.dart';

/// Cuộc trò chuyện riêng với một người bạn. Trả lời một Khoảnh khắc sẽ
/// trích dẫn ảnh đó ở đầu tin nhắn.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.friend, this.quote});
  final Person friend;
  final MomentQuote? quote;

  static Route<void> route(Person friend, {MomentQuote? quote}) =>
      MaterialPageRoute(
          builder: (_) => ChatScreen(friend: friend, quote: quote));

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late MomentQuote? _quote = widget.quote;
  final _text = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ChatController>().markRead(widget.friend));
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    final quote = _quote;
    _text.clear();
    setState(() => _quote = null);
    await context
        .read<ChatController>()
        .send(widget.friend, text, quote: quote);
  }

  @override
  Widget build(BuildContext context) {
    final convo =
        context.watch<ChatController>().conversationWith(widget.friend);
    final msgs = convo.messages;
    final f = widget.friend;
    return Scaffold(
      backgroundColor: VitaColors.bg,
      body: SafeArea(
        child: Column(children: [
          SizedBox(
            height: 58,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const BackButtonRound(),
                const SizedBox(width: 8),
                VitaAvatar(f, size: 38),
                const SizedBox(width: 10),
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                              color: VitaColors.onSurface)),
                      Text(convo.friendTyping ? 'Đang soạn tin…' : 'Bạn bè',
                          style: VitaText.caption.copyWith(fontSize: 12)),
                    ]),
              ]),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              reverse: true,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
              itemCount: msgs.length + (convo.friendTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (convo.friendTyping && i == 0) return const _Typing();
                final m =
                    msgs[msgs.length - 1 - (i - (convo.friendTyping ? 1 : 0))];
                return _Bubble(message: m, friend: f);
              },
            ),
          ),
          Container(
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: VitaColors.lineSoft))),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_quote != null) ...[
                _QuoteChip(
                  quote: _quote!,
                  title: 'Trả lời Khoảnh khắc của ${f.shortName}',
                  onRemove: () => setState(() => _quote = null),
                ),
                const SizedBox(height: 8),
              ],
              Row(children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('chat-input'),
                    controller: _text,
                    autofocus: widget.quote != null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(
                        fontSize: 15, color: VitaColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Nhắn cho ${f.shortName}…',
                      hintStyle: const TextStyle(color: VitaColors.muted),
                      filled: true,
                      fillColor: VitaColors.surfaceLow,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide:
                              const BorderSide(color: VitaColors.lineSoft)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide: const BorderSide(color: VitaColors.volt)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: 'Gửi',
                  excludeSemantics: true,
                  child: Material(
                    color: VitaColors.volt,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _send,
                      child: const SizedBox.square(
                          dimension: 46,
                          child: Icon(Icons.send_rounded,
                              size: 19, color: VitaColors.onVolt)),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.friend});
  final ChatMessage message;
  final Person friend;

  @override
  Widget build(BuildContext context) {
    final me = message.fromMe;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .76),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
              crossAxisAlignment:
                  me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.quote != null) ...[
                  _QuoteChip(
                      quote: message.quote!,
                      title: me
                          ? 'Cậu trả lời Khoảnh khắc'
                          : '${friend.shortName} trả lời Khoảnh khắc'),
                  const SizedBox(height: 4),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: me ? VitaColors.volt : VitaColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(22)),
                  child: Text(message.text,
                      style: TextStyle(
                          fontSize: 14.5,
                          height: 1.35,
                          fontWeight: me ? FontWeight.w500 : FontWeight.w400,
                          color:
                              me ? VitaColors.onVolt : VitaColors.onSurface)),
                ),
              ]),
        ),
      ),
    );
  }
}

class _QuoteChip extends StatelessWidget {
  const _QuoteChip({required this.quote, required this.title, this.onRemove});
  final MomentQuote quote;
  final String title;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
        decoration: BoxDecoration(
            color: VitaColors.surfaceLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: VitaColors.lineSoft)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
                image: quote.photo.image,
                width: 44,
                height: 44,
                fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: VitaColors.onSurface)),
                  Text(quote.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VitaText.caption.copyWith(fontSize: 12)),
                ]),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            RoundIconButton(
                icon: Icons.close_rounded,
                label: 'Bỏ trích dẫn',
                size: 30,
                onTap: onRemove),
          ],
        ]),
      );
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
              color: VitaColors.surfaceHigh,
              borderRadius: BorderRadius.circular(22)),
          child: const Text('• • •',
              semanticsLabel: 'Đang soạn tin',
              style: TextStyle(
                  letterSpacing: 2, color: VitaColors.onSurfaceVariant)),
        ),
      );
}
