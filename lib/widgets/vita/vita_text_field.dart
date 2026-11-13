import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/vita_theme.dart';

/// Ô nhập theo DESIGN.md: nhãn nằm trong ô để form gọn, viền volt khi đang
/// nhập, viền đỏ và dòng lỗi khi sai.
class VitaTextField extends StatefulWidget {
  const VitaTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.focusNode,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.isPassword = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.error,
    this.below,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final bool isPassword;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  /// Dòng lỗi dưới ô. Dùng [VitaFieldError] để có thể kèm link hành động.
  final Widget? error;

  /// Nội dung luôn hiện dưới ô (ví dụ thanh đo độ mạnh mật khẩu).
  final Widget? below;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<VitaTextField> createState() => _VitaTextFieldState();
}

class _VitaTextFieldState extends State<VitaTextField> {
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant VitaTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final hasError = widget.error != null;
    final accent = hasError
        ? VitaColors.error
        : focused
            ? VitaColors.volt
            : VitaColors.muted;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? _focus.requestFocus : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 58,
          padding: const EdgeInsets.only(left: 16, right: 4),
          decoration: BoxDecoration(
            color: VitaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: hasError
                    ? VitaColors.error
                    : focused
                        ? VitaColors.volt
                        : VitaColors.lineSoft,
                width: focused || hasError ? 1.5 : 1),
          ),
          child: Row(children: [
            Icon(widget.icon, size: 20, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Text(widget.label.toUpperCase(),
                          style: VitaText.label.copyWith(color: accent)),
                    ),
                    const SizedBox(height: 2),
                    Semantics(
                        label: widget.label,
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focus,
                          enabled: widget.enabled,
                          keyboardType: widget.keyboardType,
                          textInputAction: widget.textInputAction,
                          autofillHints: widget.autofillHints,
                          obscureText: widget.isPassword && _obscured,
                          enableSuggestions: !widget.isPassword,
                          autocorrect: false,
                          textCapitalization: widget.textCapitalization,
                          inputFormatters: widget.inputFormatters,
                          onChanged: widget.onChanged,
                          onSubmitted: widget.onSubmitted,
                          style: VitaText.input,
                          cursorColor: VitaColors.volt,
                          decoration: InputDecoration.collapsed(
                            hintText: widget.hint,
                            hintStyle: VitaText.input
                                .copyWith(color: VitaColors.placeholder),
                          ),
                        )),
                  ]),
            ),
            if (widget.isPassword)
              IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                tooltip: _obscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: VitaColors.muted),
              )
            else
              const SizedBox(width: 12),
          ]),
        ),
      ),
      if (widget.below != null) ...[
        const SizedBox(height: 7),
        widget.below!,
      ],
      if (widget.error != null) ...[
        const SizedBox(height: 6),
        widget.error!,
      ],
    ]);
  }
}

/// Dòng lỗi dưới ô nhập, có thể kèm một link hành động.
class VitaFieldError extends StatelessWidget {
  const VitaFieldError(this.message, {super.key, this.action, this.onAction});
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline_rounded,
                size: 15, color: VitaColors.error),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(message,
                      style:
                          VitaText.caption.copyWith(color: VitaColors.error)),
                  if (action != null)
                    GestureDetector(
                      onTap: onAction,
                      child: Text(action!,
                          style: VitaText.caption.copyWith(
                              color: VitaColors.volt,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: VitaColors.volt)),
                    ),
                ]),
          ),
        ]),
      );
}

/// Hộp báo lỗi chung cho cả form (sai mật khẩu, mất mạng...).
class VitaBanner extends StatelessWidget {
  const VitaBanner(this.message, {super.key, this.action, this.onAction});
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: VitaColors.errorBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VitaColors.error.withValues(alpha: .3)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.error_outline_rounded,
                size: 18, color: VitaColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message,
                        style: VitaText.bodySmall
                            .copyWith(color: VitaColors.error, fontSize: 13.5)),
                    if (action != null)
                      GestureDetector(
                        onTap: onAction,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(action!,
                              style: VitaText.bodySmall.copyWith(
                                  color: VitaColors.error,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: VitaColors.error)),
                        ),
                      ),
                  ]),
            ),
          ]),
        ),
      );
}
