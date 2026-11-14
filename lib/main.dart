import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/theme/vita_theme.dart';
import 'data/app_services.dart';
import 'data/auth/auth_repository.dart';
import 'data/auth/firebase_auth_repository.dart';
import 'data/intro/intro_store.dart';
import 'data/profile/profile_repository.dart';
import 'providers/auth_controller.dart';
import 'providers/session_scope.dart';
import 'screens/auth/auth_flow.dart';
import 'screens/auth/auth_gate_screens.dart';
import 'screens/shell/session_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  IntroStore introStore;
  try {
    introStore = await SharedPreferencesIntroStore.load();
  } catch (_) {
    // Không đọc được bộ nhớ máy: coi như lần đầu, vẫn cho vào app.
    introStore = InMemoryIntroStore();
  }
  try {
    final missing = AppConfig.missingKeys;
    if (missing.isNotEmpty) {
      throw StateError('Thiếu cấu hình: ${missing.join(', ')}.');
    }
    // Android tự đọc cấu hình từ android/app/google-services.json.
    await Firebase.initializeApp();
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
      // Supabase tin Firebase ID token (Third-Party Auth), xem docs/adr/0002.
      accessToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    );
  } catch (error) {
    runApp(SetupRequiredApp(details: '$error'));
    return;
  }
  runApp(VitaSnapApp(
    auth: FirebaseAuthRepository(
        googleServerClientId: AppConfig.googleServerClientId.isEmpty
            ? null
            : AppConfig.googleServerClientId),
    profiles: SupabaseProfileRepository(Supabase.instance.client),
    introStore: introStore,
  ));
}

class VitaSnapApp extends StatelessWidget {
  const VitaSnapApp({
    super.key,
    required this.auth,
    required this.profiles,
    required this.introStore,
    this.createServices = AppServices.demo,
  });

  final AuthRepository auth;
  final ProfileRepository profiles;
  final IntroStore introStore;

  /// Dữ liệu của mỗi phiên đăng nhập. Hiện là bản demo trong bộ nhớ (Bảng
  /// tin, Nhật ký, AI...); Tài khoản và Hồ sơ đã là dữ liệu thật.
  final AppServices Function() createServices;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AuthController(auth: auth, profiles: profiles),
        child: MaterialApp(
          title: 'VitaSnap',
          debugShowCheckedModeBanner: false,
          theme: vitaTheme(),
          home: Consumer<AuthController>(
              builder: (_, auth, __) => switch (auth.status) {
                    AuthStatus.initializing ||
                    AuthStatus.loadingProfile =>
                      const AuthSplashScreen(),
                    AuthStatus.signedOut => AuthFlow(introStore: introStore),
                    AuthStatus.profileError => const ProfileErrorScreen(),
                    AuthStatus.signedIn => SessionScope(
                        key: ValueKey(auth.profile!.id),
                        profile: auth.profile!,
                        createServices: createServices,
                        child: const SessionNavigator(),
                      ),
                  }),
        ),
      );
}
