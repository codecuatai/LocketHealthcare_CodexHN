import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/models/analysis.dart';
import '../../core/models/entry.dart';
import '../../core/models/photo.dart';
import '../../core/models/social.dart';
import '../../core/theme/vita_theme.dart';
import '../../data/app_services.dart';
import '../../providers/health_controller.dart';
import '../../widgets/vita/ui.dart';
import '../../widgets/vita/vita_buttons.dart';
import '../personal/health_info_screen.dart';
import 'activity_result_screen.dart';
import 'advice_card.dart';
import 'result_layout.dart';
import 'share_panel.dart';

/// Kết quả Bữa ăn: calo ước tính, khẩu phần, mức phù hợp, chia sẻ, ghi.
class MealResultScreen extends StatefulWidget {
  const MealResultScreen(
      {super.key, required this.photo, required this.analysis});
  final Photo photo;
  final FoodAnalysis analysis;

  static Route<void> route(Photo photo, FoodAnalysis analysis) =>
      MaterialPageRoute(
          builder: (_) => MealResultScreen(photo: photo, analysis: analysis));

  @override
  State<MealResultScreen> createState() => _MealResultScreenState();
}

class _MealResultScreenState extends State<MealResultScreen> {
  late FoodAnalysis _a = widget.analysis;
  late final _name = TextEditingController(text: _a.dishName);
  final _caption = TextEditingController();
  late bool _editing = !_a.confident;
  double _portion = 1;
  late ShareSettings _share = ShareSettings(share: _a.confident);
  bool _saving = false;
  final _at = DateTime.now();

  static const _portions = [
    Segment(.5, '½', 'Ít'),
    Segment(1.0, '1', 'Vừa'),
    Segment(1.5, '1½', 'Nhiều'),
    Segment(2.0, '2', 'Gấp đôi'),
  ];

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _caption.dispose();
    super.dispose();
  }

  int get _kcal => (_a.kcal * _portion).round();
  int _g(int grams) => (grams * _portion).round();
  String get _dish => _name.text.trim();

  Future<void> _addHealthInfo() async {
    await Navigator.of(context).push(HealthInfoScreen.route());
    if (!mounted) return;
    final health = context.read<HealthController>().info;
    if (health == null) return;
    final again = await context
        .read<AppServices>()
        .vision
        .analyzeFood(widget.photo, health: health);
    if (mounted) setState(() => _a = again);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await saveEntry(
      context,
      entry: MealEntry(
        id: 'meal-${_at.microsecondsSinceEpoch}',
        at: _at,
        photo: widget.photo,
        shared: _share.share,
        dishName: _dish,
        kcal: _kcal,
        proteinG: _g(_a.proteinG),
        carbsG: _g(_a.carbsG),
        fatG: _g(_a.fatG),
      ),
      kind: MomentKind.meal,
      momentLabel: _dish,
      kcal: _kcal,
      share: _share,
      caption: _caption.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final noHealth = context.watch<HealthController>().info == null;
    final canSave = _dish.isNotEmpty && !_saving;
    return ResultLayout(
      title: '${_a.mealLabel} · ${clockTime(_at)}',
      body: [
        ResultPhoto(
            photo: widget.photo,
            label:
                _a.confident ? 'AI nhận ra món này' : 'AI chưa chắc món này'),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: _editing
                  ? TextField(
                      key: const ValueKey('dish-name'),
                      controller: _name,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (_dish.isNotEmpty) setState(() => _editing = false);
                      },
                      style: VitaText.headline,
                      decoration: InputDecoration(
                        hintText: 'Tên món',
                        hintStyle: VitaText.headline
                            .copyWith(color: VitaColors.placeholder),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: VitaColors.line)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: VitaColors.volt)),
                      ),
                    )
                  : Text(_dish, style: VitaText.headline),
            ),
            const SizedBox(width: 10),
            _MiniButton(
              icon: _editing ? Icons.check_rounded : Icons.edit_outlined,
              label: _editing ? 'Xong' : 'Sửa tên món',
              onTap: () {
                if (_editing && _dish.isEmpty) return;
                setState(() => _editing = !_editing);
              },
            ),
          ]),
          const SizedBox(height: 2),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text('${_a.servingLabel} · ', style: VitaText.caption),
            GestureDetector(
              onTap: () => Navigator.of(context).pushReplacement(
                  ActivityResultScreen.route(widget.photo, null)),
              child: const Text('Không phải món ăn?',
                  style: TextStyle(
                      fontSize: 13,
                      color: VitaColors.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                      decorationColor: VitaColors.line)),
            ),
          ]),
        ]),
        VitaCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Semantics(
                  container: true,
                  label: 'Khoảng $_kcal kcal',
                  excludeSemantics: true,
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: '≈ ${formatInt(_kcal)}',
                          style: VitaText.metric.copyWith(
                              fontSize: 48, color: VitaColors.onSurface)),
                      const TextSpan(
                          text: ' kcal',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: VitaColors.onSurfaceVariant)),
                    ]),
                  ),
                ),
              ),
              const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('ƯỚC TÍNH', style: VitaText.label),
                    Text('Sửa khẩu phần\nnếu chưa đúng',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: VitaColors.onSurfaceVariant)),
                  ]),
            ]),
            const SizedBox(height: 14),
            PillSegmented<double>(
              segments: _portions,
              value: _portion,
              height: 38,
              onChanged: (v) => setState(() => _portion = v),
            ),
          ]),
        ),
        Row(children: [
          for (final (i, (label, grams, color)) in [
            ('Đạm', _a.proteinG, VitaColors.coralSoft),
            ('Tinh bột', _a.carbsG, VitaColors.volt),
            ('Chất béo', _a.fatG, VitaColors.cyan),
          ].indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _MacroTile(label, _g(grams), color)),
          ],
        ]),
        AdviceCard.fit(_a),
        if (noHealth)
          HealthNudge(
              text: 'Để AI biết món này có hợp với bệnh lý nền của cậu không',
              onTap: _addHealthInfo),
        if (_share.share)
          SharePanel(
              settings: _share,
              caption: _caption,
              optionsOnly: true,
              onChanged: (s) => setState(() => _share = s)),
      ],
      dock: [
        if (_a.confident || _dish.isNotEmpty)
          SharePanel(
              settings: _share,
              caption: _caption,
              onChanged: (s) => setState(() => _share = s)),
        VitaPrimaryButton(
          label: _dish.isEmpty ? 'Nhập tên món để ghi' : 'Ghi vào Nhật ký',
          showArrow: false,
          loading: _saving,
          onPressed: canSave ? _save : null,
        ),
      ],
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile(this.label, this.grams, this.color);
  final String label;
  final int grams;
  final Color color;

  @override
  Widget build(BuildContext context) => VitaCard(
        radius: 20,
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VitaText.label),
            ),
          ]),
          const SizedBox(height: 4),
          Text.rich(TextSpan(children: [
            TextSpan(
                text: '$grams',
                style: VitaText.metric
                    .copyWith(fontSize: 26, color: VitaColors.onSurface)),
            const TextSpan(
                text: ' g',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: VitaColors.onSurfaceVariant)),
          ])),
        ]),
      );
}

class _MiniButton extends StatelessWidget {
  const _MiniButton(
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
          color: VitaColors.surfaceLow,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: VitaColors.lineSoft)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox.square(
                dimension: 40,
                child:
                    Icon(icon, size: 18, color: VitaColors.onSurfaceVariant)),
          ),
        ),
      );
}
