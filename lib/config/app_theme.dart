import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color bg = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF13131A);
  static const Color surface2 = Color(0xFF1A1A24);
  static const Color accentPurple = Color(0xFFC77DFF);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentBlue = Color(0xFF48CAE4);
  static const Color accentGreen = Color(0xFF06D6A0);
  static const Color accentAmber = Color(0xFFFFB703);
  static const Color text = Color(0xFFF0F0FF);
  static const Color muted = Color(0xFF8888AA);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentPurple, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [accentBlue, accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.accentPurple,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPurple,
        secondary: AppColors.accentPink,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.cairoTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.text,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppColors.text,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: AppColors.text, fontSize: 16),
          bodyMedium: TextStyle(color: AppColors.text, fontSize: 14),
          bodySmall: TextStyle(color: AppColors.muted, fontSize: 12),
          labelLarge: TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accentPurple,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
