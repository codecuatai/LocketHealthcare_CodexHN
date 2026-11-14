import 'dart:async';

import '../../core/models/photo.dart';
import '../../core/models/social.dart';
import '../demo/demo_people.dart';

abstract interface class ChatRepository {
  /// Các cuộc trò chuyện, mới nhất trước.
  Stream<List<Conversation>> watch();
  Future<void> send(Person friend, String text, {MomentQuote? quote});
  Future<void> markRead(String friendId);
  void dispose();
}

class DemoChatRepository implements ChatRepository {
  DemoChatRepository({DateTime? now, this.simulateReplies = true}) {
    final t = now ?? DateTime.now();
    _convos = [
      Conversation(friend: DemoPeople.nam, unread: true, messages: [
        ChatMessage(
            fromMe: true,
            at: t.subtract(const Duration(minutes: 30)),
            quote: const MomentQuote(
                photo: SamplePhotos.run, label: 'Chạy bộ · 5,2 km'),
            text: 'Tuần sau rủ tớ chạy cùng nhé, tớ chạy chậm thôi'),
        ChatMessage(
            fromMe: false,
            at: t.subtract(const Duration(minutes: 8)),
            text: 'Ok luôn, thứ 7 lúc 6h ở hồ Tây nha'),
      ]),
      Conversation(friend: DemoPeople.linh, messages: [
        ChatMessage(
            fromMe: false,
            at: t.subtract(const Duration(hours: 2, minutes: 10)),
            quote: const MomentQuote(
                photo: SamplePhotos.chicken, label: 'Gỏi gà nướng'),
            text: 'Gỏi gà quán nào thế, chỉ tớ với'),
        ChatMessage(
            fromMe: true,
            at: t.subtract(const Duration(hours: 2)),
            text: 'Quán đầu ngõ cơ quan tớ, mai đi cùng không'),
      ]),
    ];
  }

  /// Giả lập Bạn bè trả lời sau vài giây.
  final bool simulateReplies;
  late List<Conversation> _convos;
  final _controller = StreamController<List<Conversation>>.broadcast();
  final _timers = <Timer>[];

  void _emit() => _controller.add(List.unmodifiable(_convos));

  void _put(Conversation c) {
    _convos = [c, ..._convos.where((x) => x.friend.id != c.friend.id)];
    _emit();
  }

  Conversation _of(Person friend) =>
      _convos.firstWhere((c) => c.friend.id == friend.id,
          orElse: () => Conversation(friend: friend, messages: const []));

  @override
  Stream<List<Conversation>> watch() async* {
    yield List.unmodifiable(_convos);
    yield* _controller.stream;
  }

  @override
  Future<void> send(Person friend, String text, {MomentQuote? quote}) async {
    final c = _of(friend);
    _put(c.copyWith(unread: false, friendTyping: simulateReplies, messages: [
      ...c.messages,
      ChatMessage(fromMe: true, text: text, quote: quote, at: DateTime.now()),
    ]));
    if (!simulateReplies) return;
    _timers.add(Timer(const Duration(milliseconds: 1600), () {
      final now = _of(friend);
      final replied = now.messages.where((m) => !m.fromMe).isNotEmpty;
      _put(now.copyWith(friendTyping: false, messages: [
        ...now.messages,
        ChatMessage(
            fromMe: false,
            text: replied ? 'Ok nha 👍' : 'Được luôn, hẹn cậu nhé!',
            at: DateTime.now()),
      ]));
    }));
  }

  @override
  Future<void> markRead(String friendId) async {
    final i = _convos.indexWhere((c) => c.friend.id == friendId);
    if (i < 0 || !_convos[i].unread) return;
    _convos = [..._convos]..[i] = _convos[i].copyWith(unread: false);
    _emit();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _controller.close();
  }
}
