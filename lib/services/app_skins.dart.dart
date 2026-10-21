import 'package:flutter/material.dart';

class AppSkins {
  // ==========================================
  // SKIN 1: Vibrant Pastel (The exact look from your screenshot)
  // ==========================================
  static final ThemeData vibrantPastel = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F9FE),
    primaryColor: const Color(0xFF7C4DFF), // Purple FAB
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF7C4DFF),
      secondary: Color(0xFF34C759), // Green for 'Done'
      tertiary: Color(0xFFFF9500), // Orange for pending
      surface: Colors.white,
      background: Color(0xFFF8F9FE),
      onPrimary: Colors.white,
      onSurface: Color(0xFF1E1E1E),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF0F0F5),
      selectedColor: const Color(0xFF7C4DFF).withOpacity(0.2),
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF1E1E1E)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF1E1E1E)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      linearTrackColor: Color(0xFFF0F0F5),
      linearMinHeight: 8,
      color: Color(0xFF7C4DFF),
    ),
  );

  // ==========================================
  // SKIN 2: Midnight Slate (Modern Dark Mode)
  // ==========================================
  static final ThemeData midnightSlate = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: const Color(0xFFBB86FC),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFBB86FC),
      secondary: Color(0xFF03DAC6), // Teal for 'Done'
      tertiary: Color(0xFFFFB74D), // Amber for pending
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      onPrimary: Colors.black,
      onSurface: Color(0xFFE0E0E0),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2C2C2C),
      selectedColor: const Color(0xFFBB86FC).withOpacity(0.3),
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFFE0E0E0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFE0E0E0)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      linearTrackColor: Color(0xFF2C2C2C),
      linearMinHeight: 8,
      color: Color(0xFFBB86FC),
    ),
  );

  // ==========================================
  // SKIN 3: Minimalist Monochrome (Clean & Corporate)
  // ==========================================
  static final ThemeData minimalistMonochrome = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    primaryColor: const Color(0xFF000000),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF000000),
      secondary: Color(0xFF4CAF50),
      tertiary: Color(0xFFFF9800),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSurface: Color(0xFF000000),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF5F5F5),
      selectedColor: const Color(0xFF000000).withOpacity(0.1),
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF000000)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.black),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      linearTrackColor: Color(0xFFF0F0F0),
      linearMinHeight: 6,
      color: Color(0xFF000000),
    ),
  );

  // ==========================================
  // SKIN 4: Warm Sunset (Cozy & Energetic)
  // ==========================================
  static final ThemeData warmSunset = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFF8F5),
    primaryColor: const Color(0xFFFF6B6B),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFF6B6B),
      secondary: Color(0xFF4ECDC4),
      tertiary: Color(0xFFFFE66D),
      surface: Colors.white,
      background: Color(0xFFFFF8F5),
      onPrimary: Colors.white,
      onSurface: Color(0xFF2D2D2D),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0xFFFF6B6B).withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFFFF0EE),
      selectedColor: const Color(0xFFFF6B6B).withOpacity(0.2),
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF2D2D2D)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF2D2D2D)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      linearTrackColor: Color(0xFFFFF0EE),
      linearMinHeight: 8,
      color: Color(0xFFFF6B6B),
    ),
  );

  // Helper method to get a skin by name
  static ThemeData getSkin(String name) {
    switch (name.toLowerCase()) {
      case 'midnight':
        return midnightSlate;
      case 'minimalist':
        return minimalistMonochrome;
      case 'sunset':
        return warmSunset;
      case 'pastel':
      default:
        return vibrantPastel;
    }
  }
}