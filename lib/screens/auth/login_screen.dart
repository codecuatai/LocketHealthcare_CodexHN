import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/models/user_model.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    try {
      context.read<AuthProvider>().login(_email.text, _password.text);
    } on FormatException catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                Expanded(
                    child: SingleChildScrollView(
                        child: Form(
                            key: _formKey,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 36),
                                  Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                          color:
                                              AppColors.mint.withOpacity(.14),
                                          borderRadius:
                                              BorderRadius.circular(18)),
                                      child: const Icon(Icons.spa_rounded,
                                          color: AppColors.mint, size: 30)),
                                  const SizedBox(height: 38),
                                  const Text('Chào mừng đến\nVitaSnap.',
                                      style: AppStyles.display),
                                  const SizedBox(height: 12),
                                  const Text(
                                      'Một góc nhìn nhẹ nhàng hơn về dinh dưỡng mỗi ngày.',
                                      style: AppStyles.bodySmall),
                                  const SizedBox(height: 40),
                                  const Text('EMAIL',
                                      style: TextStyle(
                                          fontSize: 11,
                                          letterSpacing: 2,
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                      controller: _email,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [
                                        AutofillHints.email
                                      ],
                                      decoration: const InputDecoration(
                                          hintText: 'ban@example.com'),
                                      validator: (value) => value == null ||
                                              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                                  .hasMatch(value.trim())
                                          ? 'Nhập email hợp lệ'
                                          : null),
                                  const SizedBox(height: 20),
                                  const Text('MẬT KHẨU',
                                      style: TextStyle(
                                          fontSize: 11,
                                          letterSpacing: 2,
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                      controller: _password,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                          hintText: '••••••••'),
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                              ? 'Nhập mật khẩu'
                                              : null),
                                  const SizedBox(height: 22),
                                  ElevatedButton(
                                      onPressed: _login,
                                      child: const Text('Đăng nhập')),
                                  const SizedBox(height: 10),
                                  const Center(
                                      child: Text(
                                          'Chế độ cục bộ · không kết nối máy chủ',
                                          style: AppStyles.bodySmall)),
                                  const SizedBox(height: 24),
                                ])))),
                if (!keyboardOpen)
                  Container(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppStyles.radius),
                          border: Border.all(color: AppColors.border)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Icon(Icons.bolt,
                                  color: AppColors.amber, size: 18),
                              SizedBox(width: 7),
                              Text('TRẢI NGHIỆM NHANH',
                                  style: TextStyle(
                                      color: AppColors.amber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.8))
                            ]),
                            const SizedBox(height: 7),
                            const Text('Chọn một hồ sơ. Vào ứng dụng ngay.',
                                style: AppStyles.bodySmall),
                            const SizedBox(height: 17),
                            _DemoButton(
                                label: '⚡  Demo: User A · Khớp gối + Huyết áp',
                                onPressed: () => context
                                    .read<AuthProvider>()
                                    .switchDemoUser(DemoPreset.userA)),
                            const SizedBox(height: 10),
                            _DemoButton(
                                label: '⚡  Demo: User B · Gymmer khỏe mạnh',
                                onPressed: () => context
                                    .read<AuthProvider>()
                                    .switchDemoUser(DemoPreset.userB)),
                          ])),
              ]))),
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              backgroundColor: AppColors.border.withOpacity(.55),
              minimumSize: const Size.fromHeight(54),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          child: Text(label,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))));
}
