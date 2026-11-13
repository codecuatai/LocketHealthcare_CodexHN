import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/models/profile.dart';
import '../data/auth/auth_repository.dart';
import '../data/profile/profile_repository.dart';

enum AuthStatus {
  /// Đang chờ nhà cung cấp xác thực báo phiên đăng nhập đã lưu.
  initializing,
  signedOut,

  /// Đã có Tài khoản, đang đọc hoặc tạo Hồ sơ.
  loadingProfile,

  /// Có Tài khoản nhưng không tải được Hồ sơ; người dùng có thể thử lại.
  profileError,
  signedIn,
}

/// Nối Tài khoản (Firebase) với Hồ sơ (Supabase) thành một trạng thái duy nhất
/// cho giao diện. Chỉ coi là [AuthStatus.signedIn] khi đã có cả hai.
class AuthController extends ChangeNotifier {
  AuthController(
      {required AuthRepository auth, required ProfileRepository profiles})
      : _auth = auth,
        _profiles = profiles {
    _subscription = _auth.accountChanges().listen(_onAccount);
  }

  final AuthRepository _auth;
  final ProfileRepository _profiles;
  late final StreamSubscription<AuthAccount?> _subscription;

  AuthStatus _status = AuthStatus.initializing;
  AuthStatus get status => _status;

  AuthAccount? _account;
  Profile? _profile;
  Profile? get profile => _profile;

  ProfileFailure? _profileFailure;
  ProfileFailure? get profileFailure => _profileFailure;

  /// Tên người dùng vừa gõ ở màn Đăng ký, dùng khi tạo Hồ sơ.
  String? _pendingDisplayName;
  int _loadGeneration = 0;

  bool get isSignedIn => _status == AuthStatus.signedIn;

  Future<void> signIn({required String email, required String password}) =>
      _auth.signIn(email: email, password: password);

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _pendingDisplayName = displayName.trim();
    try {
      await _auth.register(
          displayName: displayName, email: email, password: password);
    } catch (_) {
      _pendingDisplayName = null;
      rethrow;
    }
  }

  Future<void> signInWithGoogle() => _auth.signInWithGoogle();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordReset(email);

  Future<void> signOut() => _auth.signOut();

  Future<void> retryProfile() async {
    final account = _account;
    if (account != null) await _loadProfile(account);
  }

  void _onAccount(AuthAccount? account) {
    final previous = _account;
    _account = account;
    if (account == null) {
      _loadGeneration++;
      _profile = null;
      _profileFailure = null;
      _pendingDisplayName = null;
      _setStatus(AuthStatus.signedOut);
      return;
    }
    // userChanges() phát lại khi tên/ảnh đổi; chỉ tải lại khi đổi Tài khoản.
    if (previous?.uid == account.uid && _status != AuthStatus.signedOut) return;
    _loadProfile(account);
  }

  Future<void> _loadProfile(AuthAccount account) async {
    final generation = ++_loadGeneration;
    _profileFailure = null;
    _setStatus(AuthStatus.loadingProfile);
    try {
      final profile = await _profiles.ensureProfile(account,
          displayName: _pendingDisplayName);
      if (generation != _loadGeneration) return;
      _pendingDisplayName = null;
      _profile = profile;
      _setStatus(AuthStatus.signedIn);
    } on ProfileFailure catch (failure) {
      if (generation != _loadGeneration) return;
      _profileFailure = failure;
      _setStatus(AuthStatus.profileError);
    }
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
