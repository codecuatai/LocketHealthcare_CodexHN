import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/models/photo.dart';
import '../../core/models/social.dart';
import '../../core/theme/vita_theme.dart';
import '../../providers/journal_controller.dart';
import '../../providers/session_scope.dart';
import '../../providers/social_controllers.dart';
import '../../widgets/vita/ui.dart';
import '../capture/capture_flow.dart';
import '../personal/friends_screen.dart';
import '../personal/personal_screen.dart';
import '../shell/home_shell.dart';

/// Tab Chụp: khung ngắm tối giản, một nút chụp.
///
/// Bản demo chưa nối camera thật: khung ngắm hiện ảnh mẫu, vuốt ngang để đổi.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.active});
  final bool active;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  final _pages = PageController();
  int _scene = 0;
  bool _flash = false;
  bool _front = false;
  double _zoom = 1;
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 14));
  late final AnimationController _shutterFlash = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320), value: 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _drift.stop();
    } else if (widget.active && !_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(CameraScreen old) {
    super.didUpdateWidget(old);
    if (reduceMotion(context)) return;
    if (widget.active && !_drift.isAnimating) _drift.repeat(reverse: true);
    if (!widget.active) _drift.stop();
  }

  @override
  void dispose() {
    _pages.dispose();
    _drift.dispose();
    _shutterFlash.dispose();
    super.dispose();
  }

  Photo get _photo => SamplePhotos.camera[_scene].$1;

  Future<void> _shoot() async {
    HapticFeedback.mediumImpact();
    if (!reduceMotion(context)) _shutterFlash.forward(from: 0);
    await startCapture(context, _photo);
  }

  Future<void> _openGallery() async {
    final picked = await showAppSheet<Photo>(context,
        builder: (_) => const _GallerySheet());
    if (picked != null && mounted) await startCapture(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<Me>().person;
    final journal = context.watch<JournalController>();
    final unseen = context.watch<MomentsController>().unseen;
    final shell = HomeShell.of(context);
    return SafeArea(
      bottom: false,
      child: Column(children: [
        SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              MeButton(
                  person: me,
                  onTap: () =>
                      Navigator.of(context).push(PersonalScreen.route())),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: _NewMomentsChip(
                    people: [for (final m in unseen) m.author],
                    onTap: unseen.isEmpty
                        ? () =>
                            Navigator.of(context).push(FriendsScreen.route())
                        : () => shell?.go(HomeTab.feed),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StreakChip(journal.streak),
            ]),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Stack(fit: StackFit.expand, children: [
                const ColoredBox(color: Colors.black),
                PageView.builder(
                  controller: _pages,
                  itemCount: SamplePhotos.camera.length,
                  onPageChanged: (i) => setState(() => _scene = i),
                  itemBuilder: (_, i) => AnimatedBuilder(
                    animation: _drift,
                    builder: (_, child) {
                      final t = Curves.easeInOut.transform(_drift.value);
                      return Transform.scale(
                        scale: _zoom * (1.06 + .03 * t),
                        child: Transform.translate(
                            offset: Offset(-6 + 12 * t, 4 - 8 * t),
                            child: child),
                      );
                    },
                    child: Transform.flip(
                      flipX: _front,
                      child: Image(
                          image: SamplePhotos.camera[i].$1.image,
                          fit: BoxFit.cover,
                          semanticLabel: 'Khung ngắm camera'),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: _GlassToggle(
                    icon: _flash
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    label: _flash ? 'Tắt đèn flash' : 'Bật đèn flash',
                    on: _flash,
                    onTap: () => setState(() => _flash = !_flash),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 14,
                  child: GlassPill(
                    height: 30,
                    child: Text('Ảnh mẫu · ${SamplePhotos.camera[_scene].$2}',
                        style: const TextStyle(fontSize: 11.5)),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GlassPill(
                      height: 38,
                      padding: const EdgeInsets.all(4),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        for (final z in const [.5, 1.0, 2.0])
                          GestureDetector(
                            onTap: () => setState(() => _zoom = z == .5
                                ? .92
                                : z == 2
                                    ? 1.35
                                    : 1),
                            child: Container(
                              width: 36,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: _zoomLabel == z
                                      ? Colors.white24
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(99)),
                              child: Text(z == .5 ? '.5×' : '${z.toInt()}×',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _zoomLabel == z
                                          ? VitaColors.volt
                                          : Colors.white)),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _shutterFlash,
                    builder: (_, __) => ColoredBox(
                        color: Colors.white.withValues(
                            alpha: (1 - _shutterFlash.value) * .85)),
                  ),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(
          height: 34,
          child: Center(
            child: Text('Chụp món ăn, đồ uống hoặc lúc cậu vận động',
                style: VitaText.caption),
          ),
        ),
        SizedBox(
          height: 104,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(children: [
              Semantics(
                button: true,
                label: 'Chọn ảnh từ thư viện',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: _openGallery,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: VitaColors.surfaceHighest, width: 2),
                        image: DecorationImage(
                            image: SamplePhotos.chicken.image,
                            fit: BoxFit.cover)),
                  ),
                ),
              ),
              const Spacer(),
              _Shutter(onTap: _shoot),
              const Spacer(),
              RoundIconButton(
                icon: Icons.cameraswitch_rounded,
                label: 'Đổi camera trước sau',
                size: 50,
                onTap: () => setState(() => _front = !_front),
              ),
            ]),
          ),
        ),
        // Chừa chỗ cho thanh tab nằm đè phía dưới.
        SizedBox(height: 70 + MediaQuery.paddingOf(context).bottom),
      ]),
    );
  }

  double get _zoomLabel => _zoom < 1
      ? .5
      : _zoom > 1
          ? 2
          : 1;
}

class _NewMomentsChip extends StatelessWidget {
  const _NewMomentsChip({required this.people, required this.onTap});
  final List<Person> people;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, box) => _build(context, narrow: box.maxWidth < 240));

  Widget _build(BuildContext context, {required bool narrow}) {
    final hasNew = people.isNotEmpty;
    return Semantics(
      button: true,
      label: hasNew ? '${people.length} Khoảnh khắc mới' : 'Mời bạn bè',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          padding: EdgeInsets.fromLTRB(hasNew ? 5 : 12, 0, 12, 0),
          decoration: BoxDecoration(
              color: VitaColors.surfaceHigh,
              borderRadius: BorderRadius.circular(99)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (hasNew) ...[
              AvatarStack(people, size: 28),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                    narrow
                        ? '${people.length} mới'
                        : '${people.length} Khoảnh khắc mới',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: VitaColors.onSurface)),
              ),
              const SizedBox(width: 7),
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: VitaColors.volt, shape: BoxShape.circle)),
            ] else ...[
              const Icon(Icons.group_add_rounded,
                  size: 18, color: VitaColors.onSurfaceVariant),
              const SizedBox(width: 6),
              const Text('Mời bạn bè',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: VitaColors.onSurface)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _GlassToggle extends StatelessWidget {
  const _GlassToggle(
      {required this.icon,
      required this.label,
      required this.on,
      required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        toggled: on,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: on
              ? Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: VitaColors.volt, shape: BoxShape.circle),
                  child: Icon(icon, size: 20, color: VitaColors.onVolt))
              : GlassPill(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(icon, size: 20)),
        ),
      );
}

class _Shutter extends StatefulWidget {
  const _Shutter({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_Shutter> createState() => _ShutterState();
}

class _ShutterState extends State<_Shutter> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Chụp',
        excludeSemantics: true,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: Container(
            width: 84,
            height: 84,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: VitaColors.onSurface, width: 4)),
            child: AnimatedScale(
              scale: _down ? .88 : 1,
              duration: const Duration(milliseconds: 110),
              child: Container(
                decoration: const BoxDecoration(
                    color: VitaColors.volt,
                    shape: BoxShape.circle,
                    boxShadow: VitaShadows.glow),
              ),
            ),
          ),
        ),
      );
}

class _GallerySheet extends StatelessWidget {
  const _GallerySheet();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Ảnh gần đây', style: VitaText.sheetTitle),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (final (photo, label) in SamplePhotos.camera)
                Semantics(
                  button: true,
                  label: label,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(photo),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(fit: StackFit.expand, children: [
                        Image(image: photo.image, fit: BoxFit.cover),
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: GlassPill(
                              height: 22,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(label,
                                  style: const TextStyle(fontSize: 10.5))),
                        ),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ]),
      );
}
