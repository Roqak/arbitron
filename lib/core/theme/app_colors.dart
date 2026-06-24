import 'package:flutter/material.dart';

/// Semantic color tokens for Arbitron.
///
/// Never reference raw hex values in feature code. Always use these tokens or
/// the [AppTheme] / [ColorScheme] they feed. See DESIGN.md §2.
class AppColors {
  AppColors._();

  // ── Dark theme ────────────────────────────────────────────────────────────
  static const Color _darkBackground = Color(0xFF0A0E14);
  static const Color _darkSurface = Color(0xFF121821);
  static const Color _darkSurfaceRaised = Color(0xFF1A2330);
  static const Color _darkBorderSubtle = Color(0xFF1F2937);
  static const Color _darkBorderStrong = Color(0xFF2D3A4F);
  static const Color _darkTextPrimary = Color(0xFFF1F5F9);
  static const Color _darkTextSecondary = Color(0xFF94A3B8);
  static const Color _darkTextMuted = Color(0xFF64748B);
  static const Color accent = Color(0xFF34F5A0);
  static const Color accentDim = Color(0xFF0F3D2E);
  static const Color success = Color(0xFF34F5A0);
  static const Color danger = Color(0xFFFF5470);
  static const Color dangerDim = Color(0xFF3D0F1A);
  static const Color warning = Color(0xFFFFB547);
  static const Color warningDim = Color(0xFF3D2E0F);
  static const Color info = Color(0xFF5B9DFF);
  static const Color infoDim = Color(0xFF0F2A3D);

  // ── Light theme ───────────────────────────────────────────────────────────
  static const Color _lightBackground = Color(0xFFF7F9FC);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceRaised = Color(0xFFF1F5F9);
  static const Color _lightBorderSubtle = Color(0xFFE2E8F0);
  static const Color _lightBorderStrong = Color(0xFFCBD5E1);
  static const Color _lightTextPrimary = Color(0xFF0F172A);
  static const Color _lightTextSecondary = Color(0xFF475569);
  static const Color _lightTextMuted = Color(0xFF94A3B8);
  static const Color _lightAccent = Color(0xFF0FB372);
  static const Color _lightAccentDim = Color(0xFFD6F5E8);
  static const Color _lightDanger = Color(0xFFE11D48);
  static const Color _lightDangerDim = Color(0xFFFCE7ED);
  static const Color _lightWarning = Color(0xFFD97706);
  static const Color _lightWarningDim = Color(0xFFFEF3C7);
  static const Color _lightInfo = Color(0xFF2563EB);
  static const Color _lightInfoDim = Color(0xFFDBEAFE);

  /// Builds the dark [ColorScheme]. Custom slots are stashed on `surface*` and
  /// `outline*` fields; see [AppTheme.of] for the ergonomic accessors.
  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: accent,
      onPrimary: _darkBackground,
      secondary: info,
      onSecondary: _darkBackground,
      error: danger,
      onError: _darkBackground,
      surface: _darkSurface,
      onSurface: _darkTextPrimary,
      // Extended semantic slots (not part of Material's base contract but
      // honoured by [AppTheme.of]).
      surfaceContainerLowest: _darkBackground,
      surfaceContainerLow: _darkSurface,
      surfaceContainerHighest: _darkSurfaceRaised,
      surfaceContainer: _darkSurfaceRaised,
      onSurfaceVariant: _darkTextSecondary,
      outline: _darkBorderStrong,
      outlineVariant: _darkBorderSubtle,
      tertiary: warning,
      onTertiary: _darkBackground,
    );
  }

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: _lightAccent,
      onPrimary: Colors.white,
      secondary: _lightInfo,
      onSecondary: Colors.white,
      error: _lightDanger,
      onError: Colors.white,
      surface: _lightSurface,
      onSurface: _lightTextPrimary,
      surfaceContainerLowest: _lightBackground,
      surfaceContainerLow: _lightSurface,
      surfaceContainerHighest: _lightSurfaceRaised,
      surfaceContainer: _lightSurfaceRaised,
      onSurfaceVariant: _lightTextSecondary,
      outline: _lightBorderStrong,
      outlineVariant: _lightBorderSubtle,
      tertiary: _lightWarning,
      onTertiary: Colors.white,
    );
  }

  // Convenience accessors for the dim backgrounds used by chips/badges.
  static const Map<Brightness, Color> accentDimByBrightness = {
    Brightness.dark: accentDim,
    Brightness.light: _lightAccentDim,
  };
  static const Map<Brightness, Color> dangerDimByBrightness = {
    Brightness.dark: dangerDim,
    Brightness.light: _lightDangerDim,
  };
  static const Map<Brightness, Color> warningDimByBrightness = {
    Brightness.dark: warningDim,
    Brightness.light: _lightWarningDim,
  };
  static const Map<Brightness, Color> infoDimByBrightness = {
    Brightness.dark: infoDim,
    Brightness.light: _lightInfoDim,
  };
  static const Map<Brightness, Color> mutedByBrightness = {
    Brightness.dark: _darkTextMuted,
    Brightness.light: _lightTextMuted,
  };
}