import 'package:flutter/foundation.dart';

import '../core/models/health_info.dart';
import '../data/health/health_repository.dart';
import 'safe_notifier.dart';

class HealthController extends ChangeNotifier with SafeNotifier {
  HealthController(this._repo) {
    _load();
  }

  final HealthRepository _repo;

  HealthInfo? _info;

  /// null khi người dùng chưa khai Thông tin sức khỏe.
  HealthInfo? get info => _info;
  double? get bodyKg => _info?.weightKg;
  int? get targetKcal => _info?.targetKcal;

  bool _promptShown = false;

  /// Lời nhắc thiết lập chỉ hiện một lần, ở lần chụp đầu tiên.
  bool get shouldPromptBeforeCapture => _info == null && !_promptShown;

  void markPromptShown() {
    _promptShown = true;
    notifyListeners();
  }

  Future<void> _load() async {
    _info ??= await _repo.load();
    notifyListeners();
  }

  Future<void> save(HealthInfo info) async {
    await _repo.save(info);
    _info = info;
    _promptShown = true;
    notifyListeners();
  }
}
