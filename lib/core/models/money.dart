import 'package:intl/intl.dart';

/// An exact amount in minor units (piastres, fils…). Never a double.
class Money {
  const Money(this.minor, {required this.currency, required this.decimals});

  final int minor;
  final String currency;
  final int decimals;

  bool get isZero => minor == 0;

  Money operator +(Money other) => Money(minor + other.minor, currency: currency, decimals: decimals);
  Money operator -(Money other) => Money(minor - other.minor, currency: currency, decimals: decimals);
  Money times(int factor) => Money(minor * factor, currency: currency, decimals: decimals);

  /// "1,250.50" — grouping and digits follow [locale]; no symbol.
  String amount(String locale) {
    final digits = _shownDecimals;
    final format = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = digits
      ..maximumFractionDigits = digits;
    return format.format(_major);
  }

  /// "1,250.50 EGP" (or "1٬250٫50 EGP" in Arabic digits when the locale uses them).
  String format(String locale) => '${amount(locale)} $currency';

  /// Value to send to the server in plans ("1250.50"). Exact, built from integers.
  String toDecimalString() {
    if (decimals == 0) return '$minor';
    final negative = minor < 0;
    final digits = minor.abs().toString().padLeft(decimals + 1, '0');
    final cut = digits.length - decimals;
    return '${negative ? '-' : ''}${digits.substring(0, cut)}.${digits.substring(cut)}';
  }

  /// Parses what a person typed ("1250", "1,250.5", "١٢٥٠٫٥") into minor units.
  /// Returns null when it is not a valid positive amount for [decimals].
  static int? parseMinor(String input, int decimals) {
    var text = input.trim();
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final e = eastern.indexOf(char);
      final p = persian.indexOf(char);
      if (e >= 0) {
        buffer.write(e);
      } else if (p >= 0) {
        buffer.write(p);
      } else if (char == '٫') {
        buffer.write('.');
      } else if (char == ',' || char == '٬' || char == ' ' || char == ' ') {
        continue;
      } else {
        buffer.write(char);
      }
    }
    text = buffer.toString();
    final match = RegExp(r'^(\d{1,15})(?:\.(\d+))?$').firstMatch(text);
    if (match == null) return null;
    final fraction = match.group(2) ?? '';
    if (fraction.length > decimals) return null;
    final whole = int.parse(match.group(1)!);
    final minor = whole * _pow10(decimals) + (fraction.isEmpty ? 0 : int.parse(fraction.padRight(decimals, '0')));
    return minor > 0 ? minor : null;
  }

  int get _shownDecimals => minor % _pow10(decimals) == 0 ? 0 : decimals;
  num get _major => decimals == 0 ? minor : minor / _pow10(decimals);

  static int _pow10(int n) {
    var value = 1;
    for (var i = 0; i < n; i++) {
      value *= 10;
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency && other.decimals == decimals;

  @override
  int get hashCode => Object.hash(minor, currency, decimals);

  @override
  String toString() => '${toDecimalString()} $currency';
}
