import 'package:flutter/material.dart';

/// Spacing and radius tokens. Terminal-native — tighter, denser.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double xxxl = 40;

  static const double screenH = xl; // 20 — tighter than 24
  static const double section = xxl; // 28
}

class AppRadius {
  AppRadius._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;
  static const double pill = 999;
}

class AppPaddings {
  AppPaddings._();
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: AppSpacing.screenH);
  static const EdgeInsets panel = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets panelTight = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets row = EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm);
}