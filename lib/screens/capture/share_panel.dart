import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/social.dart';
import '../../core/theme/vita_theme.dart';
import '../../providers/social_controllers.dart';
import '../../widgets/vita/ui.dart';
import '../../widgets/vita/vita_buttons.dart';

/// Cách chia sẻ một Bản ghi thành Khoảnh khắc.
class ShareSettings {
  const ShareSettings({
    this.share = true,
    this.showKcal = false,
    this.audience,
  });

  final bool share;

  /// Quyền riêng tư kép: mặc định Bạn bè không thấy số calo.
  final bool showKcal;

  /// null là tất cả Bạn bè; ngược lại là id những người được chọn.
  final Set<String>? audience;

  ShareSettings copyWith(
          {bool? share, bool? showKcal, Set<String>? Function()? audience}) =>
      ShareSettings(
        share: share ?? this.share,
        showKcal: showKcal ?? this.showKcal,
        audience: audience != null ? audience() : this.audience,
      );
}

class SharePanel extends StatelessWidget {
  const SharePanel({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.caption,
    this.optionsOnly = false,
  });

  final ShareSettings settings;
  final ValueChanged<ShareSettings> onChanged;
  final TextEditingController caption;

  /// false: chỉ công tắc chia sẻ (đặt ở thanh dưới, gọn).
  /// true: các tuỳ chọn khi đã bật chia sẻ (đặt trong phần cuộn).
  final bool optionsOnly;

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendsController>().friends;
    final s = settings;
    final to = s.audience == null
        ? 'Tất cả bạn bè (${friends.length})'
        : '${s.audience!.length} người';
    Widget divider() =>
        const Divider(height: 1, thickness: 1, color: VitaColors.lineSoft);
    if (optionsOnly && !s.share) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
          color: VitaColors.surfaceLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: VitaColors.lineSoft)),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (!optionsOnly)
          _Row(
            icon: Icons.group_outlined,
            title: 'Chia sẻ cho bạn bè',
            subtitle: s.share
                ? 'Thành Khoảnh khắc trên Bảng tin'
                : 'Chỉ lưu vào Nhật ký của cậu',
            trailing: VitaSwitch(
                value: s.share,
                label: 'Chia sẻ cho bạn bè',
                onChanged: (v) => onChanged(s.copyWith(share: v))),
          ),
        if (optionsOnly) ...[
          _Row(
            icon: Icons.send_outlined,
            title: 'Gửi tới',
            onTap: () async {
              final picked = await showAppSheet<_Audience>(context,
                  builder: (_) =>
                      _AudienceSheet(friends: friends, initial: s.audience));
              if (picked != null) {
                onChanged(s.copyWith(audience: () => picked.ids));
              }
            },
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(to,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: VitaColors.onSurfaceVariant)),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: VitaColors.onSurfaceVariant),
            ]),
          ),
          divider(),
          _Row(
            icon: s.showKcal
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            title: 'Hiện calo',
            subtitle: s.showKcal
                ? 'Bạn bè thấy số kcal'
                : 'Bạn bè chỉ thấy ảnh và tên',
            trailing: VitaSwitch(
                value: s.showKcal,
                label: 'Hiện calo trên Khoảnh khắc',
                onChanged: (v) => onChanged(s.copyWith(showKcal: v))),
          ),
          divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: caption,
              maxLength: 80,
              style: const TextStyle(fontSize: 14, color: VitaColors.onSurface),
              decoration: const InputDecoration(
                hintText: 'Thêm chú thích…',
                hintStyle: TextStyle(color: VitaColors.placeholder),
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
      {required this.icon,
      required this.title,
      required this.trailing,
      this.subtitle,
      this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(children: [
              Icon(icon, size: 19, color: VitaColors.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: VitaColors.onSurface)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: VitaText.caption.copyWith(fontSize: 12)),
                    ]),
              ),
              trailing,
            ]),
          ),
        ),
      );
}

class _Audience {
  const _Audience(this.ids);
  final Set<String>? ids;
}

class _AudienceSheet extends StatefulWidget {
  const _AudienceSheet({required this.friends, required this.initial});
  final List<Person> friends;
  final Set<String>? initial;

  @override
  State<_AudienceSheet> createState() => _AudienceSheetState();
}

class _AudienceSheetState extends State<_AudienceSheet> {
  late Set<String>? _ids = widget.initial == null ? null : {...widget.initial!};

  bool _has(String id) => _ids?.contains(id) ?? false;

  /// Đang "Tất cả" mà chọn một người thì chỉ gửi cho người đó; bỏ hết hoặc
  /// chọn đủ mọi người thì quay về "Tất cả".
  void _toggle(String id) => setState(() {
        final next = {...?_ids};
        next.contains(id) ? next.remove(id) : next.add(id);
        _ids =
            next.isEmpty || next.length == widget.friends.length ? null : next;
      });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Gửi Khoảnh khắc tới', style: VitaText.sheetTitle),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(shrinkWrap: true, children: [
                  PickRow(
                    leading: const _GroupIcon(),
                    title: 'Tất cả bạn bè',
                    subtitle: 'Mặc định, ${widget.friends.length} người',
                    checked: _ids == null,
                    onTap: () => setState(() => _ids = null),
                  ),
                  for (final f in widget.friends)
                    PickRow(
                      leading: VitaAvatar(f, size: 40),
                      title: f.name,
                      checked: _has(f.id),
                      onTap: () => _toggle(f.id),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              VitaPrimaryButton(
                  label: 'Xong',
                  showArrow: false,
                  onPressed: () => Navigator.of(context).pop(_Audience(_ids))),
            ]),
      );
}

class _GroupIcon extends StatelessWidget {
  const _GroupIcon();
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
            color: VitaColors.surfaceHigh, shape: BoxShape.circle),
        child:
            const Icon(Icons.group_rounded, size: 20, color: VitaColors.volt),
      );
}

/// Một dòng chọn trong danh sách (có dấu tích tròn).
class PickRow extends StatelessWidget {
  const PickRow({
    super.key,
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.subtitleColor,
    this.checked,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;

  /// null: không hiện dấu tích.
  final bool? checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: checked ?? false,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
            child: Row(children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: VitaColors.onSurface)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: VitaText.caption.copyWith(
                                color: subtitleColor,
                                fontWeight: subtitleColor == null
                                    ? null
                                    : FontWeight.w700)),
                    ]),
              ),
              if (checked != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: checked! ? VitaColors.volt : Colors.transparent,
                    border: Border.all(
                        color: checked!
                            ? VitaColors.volt
                            : VitaColors.surfaceHighest,
                        width: 2),
                  ),
                  child: checked!
                      ? const Icon(Icons.check_rounded,
                          size: 15, color: VitaColors.onVolt)
                      : null,
                ),
            ]),
          ),
        ),
      );
}
