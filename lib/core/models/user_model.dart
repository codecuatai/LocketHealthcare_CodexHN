enum DemoPreset { userA, userB }

class UserModel {
  const UserModel(
      {required this.name,
      required this.age,
      required this.weightKg,
      required this.conditions,
      required this.targetKcal,
      required this.goal,
      this.preset});
  final String name;
  final int age;
  final int weightKg;
  final List<String> conditions;
  final int targetKcal;
  final String goal;
  final DemoPreset? preset;
  bool get hasMedicalConditions => conditions.isNotEmpty;

  static const demoA = UserModel(
      name: 'Nguyễn Văn A',
      age: 32,
      weightKg: 78,
      conditions: ['Đau khớp gối', 'Huyết áp cao'],
      targetKcal: 1800,
      goal: 'Giảm mỡ',
      preset: DemoPreset.userA);
  static const demoB = UserModel(
      name: 'Trần Minh B',
      age: 24,
      weightKg: 70,
      conditions: [],
      targetKcal: 2600,
      goal: 'Tăng cơ',
      preset: DemoPreset.userB);
}
