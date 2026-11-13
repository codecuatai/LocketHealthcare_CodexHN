import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_styles.dart';
import 'data/auth/auth_repository.dart';
import 'data/auth/firebase_auth_repository.dart';
import 'data/intro/intro_store.dart';
import 'data/profile/profile_repository.dart';
import 'providers/auth_controller.dart';
import 'screens/auth/auth_flow.dart';
import 'screens/auth/auth_gate_screens.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/feed/social_feed_screen.dart';
import 'screens/home/camera_home_screen.dart';

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
  });
  final AuthRepository auth;
  final ProfileRepository profiles;
  final IntroStore introStore;
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => AuthController(auth: auth, profiles: profiles))
        ],
        child: MaterialApp(
          title: 'VitaSnap',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: const ColorScheme.dark(
                primary: AppColors.mint,
                onPrimary: AppColors.background,
                surface: AppColors.surface,
                onSurface: AppColors.white,
                secondary: AppColors.amber,
                error: AppColors.rose),
            textTheme: const TextTheme(
                displayLarge: AppStyles.display,
                headlineMedium: AppStyles.heading,
                titleLarge: AppStyles.title,
                bodyLarge: AppStyles.body,
                bodyMedium: AppStyles.bodySmall),
            inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.surface,
                hintStyle: const TextStyle(color: AppColors.muted),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.border))),
            elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppColors.mint,
                    foregroundColor: AppColors.background,
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)))),
          ),
          home: Consumer<AuthController>(
              builder: (_, auth, __) => switch (auth.status) {
                    AuthStatus.initializing ||
                    AuthStatus.loadingProfile =>
                      const AuthSplashScreen(),
                    AuthStatus.signedOut => AuthFlow(introStore: introStore),
                    AuthStatus.profileError => const ProfileErrorScreen(),
                    AuthStatus.signedIn =>
                      VitaSnapShell(key: ValueKey(auth.profile!.id)),
                  }),
        ),
      );
}

class VitaSnapShell extends StatefulWidget {
  const VitaSnapShell({super.key});
  @override
  State<VitaSnapShell> createState() => _VitaSnapShellState();
}

class _VitaSnapShellState extends State<VitaSnapShell> {
  int _tab = 0;
  bool _hasSharedPho = false;
  void _sharePho() => setState(() {
        _hasSharedPho = true;
        _tab = 1;
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _tab, children: [
          CameraHomeScreen(
              onShare: _sharePho, onActivity: () => setState(() => _tab = 2)),
          SocialFeedScreen(hasSharedPho: _hasSharedPho),
          const DashboardScreen(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.mint.withOpacity(.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.camera_alt_outlined),
                selectedIcon: Icon(Icons.camera_alt),
                label: 'Chụp ảnh'),
            NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Khoảnh khắc'),
            NavigationDestination(
                icon: Icon(Icons.donut_large_outlined),
                selectedIcon: Icon(Icons.donut_large),
                label: 'Tổng quan'),
          ],
        ),
      );
}
