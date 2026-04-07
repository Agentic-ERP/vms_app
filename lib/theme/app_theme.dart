import 'package:flutter/material.dart';

/// Line-O-Matic brand + light surfaces (aligned with lineomatic.com).
abstract final class VmsColors {
  /// Primary brand cyan from client site.
  static const primaryCyan = Color(0xFF00AEEF);

  static const background = Color(0xFFFFFFFF);
  static const card = Color(0xFFF5FAFC);
  static const fieldFill = Color(0xFFEEF6FA);
  static const border = Color(0xFFC5D9E8);

  /// Same as [primaryCyan]; kept for existing call sites (tabs, OTP button).
  static const tabActiveBlue = primaryCyan;

  /// Success / check-out accent (readable on white).
  static const createGreen = Color(0xFF2E7D32);

  static const registerMuted = Color(0xFF546E7A);

  static const onSurfaceMuted = Color(0xFF607D8B);

  /// Main headings/body on light backgrounds.
  static const onSurface = Color(0xFF263238);
}

/// Asset bundled from https://www.lineomatic.com/assets/images/Line-O-Matic.png
const String kLineOMaticLogoAsset = 'assets/images/line_o_matic_logo.png';

ThemeData buildVmsTheme() {
  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
  );

  const scheme = ColorScheme.light(
    primary: VmsColors.primaryCyan,
    onPrimary: Colors.white,
    secondary: VmsColors.createGreen,
    onSecondary: Colors.white,
    surface: VmsColors.background,
    onSurface: VmsColors.onSurface,
    onSurfaceVariant: VmsColors.onSurfaceMuted,
    surfaceContainerHighest: VmsColors.fieldFill,
    error: Color(0xFFC62828),
    onError: Colors.white,
    outline: VmsColors.border,
    outlineVariant: Color(0xFFDCE8F0),
  );

  return base.copyWith(
    scaffoldBackgroundColor: VmsColors.background,
    colorScheme: scheme,
    textTheme: base.textTheme.apply(
      bodyColor: VmsColors.onSurface,
      displayColor: VmsColors.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: VmsColors.background,
      foregroundColor: VmsColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: VmsColors.primaryCyan.withValues(alpha: 0.08),
      centerTitle: false,
    ),
    dividerTheme: const DividerThemeData(
      color: VmsColors.border,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: VmsColors.card,
      elevation: 1,
      shadowColor: const Color(0x3300AEEF),
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
        borderSide: const BorderSide(color: VmsColors.primaryCyan, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: VmsColors.onSurfaceMuted),
      labelStyle: const TextStyle(color: VmsColors.onSurfaceMuted),
    ),
    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: VmsColors.border),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return VmsColors.primaryCyan;
        }
        return null;
      }),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: VmsColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: VmsColors.border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF37474F),
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: VmsColors.primaryCyan,
        foregroundColor: Colors.white,
      ),
    ),
  );
}

@Deprecated('Use buildVmsTheme()')
ThemeData buildVmsDarkTheme() => buildVmsTheme();
