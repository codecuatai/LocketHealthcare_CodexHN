import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_styles.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/feed/social_feed_screen.dart';
import 'screens/home/camera_home_screen.dart';

void main() => runApp(const VitaSnapApp());

class VitaSnapApp extends StatelessWidget {
  const VitaSnapApp({super.key});
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
    child: MaterialApp(
      title: 'VitaSnap', debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(primary: AppColors.mint,
          onPrimary: AppColors.background, surface: AppColors.surface,
          onSurface: AppColors.white, secondary: AppColors.amber, error: AppColors.rose),
        textTheme: const TextTheme(displayLarge: AppStyles.display,
          headlineMedium: AppStyles.heading, titleLarge: AppStyles.title,
          bodyLarge: AppStyles.body, bodyMedium: AppStyles.bodySmall),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: AppColors.surface,
          hintStyle: const TextStyle(color: AppColors.muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.border))),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56), backgroundColor: AppColors.mint,
          foregroundColor: AppColors.background,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))),
      ),
      home: Consumer<AuthProvider>(builder: (_, auth, __) =>
        auth.isAuthenticated ? const VitaSnapShell() : const LoginScreen()),
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
  void _sharePho() => setState(() { _hasSharedPho = true; _tab = 1; });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _tab, children: [
      CameraHomeScreen(onShare: _sharePho),
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
        NavigationDestination(icon: Icon(Icons.camera_alt_outlined),
          selectedIcon: Icon(Icons.camera_alt), label: 'Chụp ảnh'),
        NavigationDestination(icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded), label: 'Khoảnh khắc'),
        NavigationDestination(icon: Icon(Icons.donut_large_outlined),
          selectedIcon: Icon(Icons.donut_large), label: 'Tổng quan'),
      ],
    ),
  );
}
