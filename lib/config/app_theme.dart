import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ─── Dark glassmorphism palette (violet / pink / indigo) ───
  static const Color bg0 = Color(0xFF0A0612);
  static const Color bg1 = Color(0xFF120A20);
  static const Color bg2 = Color(0xFF1A1028);
  static const Color bg3 = Color(0xFF251838);

  // Backwards-compat aliases used across existing screens.
  static const Color bg = bg1;
  static const Color surface = bg2;
  static const Color surface2 = bg3;

  // Glass surface tints.
  static const Color glass = Color(0x0FFFFFFF); // ~0.06 white
  static const Color glassStrong = Color(0x14FFFFFF); // ~0.08 white
  static const Color glassBorder = Color(0x1AFFFFFF); // ~0.10 white
  static const Color glassHi = Color(0x2EFFFFFF); // ~0.18 white
  static const Color line = Color(0x14FFFFFF);

  // Accent — Royal palette (Gold + Violet + Pink), matches design tokens.
  static const Color accentA = Color(0xFFF0B95C); // gold
  static const Color accentB = Color(0xFFA855F7); // violet (primary CTA)
  static const Color accentC = Color(0xFFEC4899); // pink

  // Gold sub-palette — used for the tab-bar pill and warm CTAs.
  static const Color accentGold = Color(0xFFF0B95C);
  static const Color accentGoldBright = Color(0xFFFDE68A);
  static const Color accentAluminum = Color(0xFFB45309);

  // Legacy semantic aliases (kept so older widgets don't break).
  static const Color accentPurple = accentB;
  static const Color accentPink = accentC;
  static const Color accentBlue = accentB;
  static const Color accentGreen = Color(0xFF34D399);
  static const Color accentAmber = Color(0xFFFBBF24);

  // Status colors.
  static const Color good = Color(0xFF34D399);
  static const Color warn = Color(0xFFFBBF24);
  static const Color bad = Color(0xFFF87171);

  // Text.
  static const Color text = Color(0xFFF5F0FF);
  static const Color textSoft = Color(0xB8F5F0FF); // 0.72
  static const Color muted = Color(0x80F5F0FF); // 0.50
  static const Color mutedSoft = Color(0x52F5F0FF); // 0.32

  // Brand gradient — Gold → Violet → Pink (design: Royal accent).
  static const LinearGradient brandGradient = LinearGradient(
    colors: [accentA, accentB, accentC],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradientSoft = LinearGradient(
    colors: [Color(0x33F0B95C), Color(0x22A855F7), Color(0x33EC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Warm gold gradient — design spec: #FDE68A → #F0B95C → #B45309.
  // Used by the tab-bar pill and warm CTAs (captions, music, planner).
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFDE68A), Color(0xFFF0B95C), Color(0xFFB45309)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradientSoft = LinearGradient(
    colors: [Color(0x33F0B95C), Color(0x1AF0B95C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy chart gradients.
  static const LinearGradient aluminumGradient = LinearGradient(
    colors: [Color(0xFF251838), Color(0xFF120A20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient primaryGradient = brandGradient;
  static const LinearGradient blueGradient = LinearGradient(
    colors: [accentB, accentA],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy shadow names; now subtle near-black shadows.
  static const Color shadowDark = Color(0xFF05030A);
  static const Color shadowLight = Color(0x1AFFFFFF);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg1,
      primaryColor: AppColors.accentB,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentB,
        secondary: AppColors.accentA,
        tertiary: AppColors.accentC,
        surface: AppColors.bg2,
      ),
      textTheme: GoogleFonts.cairoTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.text,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            color: AppColors.text,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
          titleLarge: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: AppColors.text, fontSize: 15),
          bodyMedium: TextStyle(color: AppColors.textSoft, fontSize: 13),
          bodySmall: TextStyle(color: AppColors.muted, fontSize: 11),
          labelLarge: TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glass,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.accentB,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
