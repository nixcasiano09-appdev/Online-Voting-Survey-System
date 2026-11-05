import 'package:flutter/material.dart';

class AppTheme {
  static const navy = Color(0xFF172033);
  static const blue = Color(0xFF2684FF);
  static const paleBlue = Color(0xFFDCEAFF);
  static const background = Color(0xFFF2F8FF);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      primary: blue,
      surface: Colors.white,
      error: const Color(0xFFD64545),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: navy,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: navy,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFDDE9F7)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD7E4F3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD7E4F3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: navy,
          fontWeight: FontWeight.w800,
          fontSize: 23,
        ),
        titleLarge: TextStyle(
          color: navy,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          color: navy,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(color: Color(0xFF586579), height: 1.45),
      ),
    );
  }
}
