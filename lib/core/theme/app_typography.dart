import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dual-typeface system: Inter for prose/labels, JetBrains Mono for all
/// numeric data. See PRODUCT.md — numbers are the hero.
class AppTypography {
  AppTypography._();

  static TextTheme interTextTheme(Brightness brightness) {
    final base = GoogleFonts.interTextTheme(
      brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
    return base;
  }

  /// Monospace text theme for numeric data.
  static TextTheme monoTextTheme(Brightness brightness) {
    return GoogleFonts.jetBrainsMonoTextTheme(
      brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
  }

  /// Returns a mono [TextStyle] for numeric display.
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.4,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}