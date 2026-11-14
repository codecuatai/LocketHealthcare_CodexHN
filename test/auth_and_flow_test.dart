import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitasnap/core/models/health_info.dart';
import 'package:vitasnap/core/models/profile.dart';
import 'package:vitasnap/data/app_services.dart';
import 'package:vitasnap/data/auth/auth_repository.dart';
import 'package:vitasnap/data/intro/intro_store.dart';
import 'package:vitasnap/main.dart';
import 'package:vitasnap/widgets/vita/vita_buttons.dart';

import 'fakes.dart';

const _lan = AuthAccount(uid: 'u-lan', email: 'lan@gmail.com');
const _lanProfile =
    Profile(id: 'u-lan', email: 'lan@gmail.com', displayName: 'Lan');
const _cameraHint = 'Chụp món ăn, đồ uống hoặc lúc cậu vận động';

const _minh = HealthInfo(
  sex: Sex.male,
  birthYear: 1999,
  heightCm: 172,
  weightKg: 70,
  goal: HealthGoal.loseFat,
  conditions: {
    MedicalCondition.hypertension: ConditionSeverity.monitoring,
    MedicalCondition.jointPain: ConditionSeverity.mild,
  },
);

Future<void> pumpApp(WidgetTester tester,
    {AuthAccount? signedIn, HealthInfo? health}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(VitaSnapApp(
    auth: FakeAuthRepository(signedIn: signedIn),
    profiles: FakeProfileRepository({'u-lan': _lanProfile}),
    introStore: InMemoryIntroStore(seen: true),
    createServices: () => AppServices.demo(
        visionDelay: const Duration(milliseconds: 50),
        simulateFriends: false,
        health: health),
  ));
  await tester.pumpAndSettle();
}

/// AI giả lập trả lời sau vài chục ms: bơm thời gian thay vì chờ "settle".
Future<void> waitForAi(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

Future<void> tapLabel(WidgetTester tester, String label) async {
  final f = find.bySemanticsLabel(label);
  await tester.ensureVisible(f.first);
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

Future<void> pickFromGallery(WidgetTester tester, String label) async {
  await tapLabel(tester, 'Chọn ảnh từ thư viện');
  await tester.tap(find.bySemanticsLabel(label).last);
  await waitForAi(tester);
}

/// Cuộn danh sách của màn hiện tại tới khi thấy [f] (ListView chỉ dựng
/// phần gần màn hình).
Future<void> seek(WidgetTester tester, Finder f) =>
    tester.scrollUntilVisible(f, 250,
        scrollable: find
            .descendant(
                of: find.byType(ListView).last,
                matching: find.byType(Scrollable))
            .first);

Future<void> scrollTop(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).last, const Offset(0, 1200));
  await tester.pumpAndSettle();
}

Finder primary(String label) => find.widgetWithText(VitaPrimaryButton, label);

void main() {
  testWidgets('signing in opens the camera tab', (tester) async {
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
    expect(find.text(_cameraHint), findsOneWidget);
    expect(find.bySemanticsLabel('3 Khoảnh khắc mới'), findsOneWidget);
  });

  testWidgets('first capture without health info asks once, then logs the meal',
      (tester) async {
    await pumpApp(tester, signedIn: _lan);
    await tapLabel(tester, 'Chụp');
    expect(find.text('Cho AI biết đôi chút về cậu'), findsOneWidget);
    await tester.tap(find.text('Để sau'));
    await waitForAi(tester);

    expect(find.text('Phở bò tái'), findsOneWidget);
    await seek(tester, find.text('Dinh dưỡng chung'));
    expect(find.text('Phù hợp'), findsOneWidget);
    await scrollTop(tester);
    await tapLabel(tester, '1½, Nhiều');
    expect(find.bySemanticsLabel('Khoảng 720 kcal'), findsOneWidget);

    await tester.tap(primary('Ghi vào Nhật ký'));
    await tester.pump();
    expect(find.text('Đã ghi · 720 kcal · đã chia sẻ'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(_cameraHint), findsOneWidget);

    // Lần chụp sau không hỏi lại.
    await tapLabel(tester, 'Chụp');
    await waitForAi(tester);
    expect(find.text('Cho AI biết đôi chút về cậu'), findsNothing);
    expect(find.text('Phở bò tái'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Đóng').first);
    await tester.pumpAndSettle();

    await tapLabel(tester, 'Nhật ký');
    expect(find.text('Phở bò tái'), findsOneWidget);
    expect(find.text('+720'), findsOneWidget);
  });

  testWidgets('hypertension makes pho a dish to adjust', (tester) async {
    await pumpApp(tester, signedIn: _lan, health: _minh);
    await tapLabel(tester, 'Chụp');
    await waitForAi(tester);
    await seek(tester, find.text('CÁCH ĂN GIẢM HẠI'));
    expect(find.text('Nên điều chỉnh'), findsOneWidget);
    expect(find.text('Huyết áp cao'), findsOneWidget);
  });

  testWidgets(
      'activity: AI type, counts from last time, knee warning, locked when empty',
      (tester) async {
    await pumpApp(tester, signedIn: _lan, health: _minh);
    await pickFromGallery(tester, 'Chạy bộ');
    expect(find.text('Chạy bộ'), findsWidgets);
    final km = find.byKey(const ValueKey('metric-km'));
    await seek(tester, km);
    expect(tester.widget<TextField>(km).controller!.text, '5');
    await seek(tester, find.text('Dồn lực lên khớp gối'));
    expect(find.bySemanticsLabel('Tiêu hao khoảng 350 kcal'), findsOneWidget);
    await scrollTop(tester);

    await tapLabel(tester, 'Loại hoạt động: Chạy bộ. Bấm để đổi');
    await tapLabel(tester, 'Gym');
    await tapLabel(tester, 'Đẩy ngực');
    expect(primary('Điền đủ số liệu để ghi'), findsOneWidget);
    expect(
        tester
            .widget<VitaPrimaryButton>(primary('Điền đủ số liệu để ghi'))
            .onPressed,
        isNull);

    for (final m in ['sets', 'reps', 'weightKg']) {
      await tester.enterText(find.byKey(ValueKey('metric-$m')), '4');
    }
    await tester.pumpAndSettle();
    expect(primary('Ghi vào Nhật ký'), findsOneWidget);
    await tester.ensureVisible(primary('Ghi vào Nhật ký'));
    await tester.tap(primary('Ghi vào Nhật ký'));
    await tester.pump();
    expect(find.textContaining('Đã ghi Đẩy ngực'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('a desk photo is rejected and retaking returns to the camera',
      (tester) async {
    await pumpApp(tester, signedIn: _lan, health: _minh);
    await pickFromGallery(tester, 'Bàn làm việc');
    expect(
        find.text('Ảnh này không có món ăn hay lúc vận động'), findsOneWidget);
    await tester.tap(primary('Chụp lại'));
    await tester.pumpAndSettle();
    expect(find.text(_cameraHint), findsOneWidget);
  });

  testWidgets('feed: new moments glow until seen, reactions and reply',
      (tester) async {
    await pumpApp(tester, signedIn: _lan);
    await tapLabel(tester, 'Bảng tin');
    expect(find.text('Tất cả bạn bè (5)'), findsOneWidget);
    expect(find.bySemanticsLabel('Khoảnh khắc mới'), findsWidgets);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Đang xem Tất cả bạn bè (5). Bấm để chọn bạn');
    expect(find.text('Có Khoảnh khắc mới'), findsNWidgets(2));
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    final fire = find.bySemanticsLabel('Tiếp lửa').first;
    await tester.tap(fire);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(fire), isSemantics(isToggled: true));

    await tapLabel(tester, 'Nhắn cho Đan');
    expect(find.text('Trả lời Khoảnh khắc của Đan'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('chat-input')), 'Ngon quá, quán nào thế?');
    await tapLabel(tester, 'Gửi');
    expect(find.text('Ngon quá, quán nào thế?'), findsOneWidget);
    expect(find.text('Cậu trả lời Khoảnh khắc'), findsOneWidget);
  });

  testWidgets('saving health info sets a calorie target on the journal',
      (tester) async {
    await pumpApp(tester, signedIn: _lan);
    await tapLabel(tester, 'Nhật ký');
    expect(find.text('Thêm cân nặng để tính'), findsOneWidget);

    await tapLabel(tester, 'Cá nhân');
    await tester.tap(find.text('Thông tin sức khỏe'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(
            of: find.byKey(const ValueKey('health-year')),
            matching: find.byType(TextField)),
        '1999');
    await tester.enterText(
        find.descendant(
            of: find.byKey(const ValueKey('health-height')),
            matching: find.byType(TextField)),
        '172');
    await tester.enterText(
        find.descendant(
            of: find.byKey(const ValueKey('health-weight')),
            matching: find.byType(TextField)),
        '70');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Huyết áp cao'));
    await tester.pumpAndSettle();
    expect(find.text('Đang theo dõi'), findsOneWidget);
    await tester.tap(primary('Lưu thông tin'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Huyết áp cao ·'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Quay lại').first);
    await tester.pumpAndSettle();
    expect(find.text('CÒN LẠI'), findsOneWidget);
  });

  testWidgets('signing out from Cá nhân returns to login', (tester) async {
    await pumpApp(tester, signedIn: _lan);
    await tapLabel(tester, 'Cá nhân');
    expect(find.text('Lan'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Đăng xuất'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
  });
}
