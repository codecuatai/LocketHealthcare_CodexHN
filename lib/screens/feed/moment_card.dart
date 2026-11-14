import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/models/social.dart';
import '../../core/theme/vita_theme.dart';
import '../../providers/session_scope.dart';
import '../../providers/social_controllers.dart';
import '../../widgets/vita/ui.dart';
import '../chat/chat_screen.dart';

/// Một Khoảnh khắc trên Bảng tin. Khoảnh khắc chưa xem có viền sáng và nhãn
/// MỚI; khi đã xem thì mờ dần về như thường.
class MomentCard extends StatelessWidget {
  const MomentCard({
    super.key,
    required this.moment,
    required this.maxPhoto,
    this.showSwipeHint = false,
  });

  final Moment moment;
  final double maxPhoto;
  final bool showSwipeHint;

  @override
  Widget build(BuildContext context) {
    final m = moment;
    final author = m.isMine ? context.read<Me>().person : m.author;
    final fresh = m.unseen;
    final slow = reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 600);
    return LayoutBuilder(builder: (context, box) {
      final side = min(box.maxWidth - 24, max(200.0, maxPhoto));
      return Stack(children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                duration: slow,
                curve: Curves.easeOut,
                width: side,
                height: side,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(44),
                  border: Border.all(
                      color: fresh ? VitaColors.volt : Colors.transparent,
                      width: 3),
                  boxShadow: [
                    BoxShadow(
                        color:
                            VitaColors.volt.withValues(alpha: fresh ? .3 : 0),
                        blurRadius: 36),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Stack(fit: StackFit.expand, children: [
                    Image(
                        image: m.photo.image,
                        fit: BoxFit.cover,
                        semanticLabel: m.label),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 90,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GlassPill(
                          height: 38,
                          padding: const EdgeInsets.fromLTRB(4, 0, 14, 0),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            VitaAvatar(author, size: 30),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(m.isMine ? 'Cậu' : m.author.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13.5)),
                            ),
                            Text(
                                ' · ${relativeTime(m.postedAt, DateTime.now())}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70)),
                          ]),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 14,
                      child: AnimatedOpacity(
                        opacity: fresh ? 1 : 0,
                        duration: slow,
                        child: AnimatedScale(
                          scale: fresh ? 1 : .7,
                          duration: slow,
                          child: const _NewBadge(),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Wrap(spacing: 6, runSpacing: 6, children: [
                        GlassPill(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(m.kind == MomentKind.meal
                                ? Icons.restaurant_rounded
                                : Icons.directions_run_rounded),
                            const SizedBox(width: 6),
                            Text(m.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                        if (m.kcal != null)
                          Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                                color: VitaColors.volt,
                                borderRadius: BorderRadius.circular(99)),
                            child: Text('${formatInt(m.kcal!)} kcal',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: VitaColors.onVolt)),
                          ),
                      ]),
                    ),
                  ]),
                ),
              ),
              if (m.caption.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: side - 12,
                  child: Text(m.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14.5, color: VitaColors.onSurface)),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: side,
                child: m.isMine ? _ReceivedRow(m) : _ReactionBar(m),
              ),
            ]),
          ),
        ),
        if (showSwipeHint)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: ExcludeSemantics(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.keyboard_arrow_up_rounded,
                    size: 17, color: VitaColors.muted),
                SizedBox(width: 2),
                Text('Vuốt lên để xem tiếp',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: VitaColors.muted)),
              ]),
            ),
          ),
      ]);
    });
  }
}

class _NewBadge extends StatefulWidget {
  const _NewBadge();

  @override
  State<_NewBadge> createState() => _NewBadgeState();
}

class _NewBadgeState extends State<_NewBadge>
    with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!reduceMotion(context) && !_blink.isAnimating) {
      _blink.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Khoảnh khắc mới',
        excludeSemantics: true,
        child: Container(
          height: 30,
          padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
          decoration: BoxDecoration(
            color: VitaColors.volt,
            borderRadius: BorderRadius.circular(99),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x59000000),
                  blurRadius: 18,
                  offset: Offset(0, 6)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            FadeTransition(
              opacity: Tween(begin: 1.0, end: .25).animate(_blink),
              child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: VitaColors.onVolt, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 6),
            const Text('MỚI',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                    color: VitaColors.onVolt)),
          ]),
        ),
      );
}

/// Cảm xúc nhanh (chỉ icon), chọn thêm emoji, và ô nhắn trả lời ảnh.
class _ReactionBar extends StatefulWidget {
  const _ReactionBar(this.moment);
  final Moment moment;

  @override
  State<_ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<_ReactionBar> {
  bool _picking = false;
  final _keys = {
    for (final r in QuickReaction.values) r.name: GlobalKey(),
    'emoji': GlobalKey(),
  };

  void _burst(String key, String emoji) {
    final box = _keys[key]?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || reduceMotion(context)) return;
    EmojiBurst.show(
        context, emoji, box.localToGlobal(box.size.center(Offset.zero)));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.moment;
    final ctrl = context.read<MomentsController>();
    if (_picking) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
            color: VitaColors.surfaceHigh,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: VitaColors.line)),
        child: Row(children: [
          for (final e in extraReactions)
            Expanded(
              child: Semantics(
                button: true,
                selected: m.myEmoji == e,
                label: 'Thả $e',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ctrl.pickEmoji(m, e);
                    setState(() => _picking = false);
                    if (m.myEmoji != e) {
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _burst('emoji', e));
                    }
                  },
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: m.myEmoji == e
                              ? VitaColors.volt.withValues(alpha: .18)
                              : Colors.transparent),
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: () => setState(() => _picking = false),
            icon: const Icon(Icons.close_rounded,
                size: 18, color: VitaColors.onSurfaceVariant),
          ),
        ]),
      );
    }
    return Row(children: [
      for (final r in QuickReaction.values) ...[
        _ReactButton(
          key: _keys[r.name],
          label: r.label,
          on: m.myReactions.contains(r),
          onTap: () {
            HapticFeedback.lightImpact();
            final adding = !m.myReactions.contains(r);
            ctrl.toggle(m, r);
            if (adding) _burst(r.name, r.emoji);
          },
          child: Text(r.emoji, style: const TextStyle(fontSize: 21)),
        ),
        const SizedBox(width: 6),
      ],
      _ReactButton(
        key: _keys['emoji'],
        label: m.myEmoji == null ? 'Thêm cảm xúc' : 'Đã thả ${m.myEmoji}',
        on: m.myEmoji != null,
        onTap: () => setState(() => _picking = true),
        child: m.myEmoji == null
            ? const Icon(Icons.add_reaction_outlined,
                size: 20, color: VitaColors.onSurfaceVariant)
            : Text(m.myEmoji!, style: const TextStyle(fontSize: 21)),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Semantics(
          button: true,
          label: 'Nhắn cho ${m.author.shortName}',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(ChatScreen.route(m.author,
                quote: MomentQuote(photo: m.photo, label: m.label))),
            child: Container(
              height: 44,
              padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
              decoration: BoxDecoration(
                  color: VitaColors.bg,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: VitaColors.lineSoft)),
              child: Row(children: [
                Expanded(
                  child: Text('Nhắn cho ${m.author.shortName}…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: VitaColors.muted)),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: VitaColors.surfaceHigh, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded,
                      size: 15, color: VitaColors.onSurface),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _ReactButton extends StatelessWidget {
  const _ReactButton({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
    required this.child,
  });
  final String label;
  final bool on;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        toggled: on,
        label: label,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on
                    ? VitaColors.volt.withValues(alpha: .14)
                    : VitaColors.surfaceLow,
                border: Border.all(
                    color: on
                        ? VitaColors.volt.withValues(alpha: .55)
                        : VitaColors.lineSoft),
              ),
              child: child,
            ),
          ),
        ),
      );
}

/// Khoảnh khắc của mình: ai đã thả cảm xúc (chỉ mình thấy).
class _ReceivedRow extends StatelessWidget {
  const _ReceivedRow(this.moment);
  final Moment moment;

  @override
  Widget build(BuildContext context) {
    final got = moment.received;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: VitaColors.surfaceLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VitaColors.lineSoft)),
      child: got.isEmpty
          ? const Row(children: [
              Icon(Icons.schedule_rounded, size: 15, color: VitaColors.muted),
              SizedBox(width: 8),
              Expanded(
                child: Text('Chưa ai thả cảm xúc. Chỉ cậu thấy ai đã thả.',
                    style: VitaText.caption),
              ),
            ])
          : Row(children: [
              AvatarStack([for (final r in got) r.from],
                  border: VitaColors.surfaceLow),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    got.map((r) => '${r.from.shortName} ${r.emoji}').join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: VitaColors.onSurface)),
              ),
              const Icon(Icons.lock_outline_rounded,
                  size: 13, color: VitaColors.muted),
              const SizedBox(width: 4),
              const Text('Chỉ cậu thấy', style: VitaText.caption),
            ]),
    );
  }
}

/// Emoji bay lên từ nút cảm xúc.
abstract final class EmojiBurst {
  static void show(BuildContext context, String emoji, Offset from) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
        builder: (_) =>
            _Burst(emoji: emoji, from: from, onDone: () => entry.remove()));
    overlay.insert(entry);
  }
}

class _Burst extends StatefulWidget {
  const _Burst({required this.emoji, required this.from, required this.onDone});
  final String emoji;
  final Offset from;
  final VoidCallback onDone;

  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300))
    ..forward().whenComplete(widget.onDone);
  final _rnd = Random();
  late final _drift =
      List.generate(6, (i) => (i - 2.5) * 22 + _rnd.nextDouble() * 16 - 8);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Stack(children: [
            for (var i = 0; i < 6; i++)
              Builder(builder: (_) {
                final t = ((_c.value * 1.3) - i * .06).clamp(0.0, 1.0);
                final ease = Curves.easeOut.transform(t);
                final opacity = t < .15 ? t / .15 : (1 - t).clamp(0.0, 1.0);
                return Positioned(
                  left: widget.from.dx - 14 + _drift[i] * ease,
                  top: widget.from.dy - 14 - 190 * ease,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: .6 + .6 * (t < .15 ? t / .15 : 1 - (t - .15) * .4),
                      child: Text(widget.emoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              }),
          ]),
        ),
      );
}
