import 'package:flutter/material.dart';

/// Cairo type scale. Amounts, dates and counters always use tabular figures so
/// columns of numbers line up.
abstract final class DairaType {
  static const family = 'Cairo';
  static const _tabular = [FontFeature.tabularFigures()];

  static const display = TextStyle(fontFamily: family, fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w700);
  static const title = TextStyle(fontFamily: family, fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w700);
  static const heading = TextStyle(fontFamily: family, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w700);
  static const body = TextStyle(fontFamily: family, fontSize: 14, height: 22 / 14, fontWeight: FontWeight.w400);
  static const label = TextStyle(fontFamily: family, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w600);
  static const caption = TextStyle(fontFamily: family, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w400);
  static const amountL = TextStyle(
    fontFamily: family,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );
  static const amountM = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );
  static const numeric = TextStyle(fontFeatures: _tabular);

  static TextTheme textTheme(Color text, Color muted) => TextTheme(
    displaySmall: display.copyWith(color: text),
    headlineSmall: title.copyWith(color: text),
    titleLarge: title.copyWith(color: text),
    titleMedium: heading.copyWith(color: text),
    titleSmall: label.copyWith(color: text),
    bodyLarge: body.copyWith(fontSize: 15, color: text),
    bodyMedium: body.copyWith(color: text),
    bodySmall: caption.copyWith(color: muted),
    labelLarge: label.copyWith(fontSize: 14, color: text),
    labelMedium: label.copyWith(color: text),
    labelSmall: caption.copyWith(fontWeight: FontWeight.w600, color: muted),
  );
}
