import 'activity.dart';

enum FitVerdict {
  good('Phù hợp'),
  adjust('Nên điều chỉnh'),
  avoid('Nên tránh');

  const FitVerdict(this.label);
  final String label;
}

/// Một lý do của mức phù hợp, gắn với một Bệnh lý nền hoặc dinh dưỡng chung.
class FitReason {
  const FitReason(this.tag, this.text);
  final String tag;
  final String text;
}

/// Kết quả AI phân tích một món ăn, cho một khẩu phần chuẩn.
class FoodAnalysis {
  const FoodAnalysis({
    required this.dishName,
    required this.mealLabel,
    required this.servingLabel,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.verdict,
    required this.reasons,
    required this.tips,
    this.confident = true,
  });

  final String dishName;

  /// "Bữa tối", "Đồ uống"...
  final String mealLabel;
  final String servingLabel;
  final int kcal;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final FitVerdict verdict;
  final List<FitReason> reasons;
  final List<String> tips;

  /// false khi AI không nhận ra món: người dùng nên sửa tên.
  final bool confident;
}

/// AI phân loại ảnh trước khi phân tích (bộ lọc ảnh).
sealed class PhotoVerdict {
  const PhotoVerdict();
}

class FoodPhoto extends PhotoVerdict {
  const FoodPhoto(this.label);
  final String label;
}

class ActivityPhoto extends PhotoVerdict {
  const ActivityPhoto(this.type);

  /// null khi AI thấy là lúc vận động nhưng không rõ môn gì.
  final ActivityType? type;
}

/// Vùng xám: AI cần người dùng xác nhận một chạm.
class UncertainPhoto extends PhotoVerdict {
  const UncertainPhoto(this.detail);
  final String detail;
}

class RejectedPhoto extends PhotoVerdict {
  const RejectedPhoto();
}

/// Gợi ý của AI Coach, luôn kèm lý do an toàn.
class CoachTip {
  const CoachTip({required this.text, required this.why, this.general = false});
  final String text;
  final String why;

  /// Gợi ý chung khi chưa có Thông tin sức khỏe.
  final bool general;
}

/// Một thói quen AI nhận ra từ Nhật ký nhiều ngày.
class HabitInsight {
  const HabitInsight(this.kind, this.title, this.detail);
  final InsightKind kind;
  final String title;
  final String detail;
}

enum InsightKind { weekend, sodium, streak }
