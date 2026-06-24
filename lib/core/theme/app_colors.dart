import 'package:flutter/material.dart';

/// Terminal-native color system for Arbitron v2.
///
/// A tinted blue-black neutral ramp + one electric cyan accent. Semantic
/// colors carry the only other chroma. No gradients, no decorative color.
/// See PRODUCT.md and DESIGN.md.
class AppColors {
  AppColors._();

  // ── Dark theme (default) ───────────────────────────────────────────────────
  // Blue-black ramp, all tinted cool. 5 steps.
  static const Color _dBg = Color(0xFF070A0F);      // deepest — app canvas
  static const Color _dSurface = Color(0xFF0D1117); // panels, list items
  static const Color _dRaised = Color(0xFF151B24);  // inputs, nested surfaces
  static const Color _dBorder = Color(0xFF1E2632);  // hairline dividers
  static const Color _dBorderFoc = Color(0xFF2A3645); // focused inputs

  // Text
  static const Color _dText = Color(0xFFE6EDF3);     // primary
  static const Color _dText2 = Color(0xFF8B95A5);    // secondary
  static const Color _dText3 = Color(0xFF5C6470);    // muted

  // Semantic — dark
  static const Color accent = Color(0xFF00E5CC);      // electric cyan
  static const Color accentDim = Color(0xFF0A2926);
  static const Color success = Color(0xFF00E5CC);     // profit = accent
  static const Color danger = Color(0xFFFF5C7A);      // loss
  static const Color dangerDim = Color(0xFF2A0E14);
  static const Color warning = Color(0xFFFFB547);
  static const Color warningDim = Color(0xFF2A2010);
  static const Color ai = Color(0xFF8B7BFF);          // violet — AI/system
  static const Color aiDim = Color(0xFF1A1628);

  // ── Light theme ─────────────────────────────────────────────────────────────
  static const Color _lBg = Color(0xFFF2F4F8);
  static const Color _lSurface = Color(0xFFFFFFFF);
  static const Color _lRaised = Color(0xFFEBEDF2);
  static const Color _lBorder = Color(0xFFD8DCE3);
  static const Color _lBorderFoc = Color(0xFFB8BFCA);
  static const Color _lText = Color(0xFF0E1116);
  static const Color _lText2 = Color(0xFF4A5260);
  static const Color _lText3 = Color(0xFF8A909C);
  static const Color _lAccent = Color(0xFF00B89A);
  static const Color _lAccentDim = Color(0xFFCDF3EC);
  static const Color _lDanger = Color(0xFFD11D48);
  static const Color _lDangerDim = Color(0xFFFBE2E8);
  static const Color _lWarning = Color(0xFFB86E00);
  static const Color _lWarningDim = Color(0xFFFCEFD4);
  static const Color _lAi = Color(0xFF6B4FDB);
  static const Color _lAiDim = Color(0xFFEBE6FA);

  // Public accessors for theme extension (private fields can't be accessed
  // from outside the class).
  static const Color darkOverlay = Color(0xFF1B2330);
  static const Color lightOverlay = Color(0xFFFFFFFF);
  static const Color lightSuccess = Color(0xFF00B89A);
  static const Color lightAi = Color(0xFF6B4FDB);

  static ColorScheme darkScheme() => const ColorScheme(
        brightness: Brightness.dark,
        primary: accent, onPrimary: _dBg,
        secondary: ai, onSecondary: _dBg,
        error: danger, onError: _dBg,
        surface: _dSurface, onSurface: _dText,
        surfaceContainerLowest: _dBg,
        surfaceContainerLow: _dSurface,
        surfaceContainerHighest: _dRaised,
        surfaceContainer: _dRaised,
        onSurfaceVariant: _dText2,
        outline: _dBorderFoc,
        outlineVariant: _dBorder,
        tertiary: warning, onTertiary: _dBg,
      );

  static ColorScheme lightScheme() => const ColorScheme(
        brightness: Brightness.light,
        primary: _lAccent, onPrimary: Colors.white,
        secondary: _lAi, onSecondary: Colors.white,
        error: _lDanger, onError: Colors.white,
        surface: _lSurface, onSurface: _lText,
        surfaceContainerLowest: _lBg,
        surfaceContainerLow: _lSurface,
        surfaceContainerHighest: _lRaised,
        surfaceContainer: _lRaised,
        onSurfaceVariant: _lText2,
        outline: _lBorderFoc,
        outlineVariant: _lBorder,
        tertiary: _lWarning, onTertiary: Colors.white,
      );

  // Dim backgrounds for chips/badges per brightness.
  static const Map<Brightness, Color> accentDimOf = {Brightness.dark: accentDim, Brightness.light: _lAccentDim};
  static const Map<Brightness, Color> dangerDimOf = {Brightness.dark: dangerDim, Brightness.light: _lDangerDim};
  static const Map<Brightness, Color> warningDimOf = {Brightness.dark: warningDim, Brightness.light: _lWarningDim};
  static const Map<Brightness, Color> aiDimOf = {Brightness.dark: aiDim, Brightness.light: _lAiDim};
  static const Map<Brightness, Color> mutedOf = {Brightness.dark: _dText3, Brightness.light: _lText3};
}