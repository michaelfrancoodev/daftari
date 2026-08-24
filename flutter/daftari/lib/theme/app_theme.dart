import "package:flutter/material.dart";
import "tokens.dart";

/// Builds the DAFTARI Material theme from design tokens.
/// Navy + off-white ivory + one gold accent, generous touch targets,
/// large legible type for low-literacy, bright-daylight shop conditions.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AppColor.ink,
      onPrimary: AppColor.surface,
      secondary: AppColor.gold,
      onSecondary: AppColor.ink,
      error: AppColor.danger,
      onError: AppColor.surface,
      surface: AppColor.surface,
      onSurface: AppColor.ink,
      surfaceTint: AppColor.ink,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColor.surface,
      fontFamily: "Inter",
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColor.ink,
        displayColor: AppColor.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColor.surface,
        foregroundColor: AppColor.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColor.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: const BorderSide(color: AppColor.line, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColor.line, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.ink,
          foregroundColor: AppColor.surface,
          minimumSize: const Size.fromHeight(Touch.min),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.ink,
          minimumSize: const Size.fromHeight(Touch.min),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          side: const BorderSide(color: AppColor.line, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.ink,
          minimumSize: const Size(0, Touch.min),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: AppColor.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: AppColor.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: AppColor.ink, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColor.ink,
        contentTextStyle: const TextStyle(color: AppColor.surface, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColor.surface,
        selectedItemColor: AppColor.ink,
        unselectedItemColor: AppColor.inkMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
