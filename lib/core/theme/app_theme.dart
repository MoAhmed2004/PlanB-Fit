import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// PlanB Fit — Premium Design System v2.0
///
/// Palette:
///   Background  → Deep space black (#08080F)
///   Surface     → Elevated dark (#12121E)
///   Card        → Glassmorphic dark (#181828)
///   Primary     → Neon Mint (#00F5A0) — success, CTA, XP
///   Secondary   → Electric Violet (#7C4DFF) — Plan B, AI actions
///   Tertiary    → Flame Orange (#FF6B35) — XP streaks, energy
///   Accent Gold → (#FFD700) — premium highlights
///
/// Typography:
///   Display/Headings → Orbitron (futuristic machine voice)
///   Body/UI          → Poppins (modern, geometric, premium readability)
///
/// Effects:
///   Glassmorphism, neon glows, gradient borders, animated shimmer
/// ═══════════════════════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._();

  // ── Core Color Tokens ─────────────────────────────────────────────────────
  static const Color background    = Color(0xFF08080F);
  static const Color surface       = Color(0xFF12121E);
  static const Color cardColor     = Color(0xFF181828);
  static const Color divider       = Color(0xFF2A2A3C);

  static const Color accentGreen   = Color(0xFF00F5A0);
  static const Color accentPurple  = Color(0xFF7C4DFF);
  static const Color accentOrange  = Color(0xFFFF6B35);
  static const Color accentGold    = Color(0xFFFFD700);
  static const Color errorColor    = Color(0xFFFF4757);

  static const Color textPrimary   = Color(0xFFF8F8FF);
  static const Color textSecondary = Color(0xFF9A9AB0);
  static const Color textMuted     = Color(0xFF4E4E62);

  // ── Premium Gradients ─────────────────────────────────────────────────────
  static const LinearGradient planBGradient = LinearGradient(
    colors: [accentPurple, accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF00F5A0), Color(0xFF00D4AA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E35), Color(0xFF12121E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient xpGradient = LinearGradient(
    colors: [accentOrange, Color(0xFFFFD93D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkFadeGradient = LinearGradient(
    colors: [Colors.transparent, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Neon Glow Shadows ─────────────────────────────────────────────────────
  static List<BoxShadow> neonGreenGlow({double intensity = 0.5}) => [
    BoxShadow(
      color: accentGreen.withOpacity(intensity * 0.6),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: accentGreen.withOpacity(intensity * 0.3),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];

  static List<BoxShadow> neonPurpleGlow({double intensity = 0.4}) => [
    BoxShadow(
      color: accentPurple.withOpacity(intensity * 0.6),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: accentPurple.withOpacity(intensity * 0.3),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];

  static List<BoxShadow> neonOrangeGlow({double intensity = 0.4}) => [
    BoxShadow(
      color: accentOrange.withOpacity(intensity * 0.6),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: accentOrange.withOpacity(intensity * 0.3),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];

  // ── Glassmorphism Decoration ──────────────────────────────────────────────
  static BoxDecoration glassDecoration({
    double opacity = 0.08,
    double borderOpacity = 0.12,
    double radius = 20,
    Color? borderColor,
  }) =>
      BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: (borderColor ?? Colors.white).withOpacity(borderOpacity),
          width: 1,
        ),
      );

  static BoxDecoration premiumCardDecoration({
    Color? glowColor,
    double glowIntensity = 0.15,
  }) =>
      BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: divider, width: 1),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(glowIntensity),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      );

  // ── Border Radius Presets ─────────────────────────────────────────────────
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  // ── Spacing Presets ───────────────────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacing2Xl = 48;

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accentGreen,
        secondary: accentPurple,
        tertiary: accentOrange,
        error: errorColor,
        onSurface: textPrimary,
        onPrimary: Color(0xFF08080F),
        onSecondary: textPrimary,
      ),
      scaffoldBackgroundColor: background,

      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        // Display — Orbitron for that futuristic machine voice
        displayLarge: GoogleFonts.orbitron(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: textPrimary,
          letterSpacing: 2,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1.5,
          height: 1.15,
        ),
        displaySmall: GoogleFonts.orbitron(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.orbitron(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.orbitron(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.3,
          height: 1.3,
        ),
        // Body — Poppins for modern premium readability
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: textPrimary,
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: textSecondary,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: textMuted,
          height: 1.4,
        ),
        // Labels — Poppins semibold
        labelLarge: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 0.3,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 1,
        ),
      ),

      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: const Color(0xFF08080F),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
          elevation: 0,
          shadowColor: accentGreen.withOpacity(0.3),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentGreen,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: accentGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: GoogleFonts.poppins(color: textMuted, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: textSecondary, fontSize: 14),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: accentGreen.withOpacity(0.15),
        disabledColor: surface,
        side: const BorderSide(color: divider),
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),

      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: divider,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
        behavior: SnackBarBehavior.floating,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentPurple,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentGreen,
        linearTrackColor: divider,
      ),
    );
  }
}
