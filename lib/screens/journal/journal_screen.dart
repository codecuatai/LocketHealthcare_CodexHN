import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/models/activity.dart';
import '../../core/models/analysis.dart';
import '../../core/models/entry.dart';
import '../../core/models/health_info.dart';
import '../../core/theme/vita_theme.dart';
import '../../data/app_services.dart';
import '../../data/journal/journal_repository.dart';
import '../../providers/health_controller.dart';
import '../../providers/journal_controller.dart';
import '../../providers/session_scope.dart';
import '../../widgets/vita/ui.dart';
import '../capture/activity_result_screen.dart' show activityIcon;
import '../personal/health_info_screen.dart';
import '../personal/personal_screen.dart';

enum _Mode { day, month }

/// Nhật ký: theo dõi calo nạp và tiêu hao theo ngày và theo tháng.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  _Mode _mode = _Mode.day;

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalController>();
    final today = journal.today;
    return SafeArea(
      bottom: false,
      child: Column(children: [
        VitaTopBar(
          leading: MeButton(
              person: context.read<Me>().person,
              onTap: () => Navigator.of(context).push(PersonalScreen.route())),
          title: const Text('Nhật ký'),
          trailing: StreakChip(journal.streak),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
          child: Row(children: [
            Expanded(
              child: Text(
                  _mode == _Mode.day
                      ? 'Hôm nay, ${today.day}/${today.month}'
                      : '30 ngày qua',
                  style: const TextStyle(
                      fontFamily: VitaFonts.display,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      color: VitaColors.onSurface)),
            ),
            SizedBox(
              width: 160,
              child: PillSegmented<_Mode>(
                height: 32,
                segments: const [
                  Segment(_Mode.day, 'Ngày'),
                  Segment(_Mode.month, 'Tháng'),
                ],
                value: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
            ),
          ]),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: reduceMotion(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            child: _mode == _Mode.day
                ? const _DayView(key: ValueKey('day'))
                : const _MonthView(key: ValueKey('month')),
          ),
        ),
      ]),
    );
  }
}

/// Hàng ô thống kê cao bằng nhau.
class _EqualRow extends StatelessWidget {
  const _EqualRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
}

EdgeInsets _listPadding(BuildContext context) =>
    EdgeInsets.fromLTRB(16, 0, 16, 90 + MediaQuery.paddingOf(context).bottom);

class _DayView extends StatelessWidget {
  const _DayView({super.key});

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalController>();
    final health = context.watch<HealthController>().info;
    final entries = journal.todayEntries;
    final bodyKg = health?.weightKg;
    var intake = 0, burn = 0, meals = 0, acts = 0;
    var p = 0, c = 0, f = 0;
    double minutes = 0;
    for (final e in entries) {
      switch (e) {
        case MealEntry():
          meals++;
          intake += e.kcal;
          p += e.proteinG;
          c += e.carbsG;
          f += e.fatG;
        case ActivityEntry():
          acts++;
          burn += e.kcal(bodyKg) ?? 0;
          minutes += e.values[Metric.minutes] ?? 0;
      }
    }
    final target = health?.targetKcal;
    return ListView(padding: _listPadding(context), children: [
      if (target != null)
        _RingCard(
            target: target,
            intake: intake,
            burn: burn,
            meals: meals,
            acts: acts,
            macros: (p, c, f))
      else ...[
        _EqualRow(children: [
          Expanded(
              child: _Stat('Đã nạp', formatInt(intake), 'kcal · $meals bữa')),
          const SizedBox(width: 8),
          Expanded(
            child: _Stat('Đã tiêu', null, '$acts hoạt động', action: (
              'Thêm cân nặng để tính',
              () {
                Navigator.of(context).push(HealthInfoScreen.route());
              }
            )),
          ),
          const SizedBox(width: 8),
          Expanded(child: _Stat('Vận động', formatDecimal(minutes), 'phút')),
        ]),
        const SizedBox(height: 12),
        VitaCard(child: _MacroBars(p: p, c: c, f: f, target: null)),
        const SizedBox(height: 12),
        HealthNudge(
            text: 'Để đặt mục tiêu calo và tính calo tiêu hao khi vận động',
            onTap: () => Navigator.of(context).push(HealthInfoScreen.route())),
      ],
      const SizedBox(height: 14),
      _CoachCard(entries: entries, health: health, version: journal.version),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(
                child: Text('Hôm nay',
                    style: TextStyle(
                        fontFamily: VitaFonts.display,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: VitaColors.onSurface)),
              ),
              Text('${entries.length} bản ghi', style: VitaText.caption),
            ]),
      ),
      const SizedBox(height: 10),
      if (entries.isEmpty)
        const VitaCard(
          child: Text(
              'Chưa có Bản ghi nào hôm nay. Chụp bữa ăn hoặc lúc vận động để bắt đầu.',
              style: VitaText.bodySmall),
        )
      else
        VitaCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(children: [
            for (final (i, e) in entries.indexed) ...[
              if (i > 0)
                const Divider(
                    height: 1, thickness: 1, color: VitaColors.lineSoft),
              _EntryRow(
                  entry: e, bodyKg: bodyKg, fresh: e.id == journal.freshId),
            ],
          ]),
        ),
    ]);
  }
}

class _RingCard extends StatelessWidget {
  const _RingCard({
    required this.target,
    required this.intake,
    required this.burn,
    required this.meals,
    required this.acts,
    required this.macros,
  });

  final int target, intake, burn, meals, acts;
  final (int, int, int) macros;

  @override
  Widget build(BuildContext context) {
    final left = target - intake + burn;
    final over = left < 0;
    final fill = (intake / max(1, target + burn)).clamp(0.0, 1.0);
    return VitaCard(
      child: Column(children: [
        Row(children: [
          SizedBox.square(
            dimension: 148,
            child: Stack(alignment: Alignment.center, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fill),
                duration: reduceMotion(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => CustomPaint(
                    size: const Size.square(148),
                    painter: _RingPainter(v, over)),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(over ? 'VƯỢT' : 'CÒN LẠI', style: VitaText.label),
                Text(formatInt(left.abs()),
                    style: VitaText.metric.copyWith(
                        fontSize: 32,
                        color: over
                            ? VitaColors.coralSoft
                            : VitaColors.onSurface)),
                const Text('kcal',
                    style: TextStyle(
                        fontSize: 11.5, color: VitaColors.onSurfaceVariant)),
              ]),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Kv('Mục tiêu', target, VitaColors.volt),
              const SizedBox(height: 10),
              _Kv('Đã nạp · $meals bữa', intake, VitaColors.cyan),
              const SizedBox(height: 10),
              _Kv('Đã tiêu · $acts hoạt động', burn, VitaColors.coral),
            ]),
          ),
        ]),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1, thickness: 1, color: VitaColors.lineSoft),
        ),
        _MacroBars(p: macros.$1, c: macros.$2, f: macros.$3, target: target),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fill, this.over);
  final double fill;
  final bool over;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final ring = rect.deflate(stroke / 2);
    canvas.drawArc(
        ring,
        0,
        2 * pi,
        false,
        Paint()
          ..color = VitaColors.surfaceHighest
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    if (fill <= 0) return;
    canvas.drawArc(
        ring,
        -pi / 2,
        2 * pi * fill,
        false,
        Paint()
          ..color = over ? VitaColors.coral : VitaColors.volt
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fill != fill || old.over != over;
}

class _Kv extends StatelessWidget {
  const _Kv(this.label, this.kcal, this.color);
  final String label;
  final int kcal;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VitaText.label.copyWith(fontSize: 9.5)),
          Text.rich(TextSpan(children: [
            TextSpan(
                text: formatInt(kcal),
                style: VitaText.metric
                    .copyWith(fontSize: 21, color: VitaColors.onSurface)),
            const TextSpan(
                text: ' kcal',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: VitaColors.onSurfaceVariant)),
          ])),
        ]),
      );
}

class _MacroBars extends StatelessWidget {
  const _MacroBars(
      {required this.p,
      required this.c,
      required this.f,
      required this.target});
  final int p, c, f;
  final int? target;

  @override
  Widget build(BuildContext context) {
    final t = target;
    final rows = [
      ('Đạm', p, t == null ? null : t * .25 / 4, VitaColors.coralSoft),
      ('Tinh bột', c, t == null ? null : t * .5 / 4, VitaColors.volt),
      ('Chất béo', f, t == null ? null : t * .25 / 9, VitaColors.cyan),
    ];
    return Column(children: [
      for (final (i, (label, grams, goal, color)) in rows.indexed) ...[
        if (i > 0) const SizedBox(height: 10),
        Row(children: [
          SizedBox(
              width: 70,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12.5, color: VitaColors.onSurfaceVariant))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (grams / (goal ?? 150)).clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                backgroundColor: VitaColors.surfaceHighest,
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: '$grams',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: VitaColors.onSurface)),
                TextSpan(
                    text: goal == null ? ' g' : ' / ${formatInt(goal)} g',
                    style: const TextStyle(color: VitaColors.muted)),
              ]),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12.5, fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
        ]),
      ],
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.unit, {this.action});
  final String label;
  final String? value;
  final String unit;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) => VitaCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(12, 14, 10, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: VitaText.label),
          const SizedBox(height: 2),
          if (value != null)
            Text(value!,
                style: VitaText.metric
                    .copyWith(fontSize: 24, color: VitaColors.onSurface))
          else if (action != null)
            GestureDetector(
              onTap: action!.$2,
              child: Text(action!.$1,
                  style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: VitaColors.volt)),
            ),
          Text(unit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11.5, color: VitaColors.onSurfaceVariant)),
        ]),
      );
}

class _CoachCard extends StatelessWidget {
  const _CoachCard(
      {required this.entries, required this.health, required this.version});
  final List<Entry> entries;
  final HealthInfo? health;
  final int version;

  @override
  Widget build(BuildContext context) {
    final coach = context.read<AppServices>().coach;
    return FutureBuilder<CoachTip>(
      key: ValueKey((version, health)),
      future: coach.today(entries, health: health),
      builder: (_, snap) {
        final tip = snap.data;
        return VitaCard(
          borderColor: VitaColors.volt.withValues(alpha: .3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VitaColors.volt.withValues(alpha: .13),
              VitaColors.surfaceLow,
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 15, color: VitaColors.volt),
              SizedBox(width: 6),
              CapsLabel('AI gợi ý hôm nay', color: VitaColors.volt),
            ]),
            const SizedBox(height: 10),
            if (tip == null)
              const LinearProgressIndicator(minHeight: 2)
            else ...[
              Text(tip.text,
                  style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: VitaColors.onSurface)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          size: 18, color: VitaColors.volt),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(
                                text: tip.general
                                    ? 'Gợi ý chung, '
                                    : 'Vì sao an toàn: ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: VitaColors.onSurface)),
                            TextSpan(text: tip.why),
                          ]),
                          style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: VitaColors.onSurfaceVariant),
                        ),
                      ),
                    ]),
              ),
            ],
          ]),
        );
      },
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow(
      {required this.entry, required this.bodyKg, required this.fresh});
  final Entry entry;
  final double? bodyKg;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final (title, sub, kcal, isIn) = switch (e) {
      MealEntry() => (
          e.dishName,
          null,
          e.kcal,
          true,
        ),
      ActivityEntry() => (e.type.label, e.summary, e.kcal(bodyKg), false),
    };
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        SizedBox(
          width: 44,
          child: Text(clockTime(e.at),
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: VitaColors.muted,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox.square(
            dimension: 50,
            child: e.photo != null
                ? Image(image: e.photo!.image, fit: BoxFit.cover)
                : ColoredBox(
                    color: VitaColors.surfaceHigh,
                    child: Icon(
                        e is ActivityEntry
                            ? activityIcon(e.type)
                            : Icons.restaurant_rounded,
                        color: VitaColors.coralSoft)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: VitaColors.onSurface)),
            Row(children: [
              if (sub == null) ...[
                Icon(
                    e.shared
                        ? Icons.group_outlined
                        : Icons.lock_outline_rounded,
                    size: 12,
                    color: VitaColors.muted),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(sub ?? (e.shared ? 'Đã chia sẻ' : 'Riêng tư'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VitaText.caption.copyWith(fontSize: 12)),
              ),
            ]),
          ]),
        ),
        if (kcal != null)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${isIn ? '+' : '−'}${formatInt(kcal)}',
                style: TextStyle(
                    fontFamily: VitaFonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isIn ? VitaColors.onSurface : VitaColors.coralSoft)),
            Text(isIn ? 'kcal nạp' : 'kcal tiêu',
                style: VitaText.caption.copyWith(fontSize: 10.5)),
          ]),
      ]),
    );
    if (!fresh || reduceMotion(context)) return row;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 1600),
      builder: (_, t, child) => DecoratedBox(
          decoration: BoxDecoration(
              color: VitaColors.volt.withValues(alpha: .16 * t),
              borderRadius: BorderRadius.circular(14)),
          child: child),
      child: row,
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({super.key});

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalController>();
    final health = context.watch<HealthController>().info;
    final coach = context.read<AppServices>().coach;
    return FutureBuilder<(List<DayTotals>, List<HabitInsight>)>(
      key: ValueKey((journal.version, health)),
      future: () async {
        final days = await journal.lastDays(30, bodyKg: health?.weightKg);
        return (days, await coach.habits(days, health: health));
      }(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (days, habits) = snap.data!;
        final logged = days.where((d) => d.logged).toList();
        final avgIn = logged.isEmpty
            ? 0
            : logged.fold<int>(0, (s, d) => s + d.intakeKcal) ~/ logged.length;
        final avgOut = health == null || logged.isEmpty
            ? null
            : logged.fold<int>(0, (s, d) => s + (d.burnKcal ?? 0)) ~/
                logged.length;
        return ListView(padding: _listPadding(context), children: [
          _EqualRow(children: [
            Expanded(child: _Stat('TB nạp', formatInt(avgIn), 'kcal/ngày')),
            const SizedBox(width: 8),
            Expanded(
              child: avgOut != null
                  ? _Stat('TB tiêu', formatInt(avgOut), 'kcal/ngày')
                  : _Stat(
                      'Đã ghi', '${logged.length}', 'trên ${days.length} ngày'),
            ),
            const SizedBox(width: 8),
            Expanded(child: _Stat('Chuỗi', '${journal.streak}', 'ngày')),
          ]),
          const SizedBox(height: 12),
          VitaCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Semantics(
                label:
                    'Biểu đồ calo nạp${health == null ? '' : ' và tiêu'} 30 ngày, trung bình nạp ${formatInt(avgIn)} kcal mỗi ngày',
                excludeSemantics: true,
                child: AspectRatio(
                  aspectRatio: 342 / 210,
                  child: CustomPaint(
                    painter: _MonthChart(days,
                        target: health?.targetKcal, showBurn: health != null),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 14, runSpacing: 6, children: [
                const _Legend('Nạp', Color(0x8C7DF4FF)),
                if (health != null) const _Legend('Tiêu', Color(0xB3FF5625)),
                if (health != null) const _Legend('Mục tiêu', null),
                const _Legend('Không ghi', VitaColors.surfaceHighest),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('AI nhận ra thói quen',
              style: TextStyle(
                  fontFamily: VitaFonts.display,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: VitaColors.onSurface)),
          const SizedBox(height: 10),
          VitaCard(
            child: Column(children: [
              for (final (i, h) in habits.indexed) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                        height: 1, thickness: 1, color: VitaColors.lineSoft),
                  ),
                _Insight(h),
              ],
            ]),
          ),
        ]);
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;

  /// null: đường gạch (mục tiêu).
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        color == null
            ? Container(
                width: 14, height: 2, color: VitaColors.onSurfaceVariant)
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: VitaColors.onSurfaceVariant)),
      ]);
}

class _Insight extends StatelessWidget {
  const _Insight(this.h);
  final HabitInsight h;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (h.kind) {
      InsightKind.weekend => (
          Icons.calendar_month_rounded,
          const Color(0xFFFFC24B)
        ),
      InsightKind.sodium => (Icons.water_drop_outlined, VitaColors.coralSoft),
      InsightKind.streak => (Icons.trending_up_rounded, VitaColors.volt),
    };
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: VitaColors.surfaceHigh,
            borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, size: 19, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(h.title,
              style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: VitaColors.onSurface)),
          const SizedBox(height: 2),
          Text(h.detail, style: VitaText.bodySmall.copyWith(fontSize: 13)),
        ]),
      ),
    ]);
  }
}

/// Cột calo 30 ngày: nạp hướng lên, tiêu hướng xuống, đường mục tiêu gạch.
class _MonthChart extends CustomPainter {
  _MonthChart(this.days, {required this.target, required this.showBurn});
  final List<DayTotals> days;
  final int? target;
  final bool showBurn;

  static const _maxIn = 2800.0, _maxOut = 450.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const labelH = 16.0;
    final base = (h - labelH) * .7;
    final up = base - 10;
    final down = h - labelH - base - 6;
    final n = days.length;
    final bw = max(3.0, w / n * .62);
    final gap = n > 1 ? (w - n * bw) / (n - 1) : 0.0;

    canvas.drawLine(Offset(0, base + 1.5), Offset(w, base + 1.5),
        Paint()..color = VitaColors.lineSoft);

    for (var i = 0; i < n; i++) {
      final d = days[i];
      final x = i * (bw + gap);
      if (!d.logged) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, base - 3, bw, 3), const Radius.circular(1.5)),
            Paint()..color = VitaColors.surfaceHighest);
        continue;
      }
      final hi = (d.intakeKcal / _maxIn).clamp(0.0, 1.0) * up;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, base - hi, bw, hi), const Radius.circular(3)),
          Paint()
            ..color = i == n - 1 ? VitaColors.volt : const Color(0x8C7DF4FF));
      final out = d.burnKcal ?? 0;
      if (showBurn && out > 0) {
        final ho = (out / _maxOut).clamp(0.0, 1.0) * down;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, base + 3, bw, ho), const Radius.circular(3)),
            Paint()..color = const Color(0xB3FF5625));
      }
    }

    if (target != null) {
      final y = base - (target! / _maxIn).clamp(0.0, 1.0) * up;
      final dash = Paint()
        ..color = VitaColors.onSurfaceVariant
        ..strokeWidth = 1.5;
      for (var x = 0.0; x < w; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(min(w, x + 4), y), dash);
      }
      _text(canvas, 'Mục tiêu ${formatInt(target!)}', Offset(0, y - 15),
          VitaColors.onSurfaceVariant);
    }

    for (final i in [0, 7, 14, 21, n - 1]) {
      if (i < 0 || i >= n) continue;
      final d = days[i].date;
      final x = i * (bw + gap);
      _text(canvas, '${d.day}/${d.month}',
          Offset(min(w - 26, x), h - labelH + 3), VitaColors.muted);
    }
  }

  void _text(Canvas canvas, String s, Offset at, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              fontFamily: VitaFonts.body,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_MonthChart old) =>
      old.days != days || old.target != target || old.showBurn != showBurn;
}
