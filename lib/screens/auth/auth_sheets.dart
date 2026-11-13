import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/vita_theme.dart';
import '../../core/validation/auth_validators.dart';
import '../../data/auth/auth_repository.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/vita/vita_buttons.dart';
import '../../widgets/vita/vita_text_field.dart';

/// Mở một bottom sheet theo DESIGN.md: nền mờ đặc, bo 32px, tự nhường chỗ
/// cho bàn phím.
Future<T?> showVitaSheet<T>(BuildContext context, WidgetBuilder builder) {
  final controller = context.read<AuthController>();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: VitaColors.surfaceLow,
    barrierColor: const Color(0xB8121212),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (sheetContext) => ChangeNotifierProvider.value(
      value: controller,
      child: Theme(
        data: vitaTheme(),
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                            color: VitaColors.surfaceHighest,
                            borderRadius: BorderRadius.circular(4))),
                  ),
                  Builder(builder: builder),
                ]),
          ),
        ),
      ),
    ),
  );
}

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key, this.initialEmail = ''});
  final String initialEmail;

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _sending = false;
  String? _sentTo;
  String? _fieldError;
  String? _banner;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final error = AuthValidators.email(_email.text);
    setState(() {
      _fieldError = error;
      _banner = null;
    });
    if (error != null) return;
    setState(() => _sending = true);
    try {
      await context.read<AuthController>().sendPasswordReset(_email.text);
      if (mounted) setState(() => _sentTo = _email.text.trim());
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        if (failure.code == AuthFailureCode.invalidEmail) {
          _fieldError = failure.message;
        } else {
          _banner = failure.message;
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentTo = _sentTo;
    if (sentTo != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
                color: VitaColors.volt, shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_outlined,
                color: VitaColors.onVolt, size: 28),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Đã gửi link', style: VitaText.sheetTitle),
        const SizedBox(height: 10),
        Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Nếu '),
              TextSpan(
                  text: sentTo,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: VitaColors.onSurface)),
              const TextSpan(
                  text:
                      ' có tài khoản VitaSnap, link đặt mật khẩu mới sẽ đến trong vài phút. Nhớ xem cả mục Spam.'),
            ]),
            style: VitaText.bodySmall),
        const SizedBox(height: 22),
        VitaPrimaryButton(
            label: 'Quay lại đăng nhập',
            showArrow: false,
            onPressed: () => Navigator.of(context).pop()),
      ]);
    }
    return AutofillGroup(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Đặt lại mật khẩu', style: VitaText.sheetTitle),
        const SizedBox(height: 8),
        const Text(
            'Nhập email bạn đã dùng để đăng ký. VitaSnap sẽ gửi link để bạn đặt mật khẩu mới.',
            style: VitaText.bodySmall),
        const SizedBox(height: 18),
        VitaTextField(
          key: const ValueKey('forgot-email'),
          controller: _email,
          label: 'Email',
          icon: Icons.mail_outline_rounded,
          hint: 'ten@gmail.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          autofillHints: const [AutofillHints.email],
          error: _fieldError == null ? null : VitaFieldError(_fieldError!),
          onChanged: (_) {
            if (_fieldError != null) setState(() => _fieldError = null);
          },
          onSubmitted: (_) => _send(),
        ),
        if (_banner != null) ...[
          const SizedBox(height: 12),
          VitaBanner(_banner!),
        ],
        const SizedBox(height: 18),
        VitaPrimaryButton(
            label: 'Gửi link đặt lại', loading: _sending, onPressed: _send),
        const SizedBox(height: 10),
        VitaGhostButton(
            label: 'Huỷ', onPressed: () => Navigator.of(context).pop()),
      ]),
    );
  }
}

class TermsSheet extends StatelessWidget {
  const TermsSheet({super.key});

  static const _points = [
    'Khoảnh khắc chỉ hiện với bạn bè bạn đã kết bạn.',
    'Bệnh lý nền, cân nặng và số calo chi tiết luôn ẩn khỏi bạn bè, trừ khi bạn tự bật chia sẻ.',
    'Ảnh không liên quan đến ăn uống hoặc vận động sẽ không được đăng.',
  ];

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Điều khoản & Lưu ý y tế', style: VitaText.sheetTitle),
        const SizedBox(height: 14),
        const Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: 'Lưu ý y tế. ',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: VitaColors.onSurface)),
              TextSpan(
                  text:
                      'VitaSnap dùng AI để ước lượng calo và gợi ý vận động. Thông tin này chỉ để tham khảo, không thay thế chẩn đoán hay chỉ định của bác sĩ. Nếu bạn có bệnh lý nền, hãy hỏi bác sĩ trước khi thay đổi chế độ ăn hoặc tập luyện.'),
            ]),
            style: VitaText.bodySmall),
        const SizedBox(height: 14),
        for (final point in _points)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 10),
                  decoration: const BoxDecoration(
                      color: VitaColors.volt, shape: BoxShape.circle)),
              Expanded(child: Text(point, style: VitaText.bodySmall)),
            ]),
          ),
        const SizedBox(height: 14),
        VitaPrimaryButton(
            label: 'Đã hiểu',
            showArrow: false,
            onPressed: () => Navigator.of(context).pop()),
      ]);
}
