import 'package:flutter/foundation.dart';

/// Bỏ qua thông báo đến sau khi controller đã bị huỷ (ví dụ một Future
/// trả về sau khi người dùng đăng xuất).
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
