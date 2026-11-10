import 'package:flutter/material.dart';

class AppTheme {
  // Movie Explorer Dribbble & HTML Spec Renk Paleti
  static const Color primaryColor = Color(0xFFF5A623); // Amber / Altın Sarısı
  static const Color primaryGradientStart = Color(0xFFFFC04D);
  static const Color primaryGradientEnd = Color(0xFFF5A623);
  static const Color accentColor = Color(0xFFFF9500);  // Canlı Turuncu
  static const Color starColor = Color(0xFFF5A623);    // 5 Yıldız Amber Rengi
  static const Color darkText = Color(0xFF111111);     // Ana Başlık Metni (#111)
  static const Color mutedText = Color(0xFF6B6F7B);    // Gri Alt Metin (.g: #6B6F7B)
  static const Color lightBg = Color(0xFFFFFFFF);      // Saf Beyaz Zemin
  static const Color lightCardBg = Color(0xFFFFFFFF);  // Beyaz Kart Zemin
  static const Color borderColor = Color(0xFFE6E7EC);  // Kart & Divider Sınırı (.card, .nav: #E6E7EC)
  static const Color inputBorderColor = Color(0xFFD9DBE3); // Giriş & Pill Sınırı (.in, .pill: #D9DBE3)
  static const Color placeholderColor = Color(0xFFF0F1F5); // Skeleton / Görsel Dolgu (.ph: #F0F1F5)
  static const Color mediaCardBg = Color(0xFFF7F8FA);  // Feed içi film kartı zemini

  // Badge Renkleri (.html spec)
  static const Color quoteBadgeBg = Color(0xFFFFF1D6);
  static const Color quoteBadgeText = Color(0xFF9A5B00);
  static const Color reviewBadgeBg = Color(0xFFDDF3E7);
  static const Color reviewBadgeText = Color(0xFF17663F);
  static const Color reviewAvatarBg = Color(0xFF2E9E6B);

  // Karanlık Mod (Dark Cinema Minimal)
  static const Color darkBg = Color(0xFF0F1015);
  static const Color darkCard = Color(0xFF181A22);
  static const Color darkCardBorder = Color(0xFF262936);
  static const Color darkInputBg = Color(0xFF14151C);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: lightCardBg,
      surfaceContainerHighest: mediaCardBg,
      onSurface: darkText,
    ),
    scaffoldBackgroundColor: lightBg,
    cardTheme: CardThemeData(
      color: lightCardBg,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: darkText,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: darkText, size: 22),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightBg,
      selectedItemColor: primaryColor,
      unselectedItemColor: mutedText,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: inputBorderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: inputBorderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      hintStyle: const TextStyle(color: mutedText, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
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
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkCardBorder, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: Colors.white, size: 22),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkCard,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.white54,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkInputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkCardBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkCardBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
  );
}
