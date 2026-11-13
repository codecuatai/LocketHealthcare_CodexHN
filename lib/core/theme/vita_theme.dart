import 'package:flutter/material.dart';

/// Token màu theo DESIGN.md (Athletic High-Voltage Dark).
/// Hiện chỉ dùng cho luồng vào app (Giới thiệu, Đăng nhập, Đăng ký).
abstract final class VitaColors {
  static const bg = Color(0xFF131313);
  static const surfaceLow = Color(0xFF1C1B1B);
  static const surface = Color(0xFF201F1F);
  static const surfaceHigh = Color(0xFF2A2A2A);
  static const surfaceHighest = Color(0xFF353534);
  static const onSurface = Color(0xFFE5E2E1);
  static const onSurfaceVariant = Color(0xFFC4C9AC);
  static const muted = Color(0xFF8E9379);
  static const placeholder = Color(0xFF5F6352);
  static const line = Color(0xFF444933);
  static const lineSoft = Color(0xFF2B2C26);
  static const volt = Color(0xFFC3F400);
  static const voltDim = Color(0xFFABD600);
  static const onVolt = Color(0xFF161E00);
  static const onVoltVariant = Color(0xFF3C4D00);
  static const coral = Color(0xFFFF5625);
  static const coralSoft = Color(0xFFFFB5A0);
  static const coralPale = Color(0xFFFFDBD1);
  static const cyan = Color(0xFF7DF4FF);
  static const error = Color(0xFFFFB4AB);
  static const errorBg = Color(0xFF2C1210);
}

abstract final class VitaFonts {
  static const display = 'Chivo';
  static const body = 'SpaceGrotesk';
}

abstract final class VitaText {
  static const brand = TextStyle(
      fontFamily: VitaFonts.display,
      fontWeight: FontWeight.w900,
      fontSize: 18,
      letterSpacing: -0.2,
      color: VitaColors.onSurface);
  static const heroTitle = TextStyle(
      fontFamily: VitaFonts.display,
      fontWeight: FontWeight.w900,
      fontSize: 30,
      height: 1.08,
      letterSpacing: -0.75,
      color: VitaColors.onSurface);
  static const headline = TextStyle(
      fontFamily: VitaFonts.display,
      fontWeight: FontWeight.w800,
      fontSize: 28,
      height: 1.1,
      letterSpacing: -0.3,
      color: VitaColors.onSurface);
  static const sheetTitle = TextStyle(
      fontFamily: VitaFonts.display,
      fontWeight: FontWeight.w800,
      fontSize: 24,
      height: 1.15,
      color: VitaColors.onSurface);
  static const button = TextStyle(
      fontFamily: VitaFonts.display,
      fontWeight: FontWeight.w900,
      fontSize: 17,
      letterSpacing: 0.2);
  static const metric = TextStyle(
      fontFamily: VitaFonts.display,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.8,
      height: 1,
      fontFeatures: [FontFeature.tabularFigures()]);
  static const body = TextStyle(
      fontFamily: VitaFonts.body,
      fontSize: 15,
      height: 1.45,
      color: VitaColors.onSurfaceVariant);
  static const bodySmall = TextStyle(
      fontFamily: VitaFonts.body,
      fontSize: 14,
      height: 1.45,
      color: VitaColors.onSurfaceVariant);
  static const caption = TextStyle(
      fontFamily: VitaFonts.body,
      fontSize: 12.5,
      height: 1.4,
      color: VitaColors.muted);
  static const label = TextStyle(
      fontFamily: VitaFonts.body,
      fontSize: 10.5,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.84,
      color: VitaColors.muted);
  static const input = TextStyle(
      fontFamily: VitaFonts.body,
      fontSize: 16,
      height: 1.3,
      color: VitaColors.onSurface);
  static const link = TextStyle(
      fontFamily: VitaFonts.body,
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: VitaColors.volt);
}

abstract final class VitaShadows {
  static const glow = [
    BoxShadow(color: Color(0x47C3F400), blurRadius: 24),
  ];
}

ThemeData vitaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: VitaFonts.body,
  );
  return base.copyWith(
    scaffoldBackgroundColor: VitaColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: VitaColors.volt,
      onPrimary: VitaColors.onVolt,
      secondary: VitaColors.coral,
      surface: VitaColors.bg,
      onSurface: VitaColors.onSurface,
      error: VitaColors.error,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: VitaColors.volt,
      selectionColor: VitaColors.volt.withValues(alpha: .35),
      selectionHandleColor: VitaColors.volt,
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: VitaColors.volt),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: VitaColors.surfaceHigh,
      contentTextStyle:
          TextStyle(fontFamily: VitaFonts.body, color: VitaColors.onSurface),
    ),
  );
}
