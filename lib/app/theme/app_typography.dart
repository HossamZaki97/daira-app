import 'package:flutter/material.dart';

abstract final class AppTypography {
  /// Bundled locally under assets/fonts; no network font is used.
  static const cairoFamily = 'Cairo';

  static TextTheme textTheme(Color textColor) => TextTheme(
    displayLarge: TextStyle(
      fontSize: 48,
      height: 1.18,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    displayMedium: TextStyle(
      fontSize: 40,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    displaySmall: TextStyle(
      fontSize: 34,
      height: 1.22,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    headlineLarge: TextStyle(
      fontSize: 30,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      height: 1.35,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.4,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.6,
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.6,
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 1.55,
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
  ).apply(fontFamily: cairoFamily);
}
