import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/validation/auth_validators.dart';
import '../../data/auth/auth_repository.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/vita/vita_buttons.dart';
import '../../widgets/vita/vita_text_field.dart';
import 'auth_layout.dart';
import 'auth_sheets.dart';

enum _Busy { none, email, google }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialEmail = '', this.onRegister});

  final String initialEmail;

  /// Chuyển sang Đăng ký, mang theo email đang gõ.
  final ValueChanged<String>? onRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  _Busy _busy = _Busy.none;
  String? _emailError;
  String? _passwordError;
  AuthFailure? _failure;

  @override
  void initState() {
    super.initState();
    // Đến từ "Đăng nhập bằng email này": email đã có, chỉ còn mật khẩu.
    if (widget.initialEmail.isNotEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _passwordFocus.requestFocus());
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy != _Busy.none) return;
    final emailError = AuthValidators.email(_email.text);
    final passwordError = AuthValidators.loginPassword(_password.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _failure = null;
    });
    if (emailError != null) return _emailFocus.requestFocus();
    if (passwordError != null) return _passwordFocus.requestFocus();

    FocusScope.of(context).unfocus();
    await _run(_Busy.email, (auth) async {
      await auth.signIn(email: _email.text, password: _password.text);
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
          case AuthFailureCode.invalidEmail:
            _emailError = failure.message;
          default:
            _failure = failure;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  void _openForgot() {
    FocusScope.of(context).unfocus();
    showVitaSheet<void>(
        context, (_) => ForgotPasswordSheet(initialEmail: _email.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    final offerReset = failure?.code == AuthFailureCode.invalidCredentials ||
        failure?.code == AuthFailureCode.tooManyRequests;
    return AuthLayout(
      title: 'Chào mừng trở lại',
      subtitle: 'Đăng nhập để xem khoảnh khắc của bạn bè hôm nay.',
      form: (keyboardOpen) => [
        AutofillGroup(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            VitaTextField(
              key: const ValueKey('login-email'),
              controller: _email,
              focusNode: _emailFocus,
              label: 'Email',
              icon: Icons.mail_outline_rounded,
              hint: 'ten@gmail.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              error: _emailError == null ? null : VitaFieldError(_emailError!),
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 12),
            VitaTextField(
              key: const ValueKey('login-password'),
              controller: _password,
              focusNode: _passwordFocus,
              label: 'Mật khẩu',
              icon: Icons.lock_outline_rounded,
              hint: 'Mật khẩu của bạn',
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              error: _passwordError == null
                  ? null
                  : VitaFieldError(_passwordError!),
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
              onSubmitted: (_) => _signIn(),
            ),
          ]),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: VitaLink('Quên mật khẩu?', onTap: _openForgot),
        ),
        if (failure != null) ...[
          VitaBanner(failure.message,
              action: offerReset ? 'Đặt lại mật khẩu' : null,
              onAction: _openForgot),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 4),
        VitaPrimaryButton(
          label: 'Đăng nhập',
          loading: _busy == _Busy.email,
          onPressed: _busy == _Busy.google ? null : _signIn,
        ),
        if (!keyboardOpen) ...[
          const SizedBox(height: 14),
          const AuthOrDivider(),
          const SizedBox(height: 14),
          GoogleButton(
            label: 'Tiếp tục với Google',
            loading: _busy == _Busy.google,
            onPressed: _busy == _Busy.email
                ? null
                : () => _run(_Busy.google, (auth) => auth.signInWithGoogle()),
          ),
          const SizedBox(height: 10),
          AuthFooterLink(
            prompt: 'Chưa có tài khoản?',
            action: 'Đăng ký',
            onTap: () => widget.onRegister?.call(_email.text.trim()),
          ),
        ],
      ],
    );
  }
}
