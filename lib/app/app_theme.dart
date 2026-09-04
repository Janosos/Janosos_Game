import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildJanososTheme() {
  const cyan = Color(0xFF29FFE4);
  const gold = Color(0xFFFFB300);
  const background = Color(0xFF050A10);
  const surface = Color(0xFF0C1420);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: cyan,
    brightness: Brightness.dark,
    surface: surface,
    primary: cyan,
    secondary: gold,
  );

  final baseTextTheme = ThemeData.dark().textTheme;

  final retroTextTheme = baseTextTheme.copyWith(
    displayLarge: GoogleFonts.pressStart2p(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: cyan,
      letterSpacing: 2,
    ),
    displayMedium: GoogleFonts.pressStart2p(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: cyan,
      letterSpacing: 1.5,
    ),
    headlineLarge: GoogleFonts.pressStart2p(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 1.5,
    ),
    headlineMedium: GoogleFonts.pressStart2p(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: cyan,
      letterSpacing: 1.2,
    ),
    headlineSmall: GoogleFonts.pressStart2p(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 1,
    ),
    titleLarge: GoogleFonts.pressStart2p(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 1,
    ),
    titleMedium: GoogleFonts.pressStart2p(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: cyan,
      letterSpacing: 0.8,
    ),
    titleSmall: GoogleFonts.pressStart2p(
      fontSize: 9,
      fontWeight: FontWeight.bold,
      color: Colors.white70,
      letterSpacing: 0.5,
    ),
    bodyLarge: GoogleFonts.vt323(
      fontSize: 20,
      color: const Color(0xFFD4FFEA),
      letterSpacing: 1.2,
    ),
    bodyMedium: GoogleFonts.vt323(
      fontSize: 18,
      color: const Color(0xFFC0D8E8),
      letterSpacing: 1.1,
    ),
    bodySmall: GoogleFonts.vt323(
      fontSize: 16,
      color: const Color(0xFF88A4BE),
      letterSpacing: 1.0,
    ),
    labelLarge: GoogleFonts.pressStart2p(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    ),
    labelMedium: GoogleFonts.pressStart2p(
      fontSize: 8,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    textTheme: retroTextTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF090E17),
      labelStyle: GoogleFonts.pressStart2p(fontSize: 9, color: Colors.white70),
      hintStyle: GoogleFonts.vt323(fontSize: 18, color: Colors.white38),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFF1E354F), width: 2),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFF1E354F), width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: cyan, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: Color(0xFF1E354F), width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: cyan,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.black, width: 2),
        ),
        textStyle: GoogleFonts.pressStart2p(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: cyan,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.black, width: 2),
        ),
        textStyle: GoogleFonts.pressStart2p(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: cyan,
        side: const BorderSide(color: cyan, width: 2),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        textStyle: GoogleFonts.pressStart2p(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    ),
  );
}
