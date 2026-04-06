import 'package:flutter/material.dart';

/// Dark VMS styling aligned with the visitor entry UI reference.
abstract final class VmsColors {
  static const background = Color(0xFF121212);
  static const card = Color(0xFF1E1E1E);
  static const fieldFill = Color(0xFF2A2A2A);
  static const border = Color(0xFF404040);
  static const tabActiveBlue = Color(0xFF1E88E5);
  static const createGreen = Color(0xFF43A047);
  static const registerMuted = Color(0xFF757575);
}

ThemeData buildVmsDarkTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
  );

  return base.copyWith(
    scaffoldBackgroundColor: VmsColors.background,
    colorScheme: ColorScheme.dark(
      surface: VmsColors.background,
      primary: VmsColors.tabActiveBlue,
      onPrimary: Colors.white,
      secondary: VmsColors.createGreen,
      onSecondary: Colors.white,
      error: Colors.redAccent,
      onSurface: Colors.white,
      outline: VmsColors.border,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: VmsColors.background,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: VmsColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: VmsColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VmsColors.fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: VmsColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: VmsColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: VmsColors.tabActiveBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    ),
    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: VmsColors.border),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return VmsColors.tabActiveBlue;
        }
        return null;
      }),
    ),
  );
}
