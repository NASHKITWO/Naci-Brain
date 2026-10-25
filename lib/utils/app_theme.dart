// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonCyan,
        secondary: AppColors.neonPurple,
        tertiary: AppColors.neonYellow,
        background: AppColors.bgDark,
        surface: AppColors.bgCard,
        error: AppColors.neonRed,
        onPrimary: AppColors.bgDark,
        onSecondary: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 48,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonCyan,
          foregroundColor: AppColors.bgDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E1E3A),
        thickness: 1,
      ),
    );
  }

  // ─── Neon Glow Box Shadows ─────────────────────────────────────────────────
  static List<BoxShadow> neonGlow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withOpacity(0.4 * intensity),
        blurRadius: 8,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: color.withOpacity(0.2 * intensity),
        blurRadius: 20,
        spreadRadius: 4,
      ),
      BoxShadow(
        color: color.withOpacity(0.1 * intensity),
        blurRadius: 40,
        spreadRadius: 8,
      ),
    ];
  }

  static List<BoxShadow> subtleGlow(Color color) {
    return [
      BoxShadow(
        color: color.withOpacity(0.3),
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ];
  }

  // ─── Gradients ─────────────────────────────────────────────────────────────
  static LinearGradient get backgroundGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF050510),
          Color(0xFF0A0A20),
          Color(0xFF050515),
        ],
      );

  static LinearGradient cardGradient(Color color) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.15),
          color.withOpacity(0.05),
        ],
      );

  // ─── Border ────────────────────────────────────────────────────────────────
  static Border neonBorder(Color color, {double width = 1.5}) => Border.all(
        color: color.withOpacity(0.6),
        width: width,
      );
}

// ─── Neon Text Style Helper ───────────────────────────────────────────────────
extension NeonTextStyle on TextStyle {
  TextStyle withNeonGlow(Color color) {
    return copyWith(
      shadows: [
        Shadow(color: color.withOpacity(0.8), blurRadius: 8),
        Shadow(color: color.withOpacity(0.5), blurRadius: 20),
        Shadow(color: color.withOpacity(0.3), blurRadius: 40),
      ],
    );
  }
}
