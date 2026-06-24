/// Spacing and radius tokens. See DESIGN.md §4.
import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal screen content margin on phones.
  static const double screenH = xl; // 24

  /// Gap between major sections on a scroll view.
  static const double section = xxl; // 32
}

class AppRadius {
  AppRadius._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

extension AppEdgeInsets on Never {
  // Intentionally empty — real helpers below.
}

/// Common EdgeInsets presets used across the app.
class AppPaddings {
  AppPaddings._();
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: AppSpacing.screenH);
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets cardTight = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets listRow = EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm);
  static const EdgeInsets listRowFull = EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm);
}