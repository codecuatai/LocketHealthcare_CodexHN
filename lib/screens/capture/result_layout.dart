import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/models/entry.dart';
import '../../core/models/photo.dart';
import '../../core/models/social.dart';
import '../../core/theme/vita_theme.dart';
import '../../providers/journal_controller.dart';
import '../../providers/session_scope.dart';
import '../../providers/social_controllers.dart';
import '../../widgets/vita/ui.dart';
import 'share_panel.dart';

/// Khung chung của màn kết quả: nút ✕, nội dung cuộn, thanh dưới cố định.
class ResultLayout extends StatelessWidget {
  const ResultLayout(
      {super.key, required this.title, required this.body, required this.dock});
  final String title;
  final List<Widget> body;
  final List<Widget> dock;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VitaColors.bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            VitaTopBar(
                leading: const BackButtonRound(icon: Icons.close_rounded),
                title: Text(title)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  for (final (i, w) in body.indexed) ...[
                    if (i > 0) const SizedBox(height: 14),
                    w,
                  ],
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                  color: VitaColors.bg,
                  border: Border(top: BorderSide(color: VitaColors.lineSoft))),
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, w) in dock.indexed) ...[
                      if (i > 0) const SizedBox(height: 10),
                      w,
                    ],
                  ]),
            ),
          ]),
        ),
      );
}

/// Ảnh vừa chụp, bo 28px, kèm nhãn AI.
class ResultPhoto extends StatelessWidget {
  const ResultPhoto(
      {super.key, required this.photo, required this.label, this.height = 220});
  final Photo photo;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: height,
          child: Stack(fit: StackFit.expand, children: [
            Image(image: photo.image, fit: BoxFit.cover),
            Positioned(
              left: 12,
              bottom: 12,
              child: GlassPill(
                height: 30,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 15, color: VitaColors.volt),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ),
      );
}

/// Lưu Bản ghi vào Nhật ký, chia sẻ thành Khoảnh khắc nếu được bật,
/// báo "Đã ghi" rồi quay về Chụp.
Future<void> saveEntry(
  BuildContext context, {
  required Entry entry,
  required MomentKind kind,
  required String momentLabel,
  required int? kcal,
  required ShareSettings share,
  required String caption,
}) async {
  final journal = context.read<JournalController>();
  final moments = context.read<MomentsController>();
  final friends = context.read<FriendsController>().friends;
  final me = context.read<Me>().person;
  final navigator = Navigator.of(context);
  final overlayContext = navigator.context;

  await journal.add(entry);
  if (share.share && entry.photo != null) {
    await moments.share(
      Moment(
        id: 'moment-${entry.id}',
        author: me,
        isMine: true,
        photo: entry.photo!,
        kind: kind,
        label: momentLabel,
        kcal: share.showKcal ? kcal : null,
        caption: caption.trim(),
        postedAt: entry.at,
      ),
      audience: share.audience == null
          ? null
          : friends.where((f) => share.audience!.contains(f.id)).toList(),
    );
  }
  final what = switch (entry) {
    MealEntry() => kcal == null ? 'Đã ghi' : 'Đã ghi · ${formatInt(kcal)} kcal',
    ActivityEntry(:final type) => kcal == null
        ? 'Đã ghi ${type.label}'
        : 'Đã ghi ${type.label} · ${formatInt(kcal)} kcal',
  };
  if (overlayContext.mounted) {
    showVitaToast(overlayContext, share.share ? '$what · đã chia sẻ' : what);
  }
  navigator.pop();
}
