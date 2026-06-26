import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const double borderRadius = 24.0;
  static const double inputBorderRadius = 16.0;
  static const double buttonHeight = 56.0;

  static const Color primary = Color(0xFF186A6F);
  static const Color onPrimary = Colors.white;
  static const Color accent = Color(0xFF186A6F);
  static const Color scaffold = Color(0xFFF5F3F0);
  static const Color surface = Color(0xFFF5F3F0);
  static const Color cardSurface = Color(0xFFF0EEEA);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFFB0AFA8);
  static const Color surfaceBorder = Color(0xFFE8E6E2);
  static const Color inputFill = Color(0xFFEDEBE7);

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        secondary: primary,
        onSecondary: onPrimary,
        surface: scaffold,
        onSurface: onSurface,
        surfaceContainerLowest: scaffold,
        surfaceContainerLow: cardSurface,
        surfaceContainer: cardSurface,
        surfaceContainerHigh: cardSurface,
        surfaceContainerHighest: cardSurface,
        onSurfaceVariant: textSecondary,
        error: const Color(0xFFD32F2F),
        onError: Colors.white,
        outline: surfaceBorder,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'SF Pro Display',
        fontFamilyFallback: ['Helvetica Neue', 'Helvetica', 'Arial', 'sans-serif'],
      ).copyWith(
        displayLarge: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w300,
          color: onSurface,
          height: 1.0,
          letterSpacing: -0.5,
        ),
        displayMedium: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w300,
          color: onSurface,
          height: 1.0,
          letterSpacing: -0.3,
        ),
        displaySmall: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: onSurface,
          height: 1.05,
          letterSpacing: -0.2,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: onSurface,
          height: 1.1,
          letterSpacing: 0.0,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: onSurface,
          height: 1.2,
          letterSpacing: 0.0,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurface,
          height: 1.4,
          letterSpacing: 0.3,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.3,
          letterSpacing: 0.3,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurface,
          height: 1.0,
          letterSpacing: 0.5,
        ),
      ),
      scaffoldBackgroundColor: scaffold,
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: const TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
          fontSize: 15,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 32),
          minimumSize: const Size(0, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonHeight / 2),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: onSurface,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: BorderSide(color: surfaceBorder),
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 32),
          minimumSize: const Size(0, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonHeight / 2),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onSurface,
        actionTextColor: Colors.white,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scaffold,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: onSurface,
          letterSpacing: -0.2,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          color: textSecondary,
          height: 1.5,
          letterSpacing: 0.3,
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      dividerTheme: DividerThemeData(
        color: surfaceBorder,
        thickness: 1,
        space: 1,
      ),
      dividerColor: surfaceBorder,
    );
  }
}
