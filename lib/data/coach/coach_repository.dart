import '../../core/format.dart';
import '../../core/models/activity.dart';
import '../../core/models/analysis.dart';
import '../../core/models/entry.dart';
import '../../core/models/health_info.dart';
import '../journal/journal_repository.dart';

/// AI Coach: gợi ý hôm nay và thói quen nhiều ngày, luôn kèm lý do an toàn.
abstract interface class CoachRepository {
  Future<CoachTip> today(List<Entry> entries, {HealthInfo? health});
  Future<List<HabitInsight>> habits(List<DayTotals> days, {HealthInfo? health});
}

/// Coach giả lập theo luật đơn giản (bản thật gọi LLM kèm Bệnh lý nền).
class DemoCoachRepository implements CoachRepository {
  @override
  Future<CoachTip> today(List<Entry> entries, {HealthInfo? health}) async {
    final ateSalty = entries
        .whereType<MealEntry>()
        .any((e) => e.dishName.toLowerCase().contains('phở'));
    final minutes = entries
        .whereType<ActivityEntry>()
        .fold<double>(0, (sum, e) => sum + (e.values[Metric.minutes] ?? 0));
    if (health == null) {
      return CoachTip(
        general: true,
        text: minutes > 0
            ? 'Hôm nay cậu đã vận động ${formatDecimal(minutes)} phút. Đi bộ thêm 20 phút sau bữa tối nhé.'
            : 'Hôm nay cậu chưa vận động. Đi bộ 20 phút sau bữa tối là khởi đầu nhẹ nhàng.',
        why:
            'dành cho người không có bệnh lý nền. Thêm Thông tin sức khỏe để AI gợi ý sát với cậu hơn.',
      );
    }
    final knees = health.has(MedicalCondition.jointPain);
    final bp = health.has(MedicalCondition.hypertension);
    final move = knees ? 'đi bộ chậm 20 phút' : 'đi bộ nhanh 20 phút';
    final text = ateSalty && bp
        ? 'Tối nay cậu đã ăn phở. Uống thêm nước lọc và $move sau bữa tối.'
        : bp
            ? 'Nếu tối nay ăn món có nước dùng, chừa lại nửa phần nước. Sau bữa tối, $move.'
            : 'Sau bữa tối, $move để cân bằng năng lượng hôm nay.';
    final reasons = [
      if (knees) 'đi bộ chậm không dồn lực lên khớp gối',
      if (bp) 'bớt nước dùng giúp giữ natri trong ngưỡng an toàn cho huyết áp',
      if (!knees && !bp)
        'vận động vừa sức phù hợp với mục tiêu ${health.goal.label.toLowerCase()}',
    ];
    final why =
        reasons.map((r) => '${r[0].toUpperCase()}${r.substring(1)}.').join(' ');
    return CoachTip(text: text, why: why);
  }

  @override
  Future<List<HabitInsight>> habits(List<DayTotals> days,
      {HealthInfo? health}) async {
    final logged = days.where((d) => d.logged).toList();
    int avg(Iterable<DayTotals> xs) => xs.isEmpty
        ? 0
        : xs.fold<int>(0, (s, d) => s + d.intakeKcal) ~/ xs.length;
    bool weekend(DayTotals d) =>
        d.date.weekday == DateTime.saturday ||
        d.date.weekday == DateTime.sunday;
    final gap =
        avg(logged.where(weekend)) - avg(logged.where((d) => !weekend(d)));
    return [
      if (gap > 100)
        HabitInsight(InsightKind.weekend, 'Cuối tuần ăn nhiều hơn',
            'Thứ 7 và Chủ nhật cậu nạp nhiều hơn ngày thường khoảng ${formatInt((gap / 10).round() * 10)} kcal.'),
      if (health?.has(MedicalCondition.hypertension) ?? false)
        const HabitInsight(InsightKind.sodium, 'Natri hay vượt vào bữa tối',
            'Chủ yếu từ nước dùng và nước chấm. Với Huyết áp cao, bữa tối là chỗ dễ giảm nhất.'),
      HabitInsight(
          InsightKind.streak,
          'Ghi đều ${logged.length}/${days.length} ngày',
          'Hoạt động cậu ghi nhiều nhất là Đạp xe tĩnh, trung bình 8 km một lần.'),
    ];
  }
}
