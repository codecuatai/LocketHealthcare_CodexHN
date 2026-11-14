import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/models/health_info.dart';
import '../../core/theme/vita_theme.dart';
import '../../providers/health_controller.dart';
import '../../widgets/vita/ui.dart';
import '../../widgets/vita/vita_buttons.dart';

/// Thông tin sức khỏe: phần riêng tư chỉ chủ Tài khoản và AI dùng.
class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const HealthInfoScreen());

  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen> {
  late final HealthInfo? _start = context.read<HealthController>().info;
  late Sex _sex = _start?.sex ?? Sex.male;
  late HealthGoal _goal = _start?.goal ?? HealthGoal.maintain;
  late final _year = TextEditingController(text: _start?.birthYear.toString());
  late final _height = TextEditingController(text: _num(_start?.heightCm));
  late final _weight = TextEditingController(text: _num(_start?.weightKg));
  late bool _custom = _start?.customTargetKcal != null;
  late final _target =
      TextEditingController(text: _start?.customTargetKcal?.toString() ?? '');
  late final Map<MedicalCondition, ConditionSeverity> _conds = {
    ...?_start?.conditions
  };
  String? _error;
  bool _saving = false;

  static String _num(double? v) => v == null ? '' : formatDecimal(v);
  static double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  @override
  void initState() {
    super.initState();
    for (final c in [_year, _height, _weight, _target]) {
      c.addListener(() => setState(() => _error = null));
    }
  }

  @override
  void dispose() {
    for (final c in [_year, _height, _weight, _target]) {
      c.dispose();
    }
    super.dispose();
  }

  int? get _suggested {
    final y = int.tryParse(_year.text.trim());
    final h = _parse(_height), w = _parse(_weight);
    if (y == null || h == null || w == null) return null;
    return suggestTargetKcal(
        sex: _sex,
        age: DateTime.now().year - y,
        heightCm: h,
        weightKg: w,
        goal: _goal);
  }

  String? _validate() {
    final now = DateTime.now().year;
    final y = int.tryParse(_year.text.trim());
    final h = _parse(_height), w = _parse(_weight);
    if (y == null || h == null || w == null) {
      return 'Cần năm sinh, chiều cao và cân nặng để AI tính cho đúng.';
    }
    if (y < now - 100 || y > now - 10) return 'Năm sinh chưa hợp lý.';
    if (h < 100 || h > 230) return 'Chiều cao nên trong khoảng 100 đến 230 cm.';
    if (w < 30 || w > 250) return 'Cân nặng nên trong khoảng 30 đến 250 kg.';
    if (_custom) {
      final t = int.tryParse(_target.text.trim());
      if (t == null || t < 1000 || t > 5000) {
        return 'Mục tiêu calo nên trong khoảng 1.000 đến 5.000 kcal.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() => _saving = true);
    final info = HealthInfo(
      sex: _sex,
      birthYear: int.parse(_year.text.trim()),
      heightCm: _parse(_height)!,
      weightKg: _parse(_weight)!,
      goal: _goal,
      conditions: Map.unmodifiable(_conds),
      customTargetKcal: _custom ? int.parse(_target.text.trim()) : null,
    );
    await context.read<HealthController>().save(info);
    if (!mounted) return;
    showVitaToast(context, 'Đã lưu Thông tin sức khỏe');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final suggested = _suggested;
    return Scaffold(
      backgroundColor: VitaColors.bg,
      body: SafeArea(
        child: Column(children: [
          const VitaTopBar(
              leading: BackButtonRound(), title: Text('Thông tin sức khỏe')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: VitaColors.cyan.withValues(alpha: .07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: VitaColors.cyan.withValues(alpha: .25))),
                  child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 19, color: VitaColors.cyan),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                    text: 'Chỉ cậu và AI dùng thông tin này. ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: VitaColors.onSurface)),
                                TextSpan(
                                    text:
                                        'Bạn bè không bao giờ thấy, kể cả khi cậu chia sẻ Khoảnh khắc.'),
                              ]),
                              style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: VitaColors.onSurfaceVariant)),
                        ),
                      ]),
                ),
                _Group(
                    'Giới tính',
                    PillSegmented<Sex>(
                      segments: [
                        for (final s in Sex.values) Segment(s, s.label)
                      ],
                      value: _sex,
                      onChanged: (s) => setState(() => _sex = s),
                    )),
                _Group(
                    'Cơ thể',
                    Row(children: [
                      Expanded(
                          child: _NumberBox(
                              key: const ValueKey('health-year'),
                              label: 'Năm sinh',
                              controller: _year,
                              hint: '1999')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _NumberBox(
                              key: const ValueKey('health-height'),
                              label: 'Chiều cao',
                              unit: 'cm',
                              controller: _height,
                              hint: '170',
                              decimal: true)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _NumberBox(
                              key: const ValueKey('health-weight'),
                              label: 'Cân nặng',
                              unit: 'kg',
                              controller: _weight,
                              hint: '65',
                              decimal: true)),
                    ])),
                _Group(
                    'Mục tiêu',
                    PillSegmented<HealthGoal>(
                      segments: [
                        for (final g in HealthGoal.values) Segment(g, g.label)
                      ],
                      value: _goal,
                      onChanged: (g) => setState(() => _goal = g),
                    )),
                _Group(
                  'Mục tiêu calo mỗi ngày',
                  VitaCard(
                    radius: 20,
                    padding: const EdgeInsets.all(14),
                    color: VitaColors.surface,
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  _custom
                                      ? 'Cậu tự đặt'
                                      : suggested == null
                                          ? 'Điền đủ thông tin cơ thể để tính'
                                          : 'Tính từ cơ thể và mục tiêu của cậu',
                                  style: VitaText.caption),
                              if (!_custom)
                                Text.rich(TextSpan(children: [
                                  TextSpan(
                                      text: suggested == null
                                          ? '—'
                                          : formatInt(suggested),
                                      style: VitaText.metric.copyWith(
                                          fontSize: 26,
                                          color: VitaColors.onSurface)),
                                  const TextSpan(
                                      text: ' kcal',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: VitaColors.onSurfaceVariant)),
                                ])),
                            ]),
                      ),
                      if (_custom)
                        SizedBox(
                          width: 104,
                          child: _NumberBox(
                              key: const ValueKey('health-target'),
                              label: 'kcal',
                              controller: _target,
                              hint: '1850'),
                        ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _custom = !_custom;
                          if (_custom && _target.text.isEmpty) {
                            _target.text = '${suggested ?? 2000}';
                          }
                        }),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: VitaColors.onSurface,
                            side: const BorderSide(
                                color: VitaColors.surfaceHighest),
                            shape: const StadiumBorder()),
                        child: Text(_custom ? 'Tự tính' : 'Tự đặt'),
                      ),
                    ]),
                  ),
                ),
                _Group(
                  'Bệnh lý nền',
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final c in MedicalCondition.values)
                            _CondChip(
                              label: c.label,
                              on: _conds.containsKey(c),
                              onTap: () => setState(() => _conds.containsKey(c)
                                  ? _conds.remove(c)
                                  : _conds[c] = ConditionSeverity.mild),
                            ),
                        ]),
                        const SizedBox(height: 10),
                        if (_conds.isEmpty)
                          const Text(
                              'Không chọn nghĩa là cậu không có bệnh lý nền.',
                              style: VitaText.caption)
                        else
                          for (final c in _conds.keys)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: VitaCard(
                                radius: 18,
                                color: VitaColors.surface,
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(c.label,
                                          style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                              color: VitaColors.onSurface)),
                                      const SizedBox(height: 10),
                                      PillSegmented<ConditionSeverity>(
                                        height: 34,
                                        segments: [
                                          for (final s
                                              in ConditionSeverity.values)
                                            Segment(s, s.label)
                                        ],
                                        value: _conds[c],
                                        onChanged: (s) =>
                                            setState(() => _conds[c] = s),
                                      ),
                                    ]),
                              ),
                            ),
                      ]),
                ),
                const SizedBox(height: 18),
                const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: VitaColors.muted),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            'VitaSnap không thay thế bác sĩ. Gợi ý của AI chỉ để tham khảo. Nếu bác sĩ đã dặn kiêng hay hạn chế điều gì, hãy làm theo bác sĩ.',
                            style: VitaText.caption),
                      ),
                    ]),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: VitaColors.lineSoft))),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_error != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(_error!,
                      style: const TextStyle(
                          fontSize: 13, color: VitaColors.error)),
                ),
                const SizedBox(height: 8),
              ],
              VitaPrimaryButton(
                  label: 'Lưu thông tin',
                  showArrow: false,
                  loading: _saving,
                  onPressed: _save),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.label, this.child);
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CapsLabel(label),
          const SizedBox(height: 10),
          child,
        ]),
      );
}

class _NumberBox extends StatelessWidget {
  const _NumberBox({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.unit,
    this.decimal = false,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? unit;
  final bool decimal;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
        decoration: BoxDecoration(
            color: VitaColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: VitaColors.lineSoft)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: VitaText.label),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: decimal),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
                  LengthLimitingTextInputFormatter(5),
                ],
                style: VitaText.metric
                    .copyWith(fontSize: 20, color: VitaColors.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  hintText: hint,
                  hintStyle: const TextStyle(color: VitaColors.placeholder),
                  semanticCounterText: label,
                ),
              ),
            ),
            if (unit != null)
              Text(unit!,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VitaColors.muted)),
          ]),
        ]),
      );
}

class _CondChip extends StatelessWidget {
  const _CondChip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: on,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
                color: on ? VitaColors.volt : VitaColors.surface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                    color: on ? VitaColors.volt : VitaColors.lineSoft)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (on) ...[
                const Icon(Icons.check_rounded,
                    size: 16, color: VitaColors.onVolt),
                const SizedBox(width: 4),
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: on
                          ? VitaColors.onVolt
                          : VitaColors.onSurfaceVariant)),
            ]),
          ),
        ),
      );
}
