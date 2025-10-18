import 'package:flutter/material.dart';

class AppColors {
  // Primary Purple Colors
  static const Color primaryPurple = Color(0xFF8E08EF);      // Main purple
  static const Color secondaryPurple = Color(0xFFA855F7);    // Lighter purple for accents
  static const Color darkPurple = Color(0xFF6B21A8);         // Darker purple
  static const Color lightPurple = Color(0xFFE9D5FF);        // Very light purple for backgrounds

  // Gradient Colors
  static const Color purpleAccent = Color(0xFFDDD6FE);       // Purple accent
  static const Color deepPurple = Color(0xFF7C3AED);         // Deep purple

  // Status Colors
  static const Color success = Color(0xFF8E08EF);            // Success messages
  static const Color warning = Color(0xFFF59E0B);            // Warning messages
  static const Color error = Color(0xFFEF4444);              // Error messages

  // Background Colors
  static const Color backgroundDark = Color(0xFF0F0F0F);     // Dark background
  static const Color backgroundLight = Color(0xFFF8FAFC);    // Light background
  static const Color cardBackground = Color(0xFF1A1A1A);     // Card background

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);        // Primary text
  static const Color textSecondary = Color(0xFF9CA3AF);      // Secondary text
  static const Color textTertiary = Color(0xFF6B7280);       // Tertiary text

  // Border Colors
  static const Color borderLight = Color(0xFFE5E7EB);        // Light borders
  static const Color borderDark = Color(0xFF374151);         // Dark borders

  // Purple Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, secondaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [darkPurple, primaryPurple],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Purple Theme Data
  static ThemeData get purpleTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        brightness: Brightness.dark,
        primary: primaryPurple,
        secondary: secondaryPurple,
        surface: backgroundDark,
        background: backgroundDark,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPurple,
          side: const BorderSide(color: primaryPurple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundDark,
        selectedItemColor: primaryPurple,
        unselectedItemColor: textSecondary,
      ),
    );
  }

  // Helper methods for opacity variations
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Purple with opacity variations
  static Color primaryPurpleWithOpacity(double opacity) {
    return primaryPurple.withOpacity(opacity);
  }

  static Color secondaryPurpleWithOpacity(double opacity) {
    return secondaryPurple.withOpacity(opacity);
  }
}
