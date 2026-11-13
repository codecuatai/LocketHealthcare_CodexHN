import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/vita_theme.dart';
import '../../core/validation/auth_validators.dart';
import '../../data/auth/auth_repository.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/vita/password_meter.dart';
import '../../widgets/vita/vita_buttons.dart';
import '../../widgets/vita/vita_text_field.dart';
import 'auth_layout.dart';
import 'auth_sheets.dart';

enum _Busy { none, email, google }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialEmail = '', this.onLogin});

  final String initialEmail;

  /// Chuyển sang Đăng nhập, mang theo email (ví dụ khi email đã có tài khoản).
  final ValueChanged<String>? onLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  _Busy _busy = _Busy.none;
  String? _nameError;
  String? _emailError;
  bool _emailInUse = false;
  String? _passwordError;
  AuthFailure? _failure;

  @override
  void dispose() {
    for (final c in [_name, _email, _password]) {
      c.dispose();
    }
    for (final f in [_nameFocus, _emailFocus, _passwordFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (_busy != _Busy.none) return;
    final nameError = AuthValidators.displayName(_name.text);
    final emailError = AuthValidators.email(_email.text);
    final passwordError = AuthValidators.newPassword(_password.text);
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _emailInUse = false;
      _passwordError = passwordError;
      _failure = null;
    });
    if (nameError != null) return _nameFocus.requestFocus();
    if (emailError != null) return _emailFocus.requestFocus();
    if (passwordError != null) return _passwordFocus.requestFocus();

    FocusScope.of(context).unfocus();
    await _run(_Busy.email, (auth) async {
      await auth.register(
          displayName: _name.text,
          email: _email.text,
          password: _password.text);
      TextInput.finishAutofillContext();
    });
  }

  Future<void> _run(
      _Busy kind, Future<void> Function(AuthController auth) action) async {
    setState(() => _busy = kind);
    try {
      await action(context.read<AuthController>());
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        switch (failure.code) {
          case AuthFailureCode.canceled:
            break;
          case AuthFailureCode.emailInUse:
            _emailError = failure.message;
            _emailInUse = true;
          case AuthFailureCode.invalidEmail:
            _emailError = failure.message;
          case AuthFailureCode.weakPassword:
            _passwordError = failure.message;
          default:
            _failure = failure;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  void _openTerms() {
    FocusScope.of(context).unfocus();
    showVitaSheet<void>(context, (_) => const TermsSheet());
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
        title: 'Tạo tài khoản',
        form: (keyboardOpen) => [
          AutofillGroup(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VitaTextField(
                    key: const ValueKey('register-name'),
                    controller: _name,
                    focusNode: _nameFocus,
                    label: 'Tên hiển thị',
                    icon: Icons.person_outline_rounded,
                    hint: 'Bạn bè sẽ thấy tên này',
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                          AuthValidators.displayNameMaxLength),
                    ],
                    error:
                        _nameError == null ? null : VitaFieldError(_nameError!),
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                    onSubmitted: (_) => _emailFocus.requestFocus(),
                  ),
                  const SizedBox(height: 12),
                  VitaTextField(
                    key: const ValueKey('register-email'),
                    controller: _email,
                    focusNode: _emailFocus,
                    label: 'Email',
                    icon: Icons.mail_outline_rounded,
                    hint: 'ten@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    error: _emailError == null
                        ? null
                        : VitaFieldError(_emailError!,
                            action:
                                _emailInUse ? 'Đăng nhập bằng email này' : null,
                            onAction: () =>
                                widget.onLogin?.call(_email.text.trim())),
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() {
                          _emailError = null;
                          _emailInUse = false;
                        });
                      }
                    },
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder(
                    valueListenable: _password,
                    builder: (context, value, _) => VitaTextField(
                      key: const ValueKey('register-password'),
                      controller: _password,
                      focusNode: _passwordFocus,
                      label: 'Mật khẩu',
                      icon: Icons.lock_outline_rounded,
                      hint: 'Ít nhất 8 ký tự',
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      below: PasswordMeter(password: value.text),
                      error: _passwordError == null
                          ? null
                          : VitaFieldError(_passwordError!),
                      onChanged: (_) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        }
                      },
                      onSubmitted: (_) => _register(),
                    ),
                  ),
                ]),
          ),
          const SizedBox(height: 14),
          if (_failure != null) ...[
            VitaBanner(_failure!.message),
            const SizedBox(height: 12),
          ],
          VitaPrimaryButton(
            label: 'Tạo tài khoản',
            loading: _busy == _Busy.email,
            onPressed: _busy == _Busy.google ? null : _register,
          ),
          const SizedBox(height: 8),
          _Consent(onTerms: _openTerms),
          if (!keyboardOpen) ...[
            const SizedBox(height: 12),
            const AuthOrDivider(),
            const SizedBox(height: 14),
            GoogleButton(
              label: 'Đăng ký với Google',
              loading: _busy == _Busy.google,
              onPressed: _busy == _Busy.email
                  ? null
                  : () => _run(_Busy.google, (auth) => auth.signInWithGoogle()),
            ),
            const SizedBox(height: 10),
            AuthFooterLink(
              prompt: 'Đã có tài khoản?',
              action: 'Đăng nhập',
              onTap: () => widget.onLogin?.call(_email.text.trim()),
            ),
          ],
        ],
      );
}

/// Dòng đồng ý điều khoản thay cho ô tích (đăng ký = đồng ý).
class _Consent extends StatelessWidget {
  const _Consent({required this.onTerms});
  final VoidCallback onTerms;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
        fontFamily: VitaFonts.body,
        fontSize: 12,
        height: 1.5,
        color: VitaColors.muted);
    WidgetSpan link(String text) => WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Semantics(
            link: true,
            child: GestureDetector(
              onTap: onTerms,
              child: Text(text,
                  style: base.copyWith(
                      color: VitaColors.volt, fontWeight: FontWeight.w600)),
            ),
          ),
        );
    return Text.rich(
      TextSpan(style: base, children: [
        const TextSpan(text: 'Bằng việc tạo tài khoản, bạn đồng ý với '),
        link('Điều khoản sử dụng'),
        const TextSpan(text: ' và '),
        link('Lưu ý y tế'),
        const TextSpan(text: '.'),
      ]),
      textAlign: TextAlign.center,
    );
  }
}
