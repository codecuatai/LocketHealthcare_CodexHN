import 'activity.dart';
import 'photo.dart';

/// Bản ghi: một lần ghi vào Nhật ký, là Bữa ăn hoặc Hoạt động.
sealed class Entry {
  const Entry({
    required this.id,
    required this.at,
    this.photo,
    this.shared = false,
  });

  final String id;
  final DateTime at;
  final Photo? photo;

  /// Đã chia sẻ thành Khoảnh khắc cho Bạn bè.
  final bool shared;
}

class MealEntry extends Entry {
  const MealEntry({
    required super.id,
    required super.at,
    super.photo,
    super.shared,
    required this.dishName,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String dishName;
  final int kcal;
  final int proteinG;
  final int carbsG;
  final int fatG;
}

class ActivityEntry extends Entry {
  const ActivityEntry({
    required super.id,
    required super.at,
    super.photo,
    super.shared,
    required this.type,
    required this.values,
  });

  final ActivityType type;
  final Map<Metric, double> values;

  /// Calo tiêu hao; null khi chưa biết cân nặng.
  int? kcal(double? bodyKg) =>
      bodyKg == null ? null : type.kcal(values, bodyKg).round();

  String get summary => type.summary(values);
}
