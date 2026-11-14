import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/models/activity.dart';
import '../../core/models/analysis.dart';
import '../../core/models/entry.dart';
import '../../core/models/health_info.dart';
import '../../core/models/photo.dart';
import '../../core/models/social.dart';
import '../../core/theme/vita_theme.dart';
import '../../providers/health_controller.dart';
import '../../providers/journal_controller.dart';
import '../../widgets/vita/ui.dart';
import '../../widgets/vita/vita_buttons.dart';
import 'advice_card.dart';
import 'result_layout.dart';
import 'share_panel.dart';

/// Kết quả Hoạt động: AI nhận ra loại, người dùng khai số đếm được.
///
/// Số liệu điền sẵn theo lần gần nhất ghi cùng loại; lần đầu thì để trống và
/// nút ghi khoá tới khi đủ. Thời gian không bắt buộc (trừ môn không đếm được).
class ActivityResultScreen extends StatefulWidget {
  const ActivityResultScreen({super.key, required this.photo, this.aiType});
  final Photo photo;

  /// Loại AI nhận ra; null khi AI chưa chắc, người dùng tự chọn.
  final ActivityType? aiType;

  static Route<void> route(Photo photo, ActivityType? type) =>
      MaterialPageRoute(
          builder: (_) => ActivityResultScreen(photo: photo, aiType: type));

  @override
  State<ActivityResultScreen> createState() => _ActivityResultScreenState();
}

class _ActivityResultScreenState extends State<ActivityResultScreen> {
  ActivityType? _type;
  bool _fromAi = false;
  bool _prefilled = false;
  bool _showTime = false;
  bool _saving = false;
  Map<Metric, double> _v = {};
  final _ctl = <Metric, TextEditingController>{};
  final _caption = TextEditingController();
  ShareSettings _share = const ShareSettings();
  final _at = DateTime.now();

  @override
  void initState() {
    super.initState();
    final t = widget.aiType;
    if (t != null) {
      _setType(t, fromAi: true);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickType());
    }
  }

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    _caption.dispose();
    super.dispose();
  }

  List<Metric> get _fields => [
        ...?_type?.metrics,
        if (_type != null && _type!.timeIsOptional && _showTime) Metric.minutes,
      ];

  Future<void> _setType(ActivityType t, {bool fromAi = false}) async {
    final last = await context.read<JournalController>().lastValues(t);
    if (!mounted) return;
    setState(() {
      _type = t;
      _fromAi = fromAi;
      _v = {...?last};
      _prefilled = last != null;
      _showTime = (_v[Metric.minutes] ?? 0) > 0;
      for (final m in Metric.values) {
        final value = _v[m] ?? 0;
        (_ctl[m] ??= TextEditingController()).text =
            value > 0 ? formatDecimal(value) : '';
      }
    });
  }

  Future<void> _pickType() async {
    final t = await showAppSheet<ActivityType>(context,
        builder: (_) => ActivityTypeSheet(selected: _type));
    if (t != null && mounted) await _setType(t);
  }

  void _typed(Metric m, String text) {
    final v = double.tryParse(text.replaceAll(',', '.'));
    setState(() => _v[m] = v ?? 0);
  }

  void _bump(Metric m, int dir) {
    HapticFeedback.selectionClick();
    final next = ((_v[m] ?? 0) + dir * m.step).clamp(0, 100000).toDouble();
    final rounded = (next * 10).round() / 10;
    setState(() => _v[m] = rounded);
    _ctl[m]!.text = rounded > 0 ? formatDecimal(rounded) : '';
  }

  Future<void> _save() async {
    final t = _type!;
    setState(() => _saving = true);
    final values = {
      for (final m in _fields)
        if ((_v[m] ?? 0) > 0) m: _v[m]!,
    };
    final entry = ActivityEntry(
      id: 'act-${_at.microsecondsSinceEpoch}',
      at: _at,
      photo: widget.photo,
      shared: _share.share,
      type: t,
      values: values,
    );
    await saveEntry(
      context,
      entry: entry,
      kind: MomentKind.activity,
      momentLabel: '${t.label} · ${t.summary({
            t.metrics.first: values[t.metrics.first]!
          })}',
      kcal: entry.kcal(context.read<HealthController>().bodyKg),
      share: _share,
      caption: _caption.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthController>().info;
    final t = _type;
    final complete = t != null && t.isComplete(_v);
    final kcal =
        complete && health != null ? t.kcal(_v, health.weightKg).round() : null;
    return ResultLayout(
      title: 'Hoạt động',
      body: [
        ResultPhoto(
            photo: widget.photo,
            label: widget.aiType != null
                ? 'AI nhận ra hoạt động'
                : 'AI chưa chắc cậu tập gì',
            height: 200),
        _TypeButton(type: t, fromAi: _fromAi, onTap: _pickType),
        if (t != null) ...[
          Row(children: [
            Icon(
                _prefilled ? Icons.history_rounded : Icons.info_outline_rounded,
                size: 15,
                color: VitaColors.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                  _prefilled
                      ? 'Điền sẵn theo lần cậu ghi ${t.label} gần nhất, sửa nếu khác'
                      : 'Lần đầu ghi ${t.label}, cậu điền số liệu giúp tớ nhé',
                  style: VitaText.caption),
            ),
          ]),
          for (final m in _fields)
            _StepperRow(
              metric: m,
              optional: m == Metric.minutes && t.timeIsOptional,
              missing: t.metrics.contains(m) && (_v[m] ?? 0) <= 0,
              controller: _ctl[m]!,
              onTyped: (s) => _typed(m, s),
              onBump: (d) => _bump(m, d),
            ),
          if (t.timeIsOptional && !_showTime)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showTime = true),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm thời gian (không bắt buộc)'),
                style: TextButton.styleFrom(
                    foregroundColor: VitaColors.volt,
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5)),
              ),
            ),
          if (kcal != null) _BurnCard(kcal),
          if (t.stressesKnees &&
              (health?.has(MedicalCondition.jointPain) ?? false))
            AdviceCard(
              verdict: FitVerdict.adjust,
              eyebrow: 'Lưu ý cho cậu',
              title: 'Dồn lực lên khớp gối',
              reasons: [
                FitReason('Đau khớp gối',
                    '${t.label} không hợp lắm với khớp gối của cậu. Đã tập rồi thì vẫn ghi bình thường. Lần sau thử Đạp xe tĩnh hoặc Bơi, nhẹ cho gối hơn.'),
              ],
            ),
          if (_share.share)
            SharePanel(
                settings: _share,
                caption: _caption,
                optionsOnly: true,
                onChanged: (s) => setState(() => _share = s)),
        ],
      ],
      dock: [
        if (t != null)
          SharePanel(
              settings: _share,
              caption: _caption,
              onChanged: (s) => setState(() => _share = s)),
        VitaPrimaryButton(
          label: t == null
              ? 'Chọn hoạt động để ghi'
              : complete
                  ? 'Ghi vào Nhật ký'
                  : 'Điền đủ số liệu để ghi',
          showArrow: false,
          loading: _saving,
          onPressed: complete && !_saving ? _save : null,
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton(
      {required this.type, required this.fromAi, required this.onTap});
  final ActivityType? type;
  final bool fromAi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: type == null
            ? 'Chọn hoạt động'
            : 'Loại hoạt động: ${type!.label}. Bấm để đổi',
        excludeSemantics: true,
        child: Material(
          color: VitaColors.surfaceLow,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: VitaColors.lineSoft)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: type == null
                          ? VitaColors.surfaceHigh
                          : VitaColors.volt,
                      borderRadius: BorderRadius.circular(15)),
                  child: Icon(
                      type == null ? Icons.add_rounded : activityIcon(type!),
                      color:
                          type == null ? VitaColors.muted : VitaColors.onVolt),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          if (fromAi) ...[
                            const Icon(Icons.auto_awesome_rounded,
                                size: 13, color: VitaColors.volt),
                            const SizedBox(width: 4),
                          ],
                          Text(
                              (type == null
                                      ? 'AI chưa chắc cậu tập gì'
                                      : fromAi
                                          ? 'AI nhận ra · bấm để đổi'
                                          : 'Cậu đã chọn')
                                  .toUpperCase(),
                              style: VitaText.label),
                        ]),
                        Text(type?.label ?? 'Chọn hoạt động',
                            style: type == null
                                ? const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: VitaColors.muted)
                                : const TextStyle(
                                    fontFamily: VitaFonts.display,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 21,
                                    color: VitaColors.onSurface)),
                      ]),
                ),
                const Icon(Icons.expand_more_rounded,
                    color: VitaColors.onSurfaceVariant),
              ]),
            ),
          ),
        ),
      );
}

IconData activityIcon(ActivityType t) => switch (t.category) {
      ActivityCategory.gym => Icons.fitness_center_rounded,
      ActivityCategory.cardio => Icons.directions_run_rounded,
      ActivityCategory.gentle => Icons.self_improvement_rounded,
    };

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.metric,
    required this.optional,
    required this.missing,
    required this.controller,
    required this.onTyped,
    required this.onBump,
  });

  final Metric metric;
  final bool optional;
  final bool missing;
  final TextEditingController controller;
  final ValueChanged<String> onTyped;
  final ValueChanged<int> onBump;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: VitaColors.surfaceLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  missing ? amber.withValues(alpha: .4) : VitaColors.lineSoft),
        ),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(metric.label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VitaColors.onSurface)),
              Text(optional ? 'Không bắt buộc · ${metric.unit}' : metric.unit,
                  style: VitaText.caption.copyWith(fontSize: 12)),
            ]),
          ),
          _StepButton(
              icon: Icons.remove_rounded,
              label: 'Giảm ${metric.label}',
              onTap: () => onBump(-1)),
          const SizedBox(width: 6),
          SizedBox(
            width: 66,
            height: 44,
            child: TextField(
              key: ValueKey('metric-${metric.name}'),
              controller: controller,
              onChanged: onTyped,
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                LengthLimitingTextInputFormatter(6),
              ],
              style: VitaText.metric
                  .copyWith(fontSize: 20, color: VitaColors.onSurface),
              decoration: InputDecoration(
                hintText: '—',
                hintStyle: const TextStyle(color: VitaColors.placeholder),
                filled: true,
                fillColor: VitaColors.bg,
                contentPadding: EdgeInsets.zero,
                semanticCounterText: metric.label,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: VitaColors.lineSoft)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: VitaColors.volt)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _StepButton(
              icon: Icons.add_rounded,
              label: 'Tăng ${metric.label}',
              onTap: () => onBump(1)),
        ]),
      );
}

class _StepButton extends StatelessWidget {
  const _StepButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: VitaColors.surfaceHighest,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
                dimension: 44,
                child: Icon(icon, size: 19, color: Colors.white)),
          ),
        ),
      );
}

class _BurnCard extends StatelessWidget {
  const _BurnCard(this.kcal);
  final int kcal;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: VitaColors.coral.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: VitaColors.coral.withValues(alpha: .3)),
        ),
        child: Row(children: [
          Expanded(
            child: Text('CALO TIÊU HAO\nƯỚC TÍNH',
                style: VitaText.label.copyWith(color: VitaColors.coralSoft)),
          ),
          Semantics(
            container: true,
            label: 'Tiêu hao khoảng $kcal kcal',
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: '≈ ${formatInt(kcal)}',
                    style: VitaText.metric
                        .copyWith(fontSize: 30, color: VitaColors.coralSoft)),
                const TextSpan(
                    text: ' kcal',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: VitaColors.coralSoft)),
              ]),
            ),
          ),
        ]),
      );
}

/// Chọn loại hoạt động, chia theo Gym · Cardio · Nhẹ nhàng.
class ActivityTypeSheet extends StatefulWidget {
  const ActivityTypeSheet({super.key, this.selected});
  final ActivityType? selected;

  @override
  State<ActivityTypeSheet> createState() => _ActivityTypeSheetState();
}

class _ActivityTypeSheetState extends State<ActivityTypeSheet> {
  late ActivityCategory _cat =
      widget.selected?.category ?? ActivityCategory.cardio;

  @override
  Widget build(BuildContext context) {
    final knees = context
            .read<HealthController>()
            .info
            ?.has(MedicalCondition.jointPain) ??
        false;
    final types = ActivityType.values.where((t) => t.category == _cat).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Cậu đã tập gì?', style: VitaText.sheetTitle),
        const SizedBox(height: 14),
        PillSegmented<ActivityCategory>(
          segments: [
            for (final c in ActivityCategory.values) Segment(c, c.label)
          ],
          value: _cat,
          onChanged: (c) => setState(() => _cat = c),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.55,
          children: [
            for (final t in types)
              Semantics(
                button: true,
                selected: t == widget.selected,
                label: t.label,
                excludeSemantics: true,
                child: Material(
                  color: VitaColors.bg,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                          color: t == widget.selected
                              ? VitaColors.volt
                              : VitaColors.lineSoft,
                          width: t == widget.selected ? 1.5 : 1)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pop(t),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: VitaColors.surfaceHigh,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(activityIcon(t),
                                  size: 17, color: VitaColors.volt),
                            ),
                            const Spacer(),
                            Text(t.label,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: VitaColors.onSurface)),
                            if (knees && t.stressesKnees)
                              const Text('Nặng cho khớp gối',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: amber))
                            else
                              Text(t.metrics.map((m) => m.unit).join(' × '),
                                  style: VitaText.caption
                                      .copyWith(fontSize: 11.5)),
                          ]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}
