enum Sex {
  male('Nam'),
  female('Nữ');

  const Sex(this.label);
  final String label;
}

/// Mục tiêu sức khỏe; [kcalAdjustment] cộng vào mức tiêu hao mỗi ngày.
enum HealthGoal {
  loseFat('Giảm mỡ', -400),
  maintain('Giữ dáng', 0),
  gainMuscle('Tăng cơ', 300);

  const HealthGoal(this.label, this.kcalAdjustment);
  final String label;
  final int kcalAdjustment;
}

/// Bệnh lý nền: ràng buộc cứng cho mọi gợi ý ăn uống và vận động.
enum MedicalCondition {
  diabetes('Tiểu đường'),
  hypertension('Huyết áp cao'),
  heartDisease('Tim mạch'),
  gout('Gout'),
  stomach('Đau dạ dày'),
  jointPain('Đau khớp gối/cột sống'),
  asthma('Hen suyễn'),
  foodAllergy('Dị ứng thực phẩm');

  const MedicalCondition(this.label);
  final String label;
}

enum ConditionSeverity {
  mild('Nhẹ'),
  monitoring('Đang theo dõi'),
  restricted('Hạn chế vận động nặng');

  const ConditionSeverity(this.label);
  final String label;
}

/// Thông tin sức khỏe: phần riêng tư, chỉ chủ Tài khoản và AI dùng
/// (xem GLOSSARY.md). Không có Bệnh lý nền nào nghĩa là người dùng khỏe mạnh.
class HealthInfo {
  const HealthInfo({
    required this.sex,
    required this.birthYear,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    this.conditions = const {},
    this.customTargetKcal,
  });

  final Sex sex;
  final int birthYear;
  final double heightCm;
  final double weightKg;
  final HealthGoal goal;
  final Map<MedicalCondition, ConditionSeverity> conditions;

  /// Mục tiêu calo người dùng tự đặt; null thì dùng [suggestedTargetKcal].
  final int? customTargetKcal;

  bool has(MedicalCondition condition) => conditions.containsKey(condition);

  int ageIn(int year) => year - birthYear;

  /// Mục tiêu calo tính từ cơ thể (Mifflin-St Jeor, vận động nhẹ) và mục tiêu.
  int suggestedTargetKcal({int? year}) => suggestTargetKcal(
      sex: sex,
      age: ageIn(year ?? DateTime.now().year),
      heightCm: heightCm,
      weightKg: weightKg,
      goal: goal);

  int get targetKcal => customTargetKcal ?? suggestedTargetKcal();

  HealthInfo copyWith({
    Sex? sex,
    int? birthYear,
    double? heightCm,
    double? weightKg,
    HealthGoal? goal,
    Map<MedicalCondition, ConditionSeverity>? conditions,
    int? Function()? customTargetKcal,
  }) =>
      HealthInfo(
        sex: sex ?? this.sex,
        birthYear: birthYear ?? this.birthYear,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        goal: goal ?? this.goal,
        conditions: conditions ?? this.conditions,
        customTargetKcal: customTargetKcal != null
            ? customTargetKcal()
            : this.customTargetKcal,
      );
}

int suggestTargetKcal({
  required Sex sex,
  required int age,
  required double heightCm,
  required double weightKg,
  required HealthGoal goal,
}) {
  final bmr =
      10 * weightKg + 6.25 * heightCm - 5 * age + (sex == Sex.male ? 5 : -161);
  final daily = bmr * 1.375 + goal.kcalAdjustment;
  return (daily / 10).round() * 10;
}
