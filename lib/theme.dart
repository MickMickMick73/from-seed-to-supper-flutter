import 'package:flutter/material.dart';

class FstsColors {
  static const forest = Color(0xFF1F3D2E);
  static const forestDeep = Color(0xFF0F1F17);
  static const sage = Color(0xFF3E6B4E);
  static const cream = Color(0xFFF7F3EA);
  static const ochre = Color(0xFFD9C68A);
  static const muted = Color(0xFFA8B5A8);
  static const card = Color(0xE61A2E24);
}

ThemeData fstsTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: FstsColors.ochre,
      onPrimary: FstsColors.forestDeep,
      secondary: FstsColors.sage,
      surface: FstsColors.card,
      onSurface: FstsColors.cream,
    ),
    scaffoldBackgroundColor: FstsColors.forestDeep,
    fontFamily: 'Roboto',
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: FstsColors.cream,
      displayColor: FstsColors.cream,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xCC0F1F17),
      foregroundColor: FstsColors.cream,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x331A2E24),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(color: FstsColors.muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FstsColors.ochre,
        foregroundColor: FstsColors.forestDeep,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
