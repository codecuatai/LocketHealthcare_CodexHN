import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/profile.dart';
import '../auth/auth_repository.dart';

/// Lỗi khi đọc hoặc tạo Hồ sơ (mất mạng, Supabase từ chối...).
class ProfileFailure implements Exception {
  const ProfileFailure([this.cause]);
  final Object? cause;

  String get message =>
      'Không tải được hồ sơ của bạn. Kiểm tra mạng rồi thử lại.';

  @override
  String toString() => 'ProfileFailure($cause)';
}

abstract interface class ProfileRepository {
  /// Trả về Hồ sơ của [account]; tạo mới nếu Tài khoản chưa có Hồ sơ.
  ///
  /// [displayName] được ưu tiên khi tạo mới (tên người dùng vừa gõ lúc đăng
  /// ký, vì Firebase có thể chưa kịp lưu tên vào Tài khoản).
  Future<Profile> ensureProfile(AuthAccount account, {String? displayName});
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'profiles';

  @override
  Future<Profile> ensureProfile(AuthAccount account,
      {String? displayName}) async {
    try {
      final existing = await _client
          .from(_table)
          .select()
          .eq('id', account.uid)
          .maybeSingle();
      if (existing != null) return await _syncFromAccount(existing, account);
      try {
        final created = await _client
            .from(_table)
            .insert({
              'id': account.uid,
              'email': account.email,
              'display_name': fallbackDisplayName(
                  displayName ?? account.displayName, account.email),
              'avatar_url': account.photoUrl,
            })
            .select()
            .single();
        return Profile.fromJson(created);
      } on PostgrestException catch (error) {
        // Một lần gọi song song khác vừa tạo xong Hồ sơ.
        if (error.code != '23505') rethrow;
        final row =
            await _client.from(_table).select().eq('id', account.uid).single();
        return Profile.fromJson(row);
      }
    } on ProfileFailure {
      rethrow;
    } catch (error) {
      throw ProfileFailure(error);
    }
  }

  /// Giữ email và ảnh đại diện khớp với Tài khoản (ví dụ người dùng đổi ảnh Google).
  Future<Profile> _syncFromAccount(
      Map<String, dynamic> row, AuthAccount account) async {
    final changes = <String, dynamic>{
      if (account.email.isNotEmpty && row['email'] != account.email)
        'email': account.email,
      if (row['avatar_url'] == null && account.photoUrl != null)
        'avatar_url': account.photoUrl,
    };
    if (changes.isEmpty) return Profile.fromJson(row);
    final updated = await _client
        .from(_table)
        .update(changes)
        .eq('id', account.uid)
        .select()
        .single();
    return Profile.fromJson(updated);
  }
}

/// Tên hiển thị khi người dùng chưa đặt tên: phần trước @ của email.
String fallbackDisplayName(String? name, String email) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isNotEmpty) {
    return trimmed.length > 60 ? trimmed.substring(0, 60) : trimmed;
  }
  final local = email.split('@').first.trim();
  return local.isEmpty ? 'Bạn mới' : local;
}
