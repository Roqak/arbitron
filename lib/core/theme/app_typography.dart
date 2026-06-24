import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens. Numeric styles apply [FontFeature.tabularFigures] — see
/// DESIGN.md §3.2. Always prefer these via [TextTheme] from [AppTheme.of].
class AppTypography {
  AppTypography._();

  static TextTheme interTextTheme(Brightness brightness) {
    final base = GoogleFonts.interTextTheme(
      brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
    // Apply tabular figures to styles used for numbers.
    return base.copyWith(
      displayMedium: base.displayMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      headlineSmall: base.headlineSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      titleLarge: base.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      titleMedium: base.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      bodyLarge: base.bodyLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      bodyMedium: base.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      bodySmall: base.bodySmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      labelLarge: base.labelLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      labelMedium: base.labelMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}