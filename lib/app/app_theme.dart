import 'package:flutter/material.dart';

ThemeData buildJanososTheme() {
  const cyan = Color(0xFF29FFE4);
  const background = Color(0xFF050A10);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: cyan,
    brightness: Brightness.dark,
    surface: const Color(0xFF0F1722),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    fontFamily: 'Courier',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF111B28),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: cyan, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF0F1722),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF26384A)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
      ),
    ),
  );
}
