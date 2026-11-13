import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitasnap/core/models/user_model.dart';
import 'package:vitasnap/main.dart';
import 'package:vitasnap/providers/auth_provider.dart';

void main() {
  test('demo profiles switch without a backend and logout clears the session',
      () {
    final auth = AuthProvider();
    expect(auth.isAuthenticated, isFalse);
    auth.switchDemoUser(DemoPreset.userA);
    expect(auth.currentUser?.name, 'Nguyễn Văn A');
    expect(auth.currentUser?.conditions, contains('Huyết áp cao'));
    auth.switchDemoUser(DemoPreset.userB);
    expect(auth.currentUser?.targetKcal, 2600);
    expect(auth.currentUser?.conditions, isEmpty);
    auth.logout();
    expect(auth.isAuthenticated, isFalse);
  });

  test('local email sign-in validates input and creates a generic profile', () {
    final auth = AuthProvider();
    expect(() => auth.login('invalid', 'password'), throwsFormatException);
    expect(auth.isAuthenticated, isFalse);
    auth.login('demo@example.com', 'password');
    expect(auth.isAuthenticated, isTrue);
    expect(auth.currentUser?.name, 'demo');
    expect(auth.currentUser?.conditions, isEmpty);
  });

  testWidgets('one tap demo opens camera, result sheet, and shared feed',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const VitaSnapApp());
    await tester.tap(find.textContaining('Demo: User A'));
    await tester.pumpAndSettle();
    expect(find.text('Chụp bữa ăn'), findsOneWidget);
    expect(find.textContaining('Nguyễn Văn A'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Chụp ảnh bữa ăn'));
    await tester.pumpAndSettle();
    expect(find.text('520'), findsOneWidget);
    expect(find.textContaining('Natri'), findsOneWidget);

    await tester.tap(find.text('Lưu & Chia sẻ lên Feed'));
    await tester.pumpAndSettle();
    expect(find.text('Khoảnh Khắc'), findsWidgets);
    expect(find.text('Bạn'), findsOneWidget);
  });

  testWidgets('profile switch updates personalized guidance', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const VitaSnapApp());
    await tester.tap(find.textContaining('Demo: User A'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Đổi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trần Minh B'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Trần Minh B'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Chụp ảnh bữa ăn'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Natri'), findsNothing);
    expect(find.textContaining('Thêm rau'), findsOneWidget);
    await tester.tap(find.text('Lưu & Chia sẻ lên Feed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tổng quan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tăng cơ'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.textContaining('Để hỗ trợ mục tiêu tăng cơ'), findsOneWidget);
  });
}
