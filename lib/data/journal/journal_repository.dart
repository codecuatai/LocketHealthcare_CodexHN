import 'dart:math';

import '../../core/format.dart';
import '../../core/models/activity.dart';
import '../../core/models/entry.dart';
import '../../core/models/photo.dart';

/// Tổng calo một ngày trong Nhật ký.
class DayTotals {
  const DayTotals({
    required this.date,
    required this.intakeKcal,
    required this.burnKcal,
    required this.logged,
  });

  final DateTime date;
  final int intakeKcal;

  /// null khi chưa biết cân nặng để tính calo tiêu hao.
  final int? burnKcal;

  /// Ngày đó có ít nhất một Bản ghi.
  final bool logged;
}

abstract interface class JournalRepository {
  Future<List<Entry>> entriesOn(DateTime day);
  Future<void> add(Entry entry);

  /// [count] ngày gần nhất tính tới [today], cũ nhất trước.
  Future<List<DayTotals>> lastDays(int count, DateTime today, {double? bodyKg});

  /// Số liệu của lần gần nhất ghi [type], để điền sẵn.
  Future<Map<Metric, double>?> lastValues(ActivityType type);

  /// Số ngày liên tiếp tới hôm nay có ít nhất một Bản ghi.
  Future<int> streak(DateTime today);
}

/// Nhật ký mẫu: vài Bản ghi hôm nay và 29 ngày trước đó sinh ngẫu nhiên cố định.
class DemoJournalRepository implements JournalRepository {
  DemoJournalRepository({DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    DateTime at(int h, int m) => today.add(Duration(hours: h, minutes: m));
    _entries.addAll([
      MealEntry(
          id: 'seed-1',
          at: at(7, 40),
          photo: SamplePhotos.eggSalad,
          dishName: 'Salad trứng quinoa',
          kcal: 420,
          proteinG: 22,
          carbsG: 38,
          fatG: 18),
      MealEntry(
          id: 'seed-2',
          at: at(12, 15),
          photo: SamplePhotos.chicken,
          shared: true,
          dishName: 'Gỏi gà nướng',
          kcal: 520,
          proteinG: 34,
          carbsG: 46,
          fatG: 20),
      ActivityEntry(
          id: 'seed-3',
          at: at(17, 30),
          photo: SamplePhotos.bottle,
          type: ActivityType.stationaryBike,
          values: const {Metric.km: 8, Metric.minutes: 25}),
    ]);
  }

  final _entries = <Entry>[];

  /// Lần ghi trước hôm nay (trong lịch sử mẫu).
  static const _olderValues = <ActivityType, Map<Metric, double>>{
    ActivityType.running: {Metric.km: 5, Metric.minutes: 32},
    ActivityType.walking: {Metric.steps: 3000},
  };

  /// Các ngày trong lịch sử mẫu không có Bản ghi (tính lùi từ hôm nay).
  static const _missedDaysAgo = {27, 19, 12};

  @override
  Future<List<Entry>> entriesOn(DateTime day) async =>
      _entries.where((e) => sameDay(e.at, day)).toList()
        ..sort((a, b) => a.at.compareTo(b.at));

  @override
  Future<void> add(Entry entry) async => _entries.add(entry);

  @override
  Future<List<DayTotals>> lastDays(int count, DateTime today,
      {double? bodyKg}) async {
    final rnd = Random(7);
    final day0 = dateOnly(today);
    final out = <DayTotals>[];
    for (var ago = count - 1; ago >= 0; ago--) {
      final date = day0.subtract(Duration(days: ago));
      final r1 = rnd.nextDouble(), r2 = rnd.nextDouble(), r3 = rnd.nextDouble();
      if (ago == 0) {
        final todays = await entriesOn(date);
        out.add(_totals(date, todays, bodyKg));
        continue;
      }
      if (_missedDaysAgo.contains(ago)) {
        out.add(DayTotals(
            date: date,
            intakeKcal: 0,
            burnKcal: bodyKg == null ? null : 0,
            logged: false));
        continue;
      }
      final weekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      final burn = r3 < .3 ? 0 : (90 + r2 * 260) * (bodyKg ?? 70) / 70;
      out.add(DayTotals(
        date: date,
        intakeKcal: (1650 + r1 * 420 + (weekend ? 330 : 0)).round(),
        burnKcal: bodyKg == null ? null : burn.round(),
        logged: true,
      ));
    }
    return out;
  }

  DayTotals _totals(DateTime date, List<Entry> entries, double? bodyKg) {
    var intake = 0, burn = 0;
    for (final e in entries) {
      switch (e) {
        case MealEntry(:final kcal):
          intake += kcal;
        case ActivityEntry():
          burn += e.kcal(bodyKg) ?? 0;
      }
    }
    return DayTotals(
        date: date,
        intakeKcal: intake,
        burnKcal: bodyKg == null ? null : burn,
        logged: entries.isNotEmpty);
  }

  @override
  Future<Map<Metric, double>?> lastValues(ActivityType type) async {
    final mine = _entries
        .whereType<ActivityEntry>()
        .where((e) => e.type == type)
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    if (mine.isNotEmpty) return Map.of(mine.last.values);
    final older = _olderValues[type];
    return older == null ? null : Map.of(older);
  }

  @override
  Future<int> streak(DateTime today) async {
    final day0 = dateOnly(today);
    // Hôm nay chưa ghi thì chuỗi chưa đứt, chỉ chưa được cộng.
    var count = (await entriesOn(day0)).isNotEmpty ? 1 : 0;
    for (var ago = 1; ago < 30 && !_missedDaysAgo.contains(ago); ago++) {
      count++;
    }
    return count;
  }
}
