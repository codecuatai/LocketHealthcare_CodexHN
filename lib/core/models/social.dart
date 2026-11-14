import 'dart:ui';

import 'photo.dart';

/// Một người trong mạng Bạn bè (hoặc chính người dùng).
class Person {
  const Person({required this.id, required this.name, required this.color});
  final String id;
  final String name;
  final Color color;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    String first(String s) =>
        s.isEmpty ? '' : String.fromCharCode(s.runes.first);
    if (parts.length == 1) return first(parts.first).toUpperCase();
    return (first(parts.first) + first(parts.last)).toUpperCase();
  }

  /// Tên gọi thân mật: chữ cuối của tên.
  String get shortName => name.trim().split(RegExp(r'\s+')).last;
}

enum QuickReaction {
  fire('🔥', 'Tiếp lửa'),
  macro('🥗', 'Chuẩn Macro');

  const QuickReaction(this.emoji, this.label);
  final String emoji;
  final String label;
}

const extraReactions = ['❤️', '😋', '💪', '👏', '😍', '🤤'];

enum MomentKind { meal, activity }

class ReceivedReaction {
  const ReceivedReaction(this.from, this.emoji);
  final Person from;
  final String emoji;
}

/// Khoảnh khắc: một Bản ghi kèm ảnh được chia sẻ cho Bạn bè.
class Moment {
  const Moment({
    required this.id,
    required this.author,
    required this.photo,
    required this.kind,
    required this.label,
    required this.postedAt,
    this.isMine = false,
    this.kcal,
    this.caption = '',
    this.myReactions = const {},
    this.myEmoji,
    this.unseen = false,
    this.received = const [],
  });

  final String id;
  final Person author;
  final bool isMine;
  final Photo photo;
  final MomentKind kind;

  /// Tên món hoặc tên hoạt động, ví dụ "Chạy bộ · 5 km".
  final String label;

  /// Chỉ có khi người đăng bật "Hiện calo" (Quyền riêng tư kép).
  final int? kcal;
  final String caption;
  final DateTime postedAt;
  final Set<QuickReaction> myReactions;
  final String? myEmoji;
  final bool unseen;

  /// Cảm xúc Bạn bè thả vào Khoảnh khắc của mình; chỉ người đăng thấy.
  final List<ReceivedReaction> received;

  Moment copyWith({
    Set<QuickReaction>? myReactions,
    String? Function()? myEmoji,
    bool? unseen,
    List<ReceivedReaction>? received,
  }) =>
      Moment(
        id: id,
        author: author,
        isMine: isMine,
        photo: photo,
        kind: kind,
        label: label,
        kcal: kcal,
        caption: caption,
        postedAt: postedAt,
        myReactions: myReactions ?? this.myReactions,
        myEmoji: myEmoji != null ? myEmoji() : this.myEmoji,
        unseen: unseen ?? this.unseen,
        received: received ?? this.received,
      );
}

/// Trích dẫn một Khoảnh khắc ở đầu tin nhắn trả lời.
class MomentQuote {
  const MomentQuote({required this.photo, required this.label});
  final Photo photo;
  final String label;
}

class ChatMessage {
  const ChatMessage(
      {required this.fromMe, required this.text, required this.at, this.quote});
  final bool fromMe;
  final String text;
  final DateTime at;
  final MomentQuote? quote;
}

class Conversation {
  const Conversation({
    required this.friend,
    required this.messages,
    this.unread = false,
    this.friendTyping = false,
  });

  final Person friend;
  final List<ChatMessage> messages;
  final bool unread;
  final bool friendTyping;

  Conversation copyWith(
          {List<ChatMessage>? messages, bool? unread, bool? friendTyping}) =>
      Conversation(
        friend: friend,
        messages: messages ?? this.messages,
        unread: unread ?? this.unread,
        friendTyping: friendTyping ?? this.friendTyping,
      );
}
