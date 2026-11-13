/// Quy tắc kiểm tra form Đăng nhập / Đăng ký, kèm thông báo tiếng Việt.
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const displayNameMaxLength = 60;

  static String? email(String value) => _email.hasMatch(value.trim())
      ? null
      : 'Email chưa đúng định dạng, ví dụ ten@gmail.com.';

  static String? loginPassword(String value) =>
      value.isEmpty ? 'Nhập mật khẩu.' : null;

  static String? displayName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Nhập tên để bạn bè nhận ra bạn.';
    if (trimmed.length > displayNameMaxLength) {
      return 'Tên tối đa $displayNameMaxLength ký tự.';
    }
    return null;
  }

  static String? newPassword(String value) => PasswordCheck(value).isAcceptable
      ? null
      : 'Mật khẩu cần ít nhất 8 ký tự, có cả chữ và số.';
}

enum PasswordStrength {
  empty(''),
  weak('Yếu'),
  fair('Trung bình'),
  strong('Mạnh'),
  veryStrong('Rất mạnh');

  const PasswordStrength(this.label);
  final String label;
}

/// Đánh giá mật khẩu mới: đủ điều kiện chưa, mạnh tới đâu, còn thiếu gì.
class PasswordCheck {
  PasswordCheck(this.value);

  static const minLength = 8;
  static final _letter = RegExp(r'\p{L}', unicode: true);
  static final _digit = RegExp(r'\d');
  static final _lower = RegExp(r'\p{Ll}', unicode: true);
  static final _upper = RegExp(r'\p{Lu}', unicode: true);
  static final _symbol = RegExp(r'[^\p{L}\d]', unicode: true);

  final String value;

  bool get longEnough => value.length >= minLength;
  bool get hasLetter => _letter.hasMatch(value);
  bool get hasDigit => _digit.hasMatch(value);
  bool get isAcceptable => longEnough && hasLetter && hasDigit;

  PasswordStrength get strength {
    if (value.isEmpty) return PasswordStrength.empty;
    var score = 0;
    if (longEnough) score++;
    if (hasLetter && hasDigit) score++;
    if (_lower.hasMatch(value) && _upper.hasMatch(value)) score++;
    if (_symbol.hasMatch(value) || value.length >= 12) score++;
    return PasswordStrength.values[score.clamp(1, 4)];
  }

  /// Một dòng gợi ý ngắn: điều còn thiếu, hoặc mức độ mạnh khi đã đạt.
  String get hint {
    if (value.isEmpty) return '8+ ký tự, có chữ và số';
    if (!longEnough) return 'Cần thêm ${minLength - value.length} ký tự';
    if (!hasLetter) return 'Thêm chữ cái';
    if (!hasDigit) return 'Thêm một chữ số';
    return strength.label;
  }
}
