/// Mục tiêu sức khỏe người dùng chọn trong Hồ sơ.
enum HealthGoal {
  loseFat('lose_fat', 'Giảm mỡ'),
  gainMuscle('gain_muscle', 'Tăng cơ'),
  maintain('maintain', 'Giữ dáng');

  const HealthGoal(this.code, this.label);
  final String code;
  final String label;

  static HealthGoal? fromCode(Object? code) {
    for (final goal in values) {
      if (goal.code == code) return goal;
    }
    return null;
  }
}

/// Bệnh lý nền: ràng buộc cứng cho mọi gợi ý ăn uống và vận động.
enum MedicalCondition {
  diabetes('diabetes', 'Tiểu đường'),
  hypertension('hypertension', 'Huyết áp cao'),
  heartDisease('heart_disease', 'Tim mạch'),
  gout('gout', 'Gout'),
  stomach('stomach', 'Đau dạ dày'),
  jointPain('joint_pain', 'Đau khớp gối/cột sống'),
  asthma('asthma', 'Hen suyễn'),
  foodAllergy('food_allergy', 'Dị ứng thực phẩm');

  const MedicalCondition(this.code, this.label);
  final String code;
  final String label;

  static MedicalCondition? fromCode(Object? code) {
    for (final condition in values) {
      if (condition.code == code) return condition;
    }
    return null;
  }
}

/// Hồ sơ: thông tin về con người đứng sau một Tài khoản (xem GLOSSARY.md).
///
/// Chỉ số sức khỏe để trống cho tới khi người dùng hoàn thành Onboarding;
/// các getter `effective*` trả về giá trị mặc định an toàn trong lúc chờ.
class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.birthYear,
    this.heightCm,
    this.weightKg,
    this.goal,
    this.conditions = const [],
    this.targetKcal,
  });

  static const defaultTargetKcal = 2000;

  /// Firebase UID của Tài khoản sở hữu Hồ sơ.
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final int? birthYear;
  final double? heightCm;
  final double? weightKg;
  final HealthGoal? goal;
  final List<MedicalCondition> conditions;
  final int? targetKcal;

  bool get hasMedicalConditions => conditions.isNotEmpty;
  int get effectiveTargetKcal => targetKcal ?? defaultTargetKcal;
  String get goalLabel => goal?.label ?? 'Chưa đặt mục tiêu';

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['display_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        birthYear: (json['birth_year'] as num?)?.toInt(),
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        goal: HealthGoal.fromCode(json['goal']),
        conditions: [
          for (final code in (json['conditions'] as List?) ?? const [])
            if (MedicalCondition.fromCode(code) case final condition?)
              condition,
        ],
        targetKcal: (json['target_kcal'] as num?)?.toInt(),
      );
}
