import 'package:flutter_test/flutter_test.dart';
import 'package:vitasnap/core/format.dart';
import 'package:vitasnap/core/models/activity.dart';
import 'package:vitasnap/core/models/health_info.dart';
import 'package:vitasnap/data/journal/journal_repository.dart';

void main() {
  group('HealthInfo', () {
    const info = HealthInfo(
        sex: Sex.male,
        birthYear: 1999,
        heightCm: 172,
        weightKg: 70,
        goal: HealthGoal.loseFat);

    test('suggests a target from body and goal', () {
      // BMR 1645 × 1,375 − 400 ≈ 1862 → làm tròn 1860.
      expect(info.suggestedTargetKcal(year: 2026), 1860);
      expect(
          info
              .copyWith(goal: HealthGoal.maintain)
              .suggestedTargetKcal(year: 2026),
          2260);
    });

    test('a custom target wins over the suggestion', () {
      expect(info.copyWith(customTargetKcal: () => 2000).targetKcal, 2000);
    });

    test('no condition declared means none', () {
      expect(info.has(MedicalCondition.hypertension), isFalse);
    });
  });

  group('ActivityType', () {
    test('kcal comes from counts and body weight', () {
      expect(ActivityType.running.kcal({Metric.km: 5}, 70), 350);
      expect(ActivityType.jumpRope.kcal({Metric.count: 300}, 65),
          closeTo(45, .01));
      expect(ActivityType.walking.kcal({Metric.steps: 3000}, 70), 120);
    });

    test('time is optional except for uncountable activities', () {
      expect(ActivityType.running.timeIsOptional, isTrue);
      expect(ActivityType.yoga.timeIsOptional, isFalse);
      expect(
          ActivityType.benchPress.isComplete({Metric.sets: 4, Metric.reps: 10}),
          isFalse);
    });

    test('summary lists counts then optional time', () {
      expect(
          ActivityType.benchPress.summary({
            Metric.sets: 4,
            Metric.reps: 10,
            Metric.weightKg: 42.5,
            Metric.minutes: 30
          }),
          '4 hiệp · 10 lần · 42,5 kg · 30 phút');
    });
  });

  group('format', () {
    test('uses Vietnamese separators', () {
      expect(formatInt(1850), '1.850');
      expect(formatInt(-12345), '-12.345');
      expect(formatDecimal(5.25), '5,3');
      expect(formatDecimal(5), '5');
    });

    test('relative time', () {
      final now = DateTime(2026, 11, 14, 19);
      expect(relativeTime(now.subtract(const Duration(minutes: 20)), now),
          '20 phút');
      expect(
          relativeTime(now.subtract(const Duration(hours: 3)), now), '3 giờ');
      expect(relativeTime(DateTime(2026, 11, 13, 9), now), 'Hôm qua');
      expect(relativeTime(DateTime(2026, 11, 2, 9), now), '2/11');
    });
  });

  group('DemoJournalRepository', () {
    test('streak counts back to the last missed day', () async {
      final repo = DemoJournalRepository(now: DateTime(2026, 11, 14, 19));
      expect(await repo.streak(DateTime(2026, 11, 14)), 12);
    });

    test('last values prefer the newest entry of that type', () async {
      final repo = DemoJournalRepository(now: DateTime(2026, 11, 14, 19));
      expect(await repo.lastValues(ActivityType.running),
          {Metric.km: 5, Metric.minutes: 32});
      expect(await repo.lastValues(ActivityType.benchPress), isNull);
    });

    test('burn is unknown without body weight', () async {
      final repo = DemoJournalRepository(now: DateTime(2026, 11, 14, 19));
      final days = await repo.lastDays(30, DateTime(2026, 11, 14));
      expect(days, hasLength(30));
      expect(days.last.intakeKcal, 940);
      expect(days.every((d) => d.burnKcal == null), isTrue);
      expect(days.where((d) => !d.logged), hasLength(3));
    });
  });
}
