import 'dart:ui';

import '../../core/models/social.dart';

/// Bạn bè mẫu cho bản demo (chưa có backend Bạn bè).
abstract final class DemoPeople {
  static const linh =
      Person(id: 'linh', name: 'Linh Đan', color: Color(0xFFFFB5A0));
  static const nam =
      Person(id: 'nam', name: 'Nam Nguyễn', color: Color(0xFFC3F400));
  static const my = Person(id: 'my', name: 'Hà My', color: Color(0xFFF2C4FF));
  static const huy =
      Person(id: 'huy', name: 'Quang Huy', color: Color(0xFFFFD166));
  static const vy = Person(id: 'vy', name: 'Thảo Vy', color: Color(0xFF9AD0FF));
  static const ngoc =
      Person(id: 'ngoc', name: 'Bảo Ngọc', color: Color(0xFFB7F7C9));

  static const friends = [linh, nam, my, huy, vy];
}

/// Màu avatar của chính người dùng.
const meColor = Color(0xFF7DF4FF);

/// Người đăng tạm cho Khoảnh khắc mẫu của chính mình; giao diện thay bằng
/// Hồ sơ thật khi vẽ (Moment.isMine).
const demoMe = Person(id: 'me', name: 'Cậu', color: meColor);
