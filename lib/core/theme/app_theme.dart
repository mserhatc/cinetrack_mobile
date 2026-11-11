import 'package:flutter/material.dart';

class AppTheme {
  // Yeni Modern Sinema Uygulaması Tasarım Renk Paleti (PDF Tasarımları)
  static const Color primaryColor = Color(0xFFF5A623);
  static const Color primaryGradientStart = Color(0xFFFBBF24);
  static const Color primaryGradientEnd = Color(0xFFF59E0B);
  static const Color accentColor = Color(0xFFEA580C);
  static const Color starColor = Color(0xFFF5A623);

  static const Color darkText = Color(0xFF141619);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color softGreyBg = Color(0xFFF3F4F6);
  static const Color mediaCardBg = Color(0xFFF7F8FA);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color inputBorderColor = Color(0xFFE5E7EB);
  static const Color placeholderColor = Color(0xFFF3F4F6);

  // Floating Pill Bottom Navigation Bar Rengi
  static const Color floatingNavBg = Color(0xFF1E2025);
  static const Color floatingNavInactive = Color(0xFF9CA3AF);

  // Badge Renkleri (Page 3 - Feed)
  static const Color quoteBadgeBg = Color(0xFFFFF3DB);
  static const Color quoteBadgeText = Color(0xFFB86E00);
  static const Color reviewBadgeBg = Color(0xFFE1F6EC);
  static const Color reviewBadgeText = Color(0xFF16794B);
  static const Color reviewAvatarBg = Color(0xFF0FA4B8);
  static const Color quoteAvatarBg = Color(0xFFEA7626);
  static const Color heartRed = Color(0xFFE5484D);

  // Karanlık Mod
  static const Color darkBg = Color(0xFF0F1115);
  static const Color darkCard = Color(0xFF181B22);
  static const Color darkCardBorder = Color(0xFF262A36);
  static const Color darkInputBg = Color(0xFF1E222B);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: lightCardBg,
      surfaceContainerHighest: softGreyBg,
      onSurface: darkText,
    ),
    scaffoldBackgroundColor: lightBg,
    cardTheme: CardThemeData(
      color: lightCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFF1F2F6), width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: darkText,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: darkText, size: 22),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: softGreyBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: darkCard,
      surfaceContainerHighest: darkCardBorder,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: darkBg,
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: darkCardBorder, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: Colors.white, size: 22),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkInputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );
}
