import '../format.dart';

/// Một số đếm được của Hoạt động (xem GLOSSARY.md).
enum Metric {
  sets('Số hiệp', 'hiệp', 1),
  reps('Số lần mỗi hiệp', 'lần', 1),
  weightKg('Mức tạ', 'kg', 2.5),
  count('Số cái', 'cái', 50),
  km('Quãng đường', 'km', .5),
  meters('Quãng bơi', 'm', 50),
  steps('Số bước', 'bước', 500),
  seconds('Giữ mỗi hiệp', 'giây', 10),
  minutes('Thời gian', 'phút', 5);

  const Metric(this.label, this.unit, this.step);
  final String label;
  final String unit;
  final double step;
}

enum ActivityCategory {
  gym('Gym'),
  cardio('Cardio'),
  gentle('Nhẹ nhàng');

  const ActivityCategory(this.label);
  final String label;
}

/// Loại hoạt động. [metrics] là các số bắt buộc để tính calo; thời gian
/// luôn ghi thêm được nhưng không bắt buộc, trừ môn không đếm được.
enum ActivityType {
  benchPress('Đẩy ngực', ActivityCategory.gym,
      [Metric.sets, Metric.reps, Metric.weightKg]),
  squat('Squat', ActivityCategory.gym,
      [Metric.sets, Metric.reps, Metric.weightKg],
      stressesKnees: true),
  pullUp('Kéo xà', ActivityCategory.gym, [Metric.sets, Metric.reps]),
  plank('Plank', ActivityCategory.gym, [Metric.sets, Metric.seconds]),
  running('Chạy bộ', ActivityCategory.cardio, [Metric.km], stressesKnees: true),
  cycling('Đạp xe', ActivityCategory.cardio, [Metric.km]),
  jumpRope('Nhảy dây', ActivityCategory.cardio, [Metric.count],
      stressesKnees: true),
  swimming('Bơi', ActivityCategory.cardio, [Metric.meters]),
  walking('Đi bộ chậm', ActivityCategory.gentle, [Metric.steps]),
  stationaryBike('Đạp xe tĩnh', ActivityCategory.gentle, [Metric.km]),
  yoga('Yoga', ActivityCategory.gentle, [Metric.minutes]),
  stretching('Giãn cơ', ActivityCategory.gentle, [Metric.minutes]);

  const ActivityType(this.label, this.category, this.metrics,
      {this.stressesKnees = false});

  final String label;
  final ActivityCategory category;
  final List<Metric> metrics;

  /// Dồn lực lên khớp gối: cảnh báo người có Đau khớp gối/cột sống.
  final bool stressesKnees;

  bool get timeIsOptional => !metrics.contains(Metric.minutes);

  bool isComplete(Map<Metric, double> values) =>
      metrics.every((m) => (values[m] ?? 0) > 0);

  /// Calo tiêu hao ước tính từ các số đếm và cân nặng [bodyKg].
  double kcal(Map<Metric, double> v, double bodyKg) {
    double g(Metric m) => v[m] ?? 0;
    final w = bodyKg / 70;
    return switch (this) {
      benchPress =>
        g(Metric.sets) * g(Metric.reps) * (.3 + g(Metric.weightKg) * .008) * w,
      squat =>
        g(Metric.sets) * g(Metric.reps) * (.45 + g(Metric.weightKg) * .008) * w,
      pullUp => g(Metric.sets) * g(Metric.reps) * .9 * w,
      plank => g(Metric.sets) * g(Metric.seconds) * .075 * w,
      running => 1.0 * bodyKg * g(Metric.km),
      cycling => .3 * bodyKg * g(Metric.km),
      jumpRope => .15 * (bodyKg / 65) * g(Metric.count),
      swimming => .0035 * bodyKg * g(Metric.meters),
      walking => .04 * w * g(Metric.steps),
      stationaryBike => .22 * bodyKg * g(Metric.km),
      yoga => 2.5 * bodyKg * g(Metric.minutes) / 60,
      stretching => 2.3 * bodyKg * g(Metric.minutes) / 60,
    };
  }

  /// "4 hiệp · 10 lần · 40 kg · 30 phút".
  String summary(Map<Metric, double> v) => [
        ...metrics,
        if (timeIsOptional) Metric.minutes,
      ]
          .where((m) => (v[m] ?? 0) > 0)
          .map((m) => '${formatDecimal(v[m]!)} ${m.unit}')
          .join(' · ');
}
