import 'package:intl/intl.dart';

/// Centralized formatters for currency, percent, and timestamps.
/// All numeric output uses tabular figures via the text style, not here.
class Fmt {
  Fmt._();

  static String usd(num value, {int decimals = 2}) {
    final sign = value < 0 ? '-' : '';
    final abs = value.abs();
    return '$sign\$${NumberFormat.decimalPatternDigits(locale: 'en_US', decimalDigits: decimals).format(abs)}';
  }

  /// Sign-prefixed USD — for P&L and profit values. Uses Unicode minus.
  static String signedUsd(num value, {int decimals = 2}) {
    final abs = value.abs();
    final prefix = value > 0 ? '+' : (value < 0 ? '\u2212' : '');
    return '$prefix\$${NumberFormat.decimalPatternDigits(locale: 'en_US', decimalDigits: decimals).format(abs)}';
  }

  static String pct(num value, {int decimals = 2}) {
    final sign = value > 0 ? '+' : (value < 0 ? '\u2212' : '');
    return '$sign${value.abs().toStringAsFixed(decimals)}%';
  }

  /// Plain percentage without sign prefix — for spreads and rates.
  static String pctRaw(num value, {int decimals = 2}) => '${value.toStringAsFixed(decimals)}%';

  static String price(num value, {int decimals = 2}) {
    return NumberFormat.decimalPatternDigits(locale: 'en_US', decimalDigits: decimals).format(value);
  }

  static String compactUsd(num value) {
    return '\$${NumberFormat.compactCurrency(locale: 'en_US', symbol: '', decimalDigits: 1).format(value)}';
  }

  static String time(DateTime t) => DateFormat('HH:mm:ss').format(t);
  static String timeShort(DateTime t) => DateFormat('HH:mm').format(t);
  static String date(DateTime t) => DateFormat('MMM d').format(t);
  static String dateTime(DateTime t) => DateFormat('MMM d, HH:mm').format(t);

  /// Relative time ("2s ago", "3m ago", "1h ago", else date).
  static String relative(DateTime t, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = n.difference(t);
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(t);
  }
}