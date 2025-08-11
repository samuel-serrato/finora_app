import 'package:finora_app/constants/colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // Crear tema claro
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light().copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.accent,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFE0E0E0),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF212121)),
        bodyMedium: TextStyle(color: Color(0xFF212121)),
        titleLarge: TextStyle(color: Color(0xFF212121)),
      ),
    );
  }

  // Crear tema oscuro
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark().copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.accent,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      dividerColor: const Color(0xFF424242),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFEEEEEE)),
        bodyMedium: TextStyle(color: Color(0xFFEEEEEE)),
        titleLarge: TextStyle(color: Color(0xFFEEEEEE)),
      ),
    );
  }
}