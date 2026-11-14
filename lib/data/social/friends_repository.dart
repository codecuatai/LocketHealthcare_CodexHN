import '../../core/models/social.dart';
import '../demo/demo_people.dart';

class FriendsSnapshot {
  const FriendsSnapshot(
      {required this.friends, required this.invites, required this.myCode});
  final List<Person> friends;

  /// Lời mời kết bạn đang chờ cậu trả lời.
  final List<Person> invites;

  /// Mã kết bạn của cậu, gửi cho người khác để kết bạn.
  final String myCode;
}

abstract interface class FriendsRepository {
  Future<FriendsSnapshot> load();
  Future<void> respond(Person from, {required bool accept});

  /// Gửi lời mời theo mã; trả về false nếu mã không đúng dạng.
  Future<bool> sendInvite(String code);
}

class DemoFriendsRepository implements FriendsRepository {
  final _friends = [...DemoPeople.friends];
  final _invites = [DemoPeople.ngoc];

  @override
  Future<FriendsSnapshot> load() async => FriendsSnapshot(
      friends: List.unmodifiable(_friends),
      invites: List.unmodifiable(_invites),
      myCode: 'VITA-7K2Q');

  @override
  Future<void> respond(Person from, {required bool accept}) async {
    _invites.removeWhere((p) => p.id == from.id);
    if (accept) _friends.add(from);
  }

  @override
  Future<bool> sendInvite(String code) async =>
      RegExp(r'^[A-Z]{3,6}-[A-Z0-9]{4}$').hasMatch(code.trim().toUpperCase());
}
