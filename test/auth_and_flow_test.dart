import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitasnap/core/models/profile.dart';
import 'package:vitasnap/data/auth/auth_repository.dart';
import 'package:vitasnap/data/intro/intro_store.dart';
import 'package:vitasnap/main.dart';

import 'fakes.dart';

const _lan = AuthAccount(uid: 'u-lan', email: 'lan@gmail.com');

Future<void> pumpApp(WidgetTester tester,
    {AuthAccount? signedIn, Map<String, Profile>? rows}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(VitaSnapApp(
      auth: FakeAuthRepository(signedIn: signedIn),
      profiles: FakeProfileRepository(rows),
      introStore: InMemoryIntroStore(seen: true)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signed out shows login; signing in opens the camera',
      (tester) async {
    await pumpApp(tester);
    expect(find.text('Chào mừng trở lại'), findsOneWidget);

    await tester.enterText(
        find.descendant(
            of: find.byKey(const ValueKey('login-email')),
            matching: find.byType(TextField)),
        'lan@gmail.com');
    await tester.enterText(
        find.descendant(
            of: find.byKey(const ValueKey('login-password')),
            matching: find.byType(TextField)),
        'abc12345');
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Chụp bữa ăn'), findsOneWidget);
    expect(find.text('lan'), findsOneWidget);
  });

  testWidgets(
      'profile with hypertension gets a sodium warning and can share to feed',
      (tester) async {
    await pumpApp(tester, signedIn: _lan, rows: {
      'u-lan': const Profile(
          id: 'u-lan',
          email: 'lan@gmail.com',
          displayName: 'Lan',
          conditions: [MedicalCondition.hypertension]),
    });
    expect(find.text('Lan'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Chụp ảnh bữa ăn'));
    await tester.pumpAndSettle();
    expect(find.text('520'), findsOneWidget);
    expect(find.textContaining('Natri'), findsOneWidget);

    await tester.tap(find.text('Lưu & Chia sẻ lên Feed'));
    await tester.pumpAndSettle();
    expect(find.text('Khoảnh Khắc'), findsWidgets);
    expect(find.text('Bạn'), findsOneWidget);
  });

  testWidgets('profile without health data gets generic guidance',
      (tester) async {
    await pumpApp(tester, signedIn: _lan);
    await tester.tap(find.bySemanticsLabel('Chụp ảnh bữa ăn'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Natri'), findsNothing);
    expect(find.textContaining('Thêm rau'), findsOneWidget);
  });

  testWidgets('dashboard follows the profile goal', (tester) async {
    await pumpApp(tester, signedIn: _lan, rows: {
      'u-lan': const Profile(
          id: 'u-lan',
          email: 'lan@gmail.com',
          displayName: 'Lan',
          goal: HealthGoal.gainMuscle,
          targetKcal: 2600),
    });
    await tester.tap(find.text('Tổng quan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2600 kcal · Tăng cơ'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.textContaining('Để hỗ trợ mục tiêu tăng cơ'), findsOneWidget);
  });

  testWidgets('signing out from the account sheet returns to login',
      (tester) async {
    await pumpApp(tester, signedIn: _lan);
    await tester.tap(find.text('lan'));
    await tester.pumpAndSettle();
    expect(find.text('lan@gmail.com'), findsOneWidget);
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
  });
}
