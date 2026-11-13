import 'dart:async';

import 'package:vitasnap/core/models/profile.dart';
import 'package:vitasnap/data/auth/auth_repository.dart';
import 'package:vitasnap/data/profile/profile_repository.dart';

/// Giả lập Firebase Auth: phát Tài khoản qua stream giống `userChanges()`.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthAccount? signedIn}) : _current = signedIn;

  final _changes = StreamController<AuthAccount?>.broadcast();
  AuthAccount? _current;

  /// Lỗi sẽ ném ra ở lần gọi kế tiếp (rồi tự xoá).
  AuthFailure? nextFailure;
  final resetEmails = <String>[];

  void emit(AuthAccount? account) {
    _current = account;
    _changes.add(account);
  }

  void _throwIfFailing() {
    final failure = nextFailure;
    nextFailure = null;
    if (failure != null) throw failure;
  }

  @override
  Stream<AuthAccount?> accountChanges() async* {
    yield _current;
    yield* _changes.stream;
  }

  @override
  Future<AuthAccount> signIn(
      {required String email, required String password}) async {
    _throwIfFailing();
    final account = AuthAccount(uid: 'uid-$email', email: email);
    emit(account);
    return account;
  }

  @override
  Future<AuthAccount> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _throwIfFailing();
    // Firebase báo Tài khoản mới trước khi kịp lưu tên hiển thị.
    final bare = AuthAccount(uid: 'uid-$email', email: email);
    emit(bare);
    final named =
        AuthAccount(uid: bare.uid, email: email, displayName: displayName);
    emit(named);
    return named;
  }

  @override
  Future<AuthAccount> signInWithGoogle() async {
    _throwIfFailing();
    const account = AuthAccount(
        uid: 'uid-google',
        email: 'minh.an@gmail.com',
        displayName: 'Minh An',
        photoUrl: 'https://example.com/a.png');
    emit(account);
    return account;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    _throwIfFailing();
    resetEmails.add(email);
  }

  @override
  Future<void> signOut() async => emit(null);
}

/// Giả lập bảng `profiles` trên Supabase.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([Map<String, Profile>? rows]) : rows = rows ?? {};

  final Map<String, Profile> rows;
  int failuresLeft = 0;
  int calls = 0;
  final requestedNames = <String?>[];

  @override
  Future<Profile> ensureProfile(AuthAccount account,
      {String? displayName}) async {
    calls++;
    requestedNames.add(displayName);
    if (failuresLeft > 0) {
      failuresLeft--;
      throw const ProfileFailure('offline');
    }
    return rows.putIfAbsent(
        account.uid,
        () => Profile(
              id: account.uid,
              email: account.email,
              displayName: fallbackDisplayName(
                  displayName ?? account.displayName, account.email),
              avatarUrl: account.photoUrl,
            ));
  }
}
