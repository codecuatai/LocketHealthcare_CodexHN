/// Tài khoản đang đăng nhập, đúng như nhà cung cấp xác thực báo về.
class AuthAccount {
  const AuthAccount({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
}

enum AuthFailureCode {
  invalidCredentials,
  emailInUse,
  weakPassword,
  invalidEmail,
  tooManyRequests,
  network,
  userDisabled,
  accountExistsWithDifferentCredential,
  canceled,
  googleUnavailable,
  unknown,
}

/// Lỗi xác thực, kèm thông báo tiếng Việt hiển thị thẳng cho người dùng.
class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final AuthFailureCode code;

  String get message => switch (code) {
        AuthFailureCode.invalidCredentials =>
          'Email hoặc mật khẩu không đúng. Kiểm tra lại rồi thử lần nữa.',
        AuthFailureCode.emailInUse => 'Email này đã có tài khoản.',
        AuthFailureCode.weakPassword =>
          'Mật khẩu cần ít nhất 8 ký tự, có cả chữ và số.',
        AuthFailureCode.invalidEmail =>
          'Email chưa đúng định dạng, ví dụ ten@gmail.com.',
        AuthFailureCode.tooManyRequests =>
          'Bạn đã thử sai quá nhiều lần. Đợi vài phút rồi thử lại.',
        AuthFailureCode.network =>
          'Không kết nối được. Kiểm tra mạng rồi thử lại.',
        AuthFailureCode.userDisabled =>
          'Tài khoản này đã bị khóa. Liên hệ hỗ trợ để được giúp.',
        AuthFailureCode.accountExistsWithDifferentCredential =>
          'Email này đã đăng ký theo cách khác. Hãy đăng nhập bằng email và mật khẩu.',
        AuthFailureCode.canceled => 'Bạn đã huỷ đăng nhập.',
        AuthFailureCode.googleUnavailable =>
          'Thiết bị này chưa hỗ trợ đăng nhập bằng Google.',
        AuthFailureCode.unknown => 'Có lỗi xảy ra. Thử lại sau ít phút.',
      };

  /// Ánh xạ mã lỗi của Firebase Auth sang [AuthFailureCode].
  ///
  /// Firebase bật Email Enumeration Protection nên đăng nhập sai chỉ trả về
  /// `invalid-credential`; các mã cũ vẫn được gộp vào cùng một thông báo để
  /// không bao giờ tiết lộ email có tồn tại hay không.
  static AuthFailure fromFirebaseCode(String code) => AuthFailure(
        switch (code) {
          'invalid-credential' ||
          'INVALID_LOGIN_CREDENTIALS' ||
          'wrong-password' ||
          'user-not-found' =>
            AuthFailureCode.invalidCredentials,
          'email-already-in-use' => AuthFailureCode.emailInUse,
          'weak-password' ||
          'password-does-not-meet-requirements' =>
            AuthFailureCode.weakPassword,
          'invalid-email' || 'missing-email' => AuthFailureCode.invalidEmail,
          'too-many-requests' => AuthFailureCode.tooManyRequests,
          'network-request-failed' => AuthFailureCode.network,
          'user-disabled' => AuthFailureCode.userDisabled,
          'account-exists-with-different-credential' =>
            AuthFailureCode.accountExistsWithDifferentCredential,
          _ => AuthFailureCode.unknown,
        },
      );

  @override
  String toString() => 'AuthFailure($code)';
}

/// Cổng vào nhà cung cấp xác thực. Mọi lỗi được ném ra dưới dạng [AuthFailure].
abstract interface class AuthRepository {
  /// Phát Tài khoản hiện tại mỗi khi đăng nhập/đăng xuất; phát ngay giá trị
  /// đầu tiên khi được lắng nghe.
  Stream<AuthAccount?> accountChanges();

  Future<AuthAccount> signIn({required String email, required String password});

  Future<AuthAccount> register({
    required String displayName,
    required String email,
    required String password,
  });

  Future<AuthAccount> signInWithGoogle();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
