import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    this.googleServerClientId,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _google = googleSignIn ?? GoogleSignIn.instance {
    // Email đặt lại mật khẩu gửi bằng tiếng Việt.
    _auth.setLanguageCode('vi');
  }

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  /// Web client ID từ Firebase (OAuth). Android cần giá trị này nếu
  /// google-services.json không có sẵn `default_web_client_id`.
  final String? googleServerClientId;
  Future<void>? _googleReady;

  @override
  Stream<AuthAccount?> accountChanges() =>
      _auth.userChanges().map((user) => user == null ? null : _toAccount(user));

  @override
  Future<AuthAccount> signIn({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final result = await _auth.signInWithEmailAndPassword(
            email: email.trim(), password: password);
        return _toAccount(result.user!);
      });

  @override
  Future<AuthAccount> register({
    required String displayName,
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final result = await _auth.createUserWithEmailAndPassword(
            email: email.trim(), password: password);
        final user = result.user!;
        await user.updateDisplayName(displayName.trim());
        return AuthAccount(
          uid: user.uid,
          email: user.email ?? email.trim(),
          displayName: displayName.trim(),
          photoUrl: user.photoURL,
        );
      });

  @override
  Future<AuthAccount> signInWithGoogle() => _guard(() async {
        await (_googleReady ??=
            _google.initialize(serverClientId: googleServerClientId));
        if (!_google.supportsAuthenticate()) {
          throw const AuthFailure(AuthFailureCode.googleUnavailable);
        }
        final GoogleSignInAccount account;
        try {
          account = await _google.authenticate();
        } on GoogleSignInException catch (error) {
          throw AuthFailure(switch (error.code) {
            GoogleSignInExceptionCode.canceled ||
            GoogleSignInExceptionCode.interrupted =>
              AuthFailureCode.canceled,
            GoogleSignInExceptionCode.clientConfigurationError ||
            GoogleSignInExceptionCode.providerConfigurationError ||
            GoogleSignInExceptionCode.uiUnavailable =>
              AuthFailureCode.googleUnavailable,
            _ => AuthFailureCode.unknown,
          });
        }
        final credential = GoogleAuthProvider.credential(
            idToken: account.authentication.idToken);
        final result = await _auth.signInWithCredential(credential);
        return _toAccount(result.user!);
      });

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // Lần sau bấm Google sẽ hỏi lại chọn tài khoản nào.
    if (_googleReady != null) await _google.signOut();
  }

  static AuthAccount _toAccount(User user) => AuthAccount(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebaseCode(error.code);
    }
  }
}
