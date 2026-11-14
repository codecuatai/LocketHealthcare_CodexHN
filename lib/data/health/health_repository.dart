import '../../core/models/health_info.dart';

/// Lưu Thông tin sức khỏe (riêng tư) của người dùng.
abstract interface class HealthRepository {
  /// null khi người dùng chưa khai.
  Future<HealthInfo?> load();
  Future<void> save(HealthInfo info);
}

class InMemoryHealthRepository implements HealthRepository {
  InMemoryHealthRepository([this._info]);
  HealthInfo? _info;

  @override
  Future<HealthInfo?> load() async => _info;

  @override
  Future<void> save(HealthInfo info) async => _info = info;
}
