/// Global Flutter Material 3 theme configuration for AeroX AI.
///
/// Sets up the dark color scheme, Quicksand typography (matching the web
/// platform's `font-family: 'Quicksand'`), input borders, elevation themes,
/// and custom scrollbars.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'aerox_colors.dart';

/// Provides theme data builders matching the AeroX web platform styling.
class AeroXTheme {
  AeroXTheme._();

  /// Display font family matching the web platform's `.font-display` (Caacupe One).
  static const String fontDisplay = 'Caacupe One';

  /// Tech font family matching the web platform's `.font-tech` (Share Tech).
  static const String fontTech = 'Share Tech';

  /// Heading font family matching the web platform's `.font-heading` (Lora).
  static const String fontHeading = 'Lora';

  // ─── Typography Helpers (1:1 Web Font Mappings) ────────────────────

  /// Heading font matching web `.font-heading` (`Lora` serif).
  static TextStyle heading({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AeroXColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.lora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? -0.3,
      height: height ?? 1.3,
    );
  }

  /// Tech / specs font matching web `.font-tech` (`Share Tech`).
  static TextStyle tech({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AeroXColors.textSecondary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.shareTech(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? 0.5,
      height: height ?? 1.2,
    );
  }

  /// Monospace code font matching web `.font-mono` (`JetBrains Mono`).
  static TextStyle mono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AeroXColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height ?? 1.4,
    );
  }

  /// Body font matching web `.font-body` (`Quicksand`).
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AeroXColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.quicksand(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? 0.1,
      height: height ?? 1.5,
    );
  }

  /// Inter font matching web UI `.sidebar` (`Inter`).
  static TextStyle inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AeroXColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? -0.2,
      height: height ?? 1.4,
    );
  }

  /// Display font matching web `.font-display` (`Caacupe One`).
  static TextStyle display({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AeroXColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontDisplay,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? -0.5,
      height: height,
    );
  }

  /// The primary dark theme configuration adhering to the unified design system.
  ///
  /// Typography uses **Quicksand** (the same typeface rendered in the web
  /// platform's CSS `body { font-family: 'Quicksand', ... }`).
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.quicksandTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.quicksand().fontFamily,
      fontFamilyFallback: const ['Segoe UI', 'Arial', 'sans-serif'],
      scaffoldBackgroundColor: AeroXColors.bgPrimary,
      primaryColor: AeroXColors.textPrimary,
      textTheme: baseTextTheme.apply(
        bodyColor: AeroXColors.textPrimary,
        displayColor: AeroXColors.textPrimary,
        fontFamilyFallback: const ['Segoe UI', 'Arial', 'sans-serif'],
      ),
      colorScheme: const ColorScheme.dark(
        primary: AeroXColors.textPrimary,
        onPrimary: AeroXColors.bgPrimary,
        surface: AeroXColors.bgSecondary,
        onSurface: AeroXColors.textPrimary,
        error: AeroXColors.error,
        onError: AeroXColors.bgPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AeroXColors.bgPrimary,
        foregroundColor: AeroXColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AeroXColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AeroXColors.borderPrimary, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AeroXColors.bgElevated,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AeroXColors.borderPrimary, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AeroXColors.bgInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(color: AeroXColors.textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AeroXColors.borderPrimary, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AeroXColors.borderPrimary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AeroXColors.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AeroXColors.error, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AeroXColors.borderPrimary,
        thickness: 1,
        space: 1,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AeroXColors.borderPrimary),
        radius: const Radius.circular(3),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }
}
