// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

/// The whole app uses three colors:
///   1. a dark neutral (bg / surface / border / text shades),
///   2. one accent (mint) for everything positive and interactive,
///   3. one alert color (coral) for mistakes and low time.
class AppColors {
  AppColors._();

  // Neutral
  static const Color bg = Color(0xFF0E1013);
  static const Color surface = Color(0xFF161A1F);
  static const Color surfaceHigh = Color(0xFF1E232A);
  static const Color border = Color(0xFF2A3038);
  static const Color text = Color(0xFFF3F5F7);
  static const Color textDim = Color(0xFFA0A8B3);
  static const Color textMuted = Color(0xFF6C7580);

  // Accent
  static const Color accent = Color(0xFF5EEAD4);

  // Alert
  static const Color danger = Color(0xFFFF7A7A);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.bg,
      secondary: AppColors.accent,
      onSecondary: AppColors.bg,
      error: AppColors.danger,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: scheme,
      dividerColor: AppColors.border,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.text),
        bodyMedium: TextStyle(color: AppColors.textDim),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.bg
              : AppColors.textDim,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.surfaceHigh,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
