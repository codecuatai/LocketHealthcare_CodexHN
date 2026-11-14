/// Hồ sơ: phần Bạn bè nhìn thấy về con người đứng sau một Tài khoản
/// (xem GLOSSARY.md). Chỉ số sức khỏe nằm riêng trong [HealthInfo].
class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  /// Firebase UID của Tài khoản sở hữu Hồ sơ.
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['display_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
      );
}
