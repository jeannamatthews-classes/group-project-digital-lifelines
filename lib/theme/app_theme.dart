import 'package:flutter/material.dart';

class ThemeConstants {
  static const double borderRadius = 16.0;
  static const double padding = 24.0;
  
  // Brand Template Colors
  static const Color brandPrimary = Color(0xFF2563EB);   // Deep Blue
  static const Color brandSecondary = Color(0xFF7C3AED); // Purple
  static const Color brandAccent = Color(0xFF22C55E);    // Fresh Green
  
  // Light Mode Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  
  // Dark Mode Colors
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color backgroundDark = Color(0xFF0F172A); // Dark Navy
  static const Color surfaceDark = Color(0xFF1E293B);
  
  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [brandPrimary, brandSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Backward compatibility for existing codebase
class AppColors {
  static const Color primary = ThemeConstants.brandPrimary;
  static const Color primaryDark = ThemeConstants.textPrimaryDark;
  static const Color accent = ThemeConstants.brandAccent;
  static const Color background = ThemeConstants.backgroundLight;
  static const Color appBarText = ThemeConstants.textPrimaryLight;
  static const Color mutedText = ThemeConstants.textSecondaryLight;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: ThemeConstants.brandPrimary,
      scaffoldBackgroundColor: ThemeConstants.backgroundLight,
      useMaterial3: true,
      fontFamily: 'SF Pro Display', // Substitute a local system font or add to pubspec
      colorScheme: const ColorScheme.light(
        primary: ThemeConstants.brandPrimary,
        secondary: ThemeConstants.brandSecondary,
        surface: ThemeConstants.surfaceLight,
      ),
      cardTheme: CardThemeData(
        color: ThemeConstants.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeConstants.borderRadius)),
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: ThemeConstants.brandPrimary,
      scaffoldBackgroundColor: ThemeConstants.backgroundDark,
      useMaterial3: true,
      fontFamily: 'SF Pro Display', // Substitute a local system font or add to pubspec
      colorScheme: const ColorScheme.dark(
        primary: ThemeConstants.brandPrimary,
        secondary: ThemeConstants.brandSecondary,
        surface: ThemeConstants.surfaceDark,
      ),
      cardTheme: CardThemeData(
        color: ThemeConstants.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeConstants.borderRadius)),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
