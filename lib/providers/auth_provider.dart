import 'package:flutter/foundation.dart';
import '../core/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Local UI sign-in only: credentials are never stored or transmitted.
  void login(String email, String password) {
    final normalized = email.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized) ||
        password.isEmpty) {
      throw const FormatException('Nhập email hợp lệ và mật khẩu.');
    }
    _currentUser = UserModel(
        name: normalized.split('@').first,
        age: 0,
        weightKg: 0,
        conditions: const [],
        targetKcal: 2000,
        goal: 'Cân bằng');
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void switchDemoUser(DemoPreset preset) {
    _currentUser =
        preset == DemoPreset.userA ? UserModel.demoA : UserModel.demoB;
    notifyListeners();
  }
}
