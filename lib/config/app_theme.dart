import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();
  static const bg = Color(0xFFF8F8FC);
  static const surface = Colors.white;
  static const surface2 = Color(0xFFF4F3F7);
  static const border = Color(0xFFEEEDF4);
  static const borderHi = Color(0xFFE2E0EA);
  static const text = Color(0xFF29263B);
  static const textDim = Color(0xFF89869D);
  static const textMute = Color(0xFFA4A1B3);
  static const accent = Color(0xFF6354E8);
  static const accent2 = Color(0xFF7864F1);
  static const accentBg = Color(0xFFF0EDFF);
  static const green = Color(0xFF16A979);
  static const greenBg = Color(0xFFE6FBF4);
  static const yellow = Color(0xFFF5A623);
  static const yellowBg = Color(0xFFFFF6E5);
  static const red = Color(0xFFE95757);
  static const redBg = Color(0xFFFFEEEE);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8675FF), Color(0xFF5844DC)],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        surface: AppColors.surface,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
      ),
    );
  }
}
