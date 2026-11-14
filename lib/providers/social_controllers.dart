import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/models/social.dart';
import '../data/social/chat_repository.dart';
import '../data/social/friends_repository.dart';
import '../data/social/moments_repository.dart';
import 'safe_notifier.dart';

/// Bảng tin: Khoảnh khắc của Bạn bè và của chính mình.
class MomentsController extends ChangeNotifier with SafeNotifier {
  MomentsController(this._repo) {
    _sub = _repo.watchFeed().listen((list) {
      _all = list;
      notifyListeners();
    });
  }

  final MomentsRepository _repo;
  late final StreamSubscription<List<Moment>> _sub;

  List<Moment> _all = const [];

  /// null: xem tất cả Bạn bè; ngược lại là id một người.
  String? _filter;
  String? get filter => _filter;

  set filter(String? id) {
    _filter = id;
    notifyListeners();
  }

  List<Moment> get all => _all;
  List<Moment> get visible => _filter == null
      ? _all
      : _all.where((m) => m.author.id == _filter).toList();

  List<Moment> get unseen => _all.where((m) => m.unseen).toList();
  bool hasUnseenFrom(String personId) =>
      _all.any((m) => m.unseen && m.author.id == personId);
  int countFrom(String personId) =>
      _all.where((m) => m.author.id == personId).length;
  List<Moment> get mine => _all.where((m) => m.isMine).toList();

  Future<void> toggle(Moment m, QuickReaction r) =>
      _repo.setReaction(m.id, r, !m.myReactions.contains(r));

  Future<void> pickEmoji(Moment m, String emoji) =>
      _repo.setEmoji(m.id, m.myEmoji == emoji ? null : emoji);

  Future<void> markSeen(Moment m) async {
    if (m.unseen) await _repo.markSeen(m.id);
  }

  Future<void> share(Moment m, {List<Person>? audience}) =>
      _repo.share(m, audience: audience);

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class ChatController extends ChangeNotifier with SafeNotifier {
  ChatController(this._repo) {
    _sub = _repo.watch().listen((list) {
      _convos = list;
      notifyListeners();
    });
  }

  final ChatRepository _repo;
  late final StreamSubscription<List<Conversation>> _sub;

  List<Conversation> _convos = const [];
  List<Conversation> get conversations => _convos;
  int get unreadCount => _convos.where((c) => c.unread).length;

  Conversation conversationWith(Person friend) =>
      _convos.firstWhere((c) => c.friend.id == friend.id,
          orElse: () => Conversation(friend: friend, messages: const []));

  Future<void> send(Person friend, String text, {MomentQuote? quote}) =>
      _repo.send(friend, text, quote: quote);

  Future<void> markRead(Person friend) => _repo.markRead(friend.id);

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class FriendsController extends ChangeNotifier with SafeNotifier {
  FriendsController(this._repo) {
    refresh();
  }

  final FriendsRepository _repo;

  FriendsSnapshot? _snapshot;
  List<Person> get friends => _snapshot?.friends ?? const [];
  List<Person> get invites => _snapshot?.invites ?? const [];
  String get myCode => _snapshot?.myCode ?? '';

  Future<void> refresh() async {
    _snapshot = await _repo.load();
    notifyListeners();
  }

  Future<void> respond(Person from, {required bool accept}) async {
    await _repo.respond(from, accept: accept);
    await refresh();
  }

  Future<bool> sendInvite(String code) => _repo.sendInvite(code);
}
