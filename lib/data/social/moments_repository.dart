import 'dart:async';

import '../../core/models/photo.dart';
import '../../core/models/social.dart';
import '../demo/demo_people.dart';

abstract interface class MomentsRepository {
  /// Bảng tin của người dùng, mới nhất trước; phát lại mỗi khi có thay đổi.
  Stream<List<Moment>> watchFeed();
  Future<void> share(Moment moment, {List<Person>? audience});
  Future<void> setReaction(String momentId, QuickReaction reaction, bool on);
  Future<void> setEmoji(String momentId, String? emoji);
  Future<void> markSeen(String momentId);
  void dispose();
}

class DemoMomentsRepository implements MomentsRepository {
  DemoMomentsRepository({DateTime? now, this.simulateFriends = true}) {
    final t = now ?? DateTime.now();
    _moments = [
      Moment(
          id: 'm-linh',
          author: DemoPeople.linh,
          photo: SamplePhotos.salad,
          kind: MomentKind.meal,
          label: 'Salad ức gà',
          kcal: 410,
          caption: 'Bữa trưa văn phòng, no tới chiều',
          postedAt: t.subtract(const Duration(minutes: 20)),
          unseen: true),
      Moment(
          id: 'm-nam',
          author: DemoPeople.nam,
          photo: SamplePhotos.run,
          kind: MomentKind.activity,
          label: 'Chạy bộ · 5,2 km',
          caption: 'Sáng nay trời mát, chạy sướng ghê',
          postedAt: t.subtract(const Duration(hours: 1)),
          unseen: true),
      Moment(
          id: 'm-my',
          author: DemoPeople.my,
          photo: SamplePhotos.eggSalad,
          kind: MomentKind.meal,
          label: 'Salad trứng quinoa',
          caption: 'Thử công thức mới, ngon hơn tưởng',
          postedAt: t.subtract(const Duration(hours: 3)),
          unseen: true),
      // Khoảnh khắc của chính người dùng (Bản ghi Gỏi gà đã chia sẻ).
      Moment(
          id: 'm-me',
          author: demoMe,
          isMine: true,
          photo: SamplePhotos.chicken,
          kind: MomentKind.meal,
          label: 'Gỏi gà nướng',
          caption: 'Trưa nay ăn nhẹ',
          postedAt: t.subtract(const Duration(hours: 5)),
          received: const [ReceivedReaction(DemoPeople.linh, '🔥')]),
      Moment(
          id: 'm-huy',
          author: DemoPeople.huy,
          photo: SamplePhotos.chicken,
          kind: MomentKind.meal,
          label: 'Gỏi gà nướng',
          caption: 'Cuối tuần ăn nhẹ thôi',
          postedAt: t.subtract(const Duration(days: 1)),
          myReactions: const {QuickReaction.fire}),
    ];
  }

  /// Giả lập Bạn bè thả cảm xúc vào Khoảnh khắc vừa chia sẻ.
  final bool simulateFriends;
  late List<Moment> _moments;
  final _controller = StreamController<List<Moment>>.broadcast();
  final _timers = <Timer>[];

  void _emit() => _controller.add(List.unmodifiable(_moments));

  void _update(String id, Moment Function(Moment) change) {
    _moments = [for (final m in _moments) m.id == id ? change(m) : m];
    _emit();
  }

  @override
  Stream<List<Moment>> watchFeed() async* {
    yield List.unmodifiable(_moments);
    yield* _controller.stream;
  }

  @override
  Future<void> share(Moment moment, {List<Person>? audience}) async {
    _moments = [moment, ..._moments];
    _emit();
    if (!simulateFriends) return;
    for (final (delay, from, emoji) in [
      (const Duration(seconds: 4), DemoPeople.linh, '🔥'),
      (const Duration(seconds: 7), DemoPeople.huy, '🥗'),
    ]) {
      _timers.add(Timer(delay, () {
        _update(
            moment.id,
            (m) => m.copyWith(
                received: [...m.received, ReceivedReaction(from, emoji)]));
      }));
    }
  }

  @override
  Future<void> setReaction(
      String momentId, QuickReaction reaction, bool on) async {
    _update(momentId, (m) {
      final next = {...m.myReactions};
      on ? next.add(reaction) : next.remove(reaction);
      return m.copyWith(myReactions: next);
    });
  }

  @override
  Future<void> setEmoji(String momentId, String? emoji) async =>
      _update(momentId, (m) => m.copyWith(myEmoji: () => emoji));

  @override
  Future<void> markSeen(String momentId) async =>
      _update(momentId, (m) => m.copyWith(unseen: false));

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _controller.close();
  }
}
