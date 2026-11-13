import 'package:flutter_test/flutter_test.dart';
import 'package:vitasnap/core/models/profile.dart';
import 'package:vitasnap/data/auth/auth_repository.dart';
import 'package:vitasnap/data/profile/profile_repository.dart';
import 'package:vitasnap/providers/auth_controller.dart';

import 'fakes.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late AuthController controller;

  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository();
    controller = AuthController(auth: auth, profiles: profiles);
  });
  tearDown(() => controller.dispose());

  test('starts initializing, then signed out when no session is stored',
      () async {
    final fresh =
        AuthController(auth: FakeAuthRepository(), profiles: profiles);
    addTearDown(fresh.dispose);
    expect(fresh.status, AuthStatus.initializing);
    await settle();
    expect(fresh.status, AuthStatus.signedOut);
    expect(fresh.profile, isNull);
  });

  test('restores a stored session straight into the profile', () async {
    final restored = AuthController(
        auth: FakeAuthRepository(
            signedIn: const AuthAccount(uid: 'u1', email: 'lan@gmail.com')),
        profiles: profiles);
    addTearDown(restored.dispose);
    await settle();
    await settle();
    expect(restored.status, AuthStatus.signedIn);
    expect(restored.profile?.id, 'u1');
  });

  test('sign in creates a profile named after the email when none exists',
      () async {
    await settle();
    await controller.signIn(email: 'minh.an@gmail.com', password: 'secret12');
    await settle();
    expect(controller.status, AuthStatus.signedIn);
    expect(controller.profile?.displayName, 'minh.an');
    expect(controller.profile?.email, 'minh.an@gmail.com');
  });

  test('register stores the typed name even before Firebase saves it',
      () async {
    await settle();
    await controller.register(
        displayName: '  Thảo Vy ', email: 'vy@gmail.com', password: 'abc12345');
    await settle();
    expect(controller.status, AuthStatus.signedIn);
    expect(controller.profile?.displayName, 'Thảo Vy');
    expect(profiles.calls, 1,
        reason: 'the second userChanges() event for the same uid is ignored');
  });

  test('a failed sign in surfaces AuthFailure and stays signed out', () async {
    await settle();
    auth.nextFailure = const AuthFailure(AuthFailureCode.invalidCredentials);
    await expectLater(
        controller.signIn(email: 'a@b.co', password: 'nope'),
        throwsA(isA<AuthFailure>().having(
            (f) => f.code, 'code', AuthFailureCode.invalidCredentials)));
    expect(controller.status, AuthStatus.signedOut);
  });

  test('a failed register does not leak its name into the next sign in',
      () async {
    await settle();
    auth.nextFailure = const AuthFailure(AuthFailureCode.emailInUse);
    await expectLater(
        controller.register(
            displayName: 'Ghost', email: 'x@gmail.com', password: 'abc12345'),
        throwsA(isA<AuthFailure>()));
    await controller.signIn(email: 'x@gmail.com', password: 'abc12345');
    await settle();
    expect(profiles.requestedNames.last, isNull);
    expect(controller.profile?.displayName, 'x');
  });

  test('profile load failure can be retried', () async {
    await settle();
    profiles.failuresLeft = 1;
    await controller.signIn(email: 'lan@gmail.com', password: 'abc12345');
    await settle();
    expect(controller.status, AuthStatus.profileError);
    expect(controller.profileFailure, isA<ProfileFailure>());

    await controller.retryProfile();
    expect(controller.status, AuthStatus.signedIn);
    expect(controller.profileFailure, isNull);
  });

  test('Google sign in keeps the Google name and photo', () async {
    await settle();
    await controller.signInWithGoogle();
    await settle();
    expect(controller.profile?.displayName, 'Minh An');
    expect(controller.profile?.avatarUrl, 'https://example.com/a.png');
  });

  test('sign out clears the profile', () async {
    await settle();
    await controller.signIn(email: 'lan@gmail.com', password: 'abc12345');
    await settle();
    await controller.signOut();
    await settle();
    expect(controller.status, AuthStatus.signedOut);
    expect(controller.profile, isNull);
  });

  test('password reset is passed through to the auth provider', () async {
    await controller.sendPasswordReset('lan@gmail.com');
    expect(auth.resetEmails, ['lan@gmail.com']);
  });

  group('AuthFailure.fromFirebaseCode', () {
    test('never reveals whether an email has an account', () {
      final messages = {
        for (final code in [
          'invalid-credential',
          'INVALID_LOGIN_CREDENTIALS',
          'wrong-password',
          'user-not-found',
        ])
          AuthFailure.fromFirebaseCode(code).message,
      };
      expect(messages, hasLength(1));
    });

    test('maps known codes and falls back to unknown', () {
      expect(AuthFailure.fromFirebaseCode('email-already-in-use').code,
          AuthFailureCode.emailInUse);
      expect(AuthFailure.fromFirebaseCode('network-request-failed').code,
          AuthFailureCode.network);
      expect(AuthFailure.fromFirebaseCode('too-many-requests').code,
          AuthFailureCode.tooManyRequests);
      expect(AuthFailure.fromFirebaseCode('something-new').code,
          AuthFailureCode.unknown);
    });
  });

  group('Profile', () {
    test('parses a Supabase row and ignores unknown conditions', () {
      final profile = Profile.fromJson({
        'id': 'u1',
        'email': 'lan@gmail.com',
        'display_name': 'Lan',
        'avatar_url': null,
        'birth_year': 1994,
        'height_cm': 162.5,
        'weight_kg': 54,
        'goal': 'lose_fat',
        'conditions': ['hypertension', 'not_a_condition'],
        'target_kcal': 1800,
      });
      expect(profile.goal, HealthGoal.loseFat);
      expect(profile.conditions, [MedicalCondition.hypertension]);
      expect(profile.weightKg, 54.0);
      expect(profile.effectiveTargetKcal, 1800);
    });

    test('falls back to safe defaults before onboarding', () {
      final profile = Profile.fromJson({
        'id': 'u1',
        'email': 'lan@gmail.com',
        'display_name': 'Lan',
        'conditions': <String>[],
      });
      expect(profile.hasMedicalConditions, isFalse);
      expect(profile.effectiveTargetKcal, Profile.defaultTargetKcal);
      expect(profile.goalLabel, 'Chưa đặt mục tiêu');
    });
  });

  test('fallbackDisplayName trims, caps length and uses the email', () {
    expect(fallbackDisplayName('  Lan  ', 'x@y.z'), 'Lan');
    expect(fallbackDisplayName('', 'minh.an@gmail.com'), 'minh.an');
    expect(fallbackDisplayName(null, '@gmail.com'), 'Bạn mới');
    expect(fallbackDisplayName('a' * 80, 'x@y.z'), hasLength(60));
  });
}
