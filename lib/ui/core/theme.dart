import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const double borderRadius = 20.0;
  static const double inputBorderRadius = 16.0;

  static const Color primary = Color(0xFF186A6F);
  static const Color onPrimary = Colors.white;
  static const Color secondary = Color(0xFFD4815A);
  static const Color onSecondary = Colors.white;
  static const Color scaffold = Colors.white;
  static const Color surface = Colors.white;
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color cardBorder = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color inputFill = Color(0xFFF5F5F5);

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: onSecondary,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF8F8F8),
        surfaceContainer: const Color(0xFFF2F2F2),
        surfaceContainerHigh: const Color(0xFFEBEBEB),
        surfaceContainerHighest: const Color(0xFFE0E0E0),
        onSurfaceVariant: textSecondary,
        error: const Color(0xFFD32F2F),
        onError: Colors.white,
      ),
      textTheme: base.textTheme.apply().copyWith(
        displayLarge: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: onSurface,
        ),
        displayMedium: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: onSurface,
        ),
        displaySmall: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: onSurface,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: onSurface,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
      ),
      scaffoldBackgroundColor: scaffold,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        hintStyle: TextStyle(
          color: textSecondary.withValues(alpha: 0.6),
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(inputBorderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(8),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(inputBorderRadius),
              side: BorderSide(color: cardBorder, width: 1),
            ),
          ),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputFill,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(inputBorderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(inputBorderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(inputBorderRadius),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 14, color: onSurface),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primary,
        actionTextColor: Colors.white,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          color: textSecondary,
          height: 1.5,
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }
}
