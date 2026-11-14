import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitasnap/core/validation/auth_validators.dart';
import 'package:vitasnap/data/auth/auth_repository.dart';
import 'package:vitasnap/data/intro/intro_store.dart';
import 'package:vitasnap/main.dart';
import 'package:vitasnap/widgets/vita/vita_buttons.dart';

import 'fakes.dart';

class AuthHarness {
  AuthHarness(this.auth, this.profiles, this.intro);
  final FakeAuthRepository auth;
  final FakeProfileRepository profiles;
  final InMemoryIntroStore intro;
}

Future<AuthHarness> pumpAuth(WidgetTester tester,
    {bool introSeen = true, Size size = const Size(360, 800)}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final h = AuthHarness(FakeAuthRepository(), FakeProfileRepository(),
      InMemoryIntroStore(seen: introSeen));
  await tester.pumpWidget(
      VitaSnapApp(auth: h.auth, profiles: h.profiles, introStore: h.intro));
  await tester.pumpAndSettle();
  return h;
}

Finder field(String key) => find.descendant(
    of: find.byKey(ValueKey(key)), matching: find.byType(TextField));

void main() {
  group('Giới thiệu', () {
    testWidgets('shows on first launch and Skip goes to register',
        (tester) async {
      final h = await pumpAuth(tester, introSeen: false);
      expect(find.textContaining('Khoảnh khắc khỏe'), findsOneWidget);

      await tester.tap(find.text('Bỏ qua'));
      await tester.pumpAndSettle();
      expect(find.text('Tạo tài khoản'), findsWidgets);
      expect(find.byKey(const ValueKey('register-name')), findsOneWidget);
      expect(h.intro.seen, isTrue);
    });

    testWidgets('last card offers register and login without moving the dots',
        (tester) async {
      await pumpAuth(tester, introSeen: false);
      final dotsBefore = tester.getTopLeft(find.bySemanticsLabel('Thẻ 1'));

      await tester.tap(find.bySemanticsLabel('Thẻ 4'));
      await tester.pumpAndSettle();
      expect(find.textContaining('điều bạn muốn'), findsOneWidget);
      expect(tester.getTopLeft(find.bySemanticsLabel('Thẻ 1')), dotsBefore);

      await tester.tap(find.text('Tôi đã có tài khoản'));
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng trở lại'), findsOneWidget);
    });

    testWidgets('is skipped once seen', (tester) async {
      await pumpAuth(tester);
      expect(find.text('Bỏ qua'), findsNothing);
      expect(find.text('Chào mừng trở lại'), findsOneWidget);
    });
  });

  group('Đăng nhập', () {
    testWidgets('validates before calling Firebase', (tester) async {
      await pumpAuth(tester);
      await tester.enterText(field('login-email'), 'not-an-email');
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Email chưa đúng định dạng'), findsOneWidget);
      expect(find.text('Nhập mật khẩu.'), findsOneWidget);
    });

    testWidgets('wrong credentials show a banner that opens password reset',
        (tester) async {
      final h = await pumpAuth(tester);
      h.auth.nextFailure =
          const AuthFailure(AuthFailureCode.invalidCredentials);
      await tester.enterText(field('login-email'), 'lan@gmail.com');
      await tester.enterText(field('login-password'), 'sai12345');
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Email hoặc mật khẩu không đúng'),
          findsOneWidget);

      await tester.tap(find.text('Đặt lại mật khẩu'));
      await tester.pumpAndSettle();
      expect(find.text('Đặt lại mật khẩu'), findsWidgets);
      final email = tester.widget<TextField>(field('forgot-email'));
      expect(email.controller!.text, 'lan@gmail.com');

      await tester.tap(find.text('Gửi link đặt lại'));
      await tester.pumpAndSettle();
      expect(find.text('Đã gửi link'), findsOneWidget);
      expect(h.auth.resetEmails, ['lan@gmail.com']);
    });

    testWidgets('hides Google and the footer while the keyboard is open',
        (tester) async {
      await pumpAuth(tester);
      expect(find.text('Tiếp tục với Google'), findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await tester.pumpAndSettle();
      expect(find.text('Tiếp tục với Google'), findsNothing);
      expect(find.text('Chưa có tài khoản?'), findsNothing);
      expect(find.text('Đăng nhập'), findsOneWidget);
      // Nút chính vẫn nằm trên bàn phím.
      expect(
          tester.getBottomLeft(find.text('Đăng nhập')).dy, lessThan(800 - 300));
    });

    testWidgets('a cancelled Google sign in stays quiet', (tester) async {
      final h = await pumpAuth(tester);
      h.auth.nextFailure = const AuthFailure(AuthFailureCode.canceled);
      await tester.tap(find.text('Tiếp tục với Google'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn đã huỷ đăng nhập.'), findsNothing);
      expect(find.text('Chào mừng trở lại'), findsOneWidget);
    });
  });

  group('Đăng ký', () {
    Future<void> openRegister(WidgetTester tester) async {
      await tester.tap(find.text('Đăng ký'));
      await tester.pumpAndSettle();
    }

    testWidgets('password meter explains what is missing', (tester) async {
      await pumpAuth(tester);
      await openRegister(tester);
      await tester.enterText(field('register-password'), 'abc');
      await tester.pump();
      expect(find.text('Cần thêm 5 ký tự'), findsOneWidget);
      await tester.enterText(field('register-password'), 'abcdefgh');
      await tester.pump();
      expect(find.text('Thêm một chữ số'), findsOneWidget);
      await tester.enterText(field('register-password'), 'Abcdefg1');
      await tester.pump();
      expect(find.text('Mạnh'), findsOneWidget);
    });

    testWidgets('email already in use links back to login with the email',
        (tester) async {
      final h = await pumpAuth(tester);
      await openRegister(tester);
      h.auth.nextFailure = const AuthFailure(AuthFailureCode.emailInUse);
      await tester.enterText(field('register-name'), 'Lan');
      await tester.enterText(field('register-email'), 'lan@gmail.com');
      await tester.enterText(field('register-password'), 'abc12345');
      await tester.tap(find.widgetWithText(VitaPrimaryButton, 'Tạo tài khoản'));
      await tester.pumpAndSettle();
      expect(find.text('Email này đã có tài khoản.'), findsOneWidget);

      await tester.tap(find.text('Đăng nhập bằng email này'));
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng trở lại'), findsOneWidget);
      expect(tester.widget<TextField>(field('login-email')).controller!.text,
          'lan@gmail.com');
    });

    testWidgets('success opens the app with the typed name', (tester) async {
      await pumpAuth(tester);
      await openRegister(tester);
      await tester.enterText(field('register-name'), 'Thảo Vy');
      await tester.enterText(field('register-email'), 'vy@gmail.com');
      await tester.enterText(field('register-password'), 'abc12345');
      await tester.tap(find.widgetWithText(VitaPrimaryButton, 'Tạo tài khoản'));
      await tester.pumpAndSettle();
      expect(find.text('Chụp món ăn, đồ uống hoặc lúc cậu vận động'),
          findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Cá nhân'));
      await tester.pumpAndSettle();
      expect(find.text('Thảo Vy'), findsOneWidget);
    });

    testWidgets('consent line opens the terms sheet', (tester) async {
      await pumpAuth(tester);
      await openRegister(tester);
      await tester.tap(find.text('Lưu ý y tế'));
      await tester.pumpAndSettle();
      expect(find.text('Điều khoản & Lưu ý y tế'), findsOneWidget);
      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();
      expect(find.text('Điều khoản & Lưu ý y tế'), findsNothing);
    });

    testWidgets('fits a small phone without overflowing', (tester) async {
      await pumpAuth(tester, size: const Size(320, 568));
      await openRegister(tester);
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260 * 3);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Android back from register returns to login', (tester) async {
      await pumpAuth(tester);
      await openRegister(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng trở lại'), findsOneWidget);
    });
  });

  group('PasswordCheck', () {
    test('requires 8 characters with a letter and a digit', () {
      expect(PasswordCheck('abc12345').isAcceptable, isTrue);
      expect(PasswordCheck('abcdefgh').isAcceptable, isFalse);
      expect(PasswordCheck('12345678').isAcceptable, isFalse);
      expect(PasswordCheck('ab1').isAcceptable, isFalse);
      expect(PasswordCheck('mậtkhẩu1').isAcceptable, isTrue,
          reason: 'Vietnamese letters count as letters');
    });

    test('grades strength', () {
      expect(PasswordCheck('').strength, PasswordStrength.empty);
      expect(PasswordCheck('abc').strength, PasswordStrength.weak);
      expect(PasswordCheck('abc12345').strength, PasswordStrength.fair);
      expect(PasswordCheck('Abc12345').strength, PasswordStrength.strong);
      expect(PasswordCheck('Abc12345!').strength, PasswordStrength.veryStrong);
    });
  });
}
