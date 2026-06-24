import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Terminal-native theme. See PRODUCT.md and DESIGN.md.
class AppTheme {
  AppTheme._();

  static ThemeData of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark() : light();
  }

  static ThemeData dark() => _build(AppColors.darkScheme(), Brightness.dark);
  static ThemeData light() => _build(AppColors.lightScheme(), Brightness.light);

  static ThemeData _build(ColorScheme s, Brightness b) {
    final isDark = b == Brightness.dark;
    final text = AppTypography.interTextTheme(b);
    final mono = AppTypography.monoTextTheme(b);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: s,
      scaffoldBackgroundColor: s.surfaceContainerLowest,
      canvasColor: s.surfaceContainerLowest,
      textTheme: text,
      fontFamily: text.bodyLarge?.fontFamily,
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: s.onSurface,
        elevation: 0, scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.screenH,
        titleTextStyle: text.headlineSmall?.copyWith(color: s.onSurface, fontWeight: FontWeight.w600),
      ),

      cardTheme: CardTheme(
        color: s.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm), side: BorderSide(color: s.outlineVariant, width: 1)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surfaceContainerHighest,
        hintStyle: TextStyle(color: s.onSurfaceVariant.withOpacity(0.5)),
        labelStyle: TextStyle(color: s.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: s.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide(color: s.outlineVariant, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide(color: s.outlineVariant, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide(color: s.outline, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide(color: s.error, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide(color: s.error, width: 1.5)),
      ),

      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: s.primary, foregroundColor: s.onPrimary,
        minimumSize: const Size(0, 46), padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        textStyle: text.labelLarge, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: s.primary, foregroundColor: s.onPrimary,
        minimumSize: const Size(0, 46), elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        textStyle: text.labelLarge, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: s.onSurface, minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        textStyle: text.labelLarge, side: BorderSide(color: s.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      )),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
        foregroundColor: s.onSurfaceVariant, minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        textStyle: text.labelLarge, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      )),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: s.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return mono.labelSmall!.copyWith(
            color: sel ? s.primary : s.onSurfaceVariant,
            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(color: sel ? s.primary : s.onSurfaceVariant, size: 22);
        }),
        height: 60,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      dividerTheme: DividerThemeData(color: s.outlineVariant, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: s.onSurfaceVariant, size: 22),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkOverlay : AppColors.lightOverlay,
        surfaceTintColor: Colors.transparent, modalElevation: isDark ? 0 : 3,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: s.surfaceContainerHighest, surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: s.surfaceContainerHighest, contentTextStyle: text.bodyMedium?.copyWith(color: s.onSurface),
        behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: s.error, foregroundColor: s.onError, elevation: isDark ? 0 : 4,
        shape: const CircleBorder(),
      ),
    );
  }
}

/// Convenience extension for semantic color access from [ThemeData].
extension AppThemeX on ThemeData {
  Color get bg => colorScheme.surfaceContainerLowest;
  Color get surfaceRaised => colorScheme.surfaceContainerHighest;
  Color get surfaceOverlay => brightness == Brightness.dark ? AppColors.darkOverlay : AppColors.lightOverlay;
  Color get borderSubtle => colorScheme.outlineVariant;
  Color get borderStrong => colorScheme.outline;
  Color get textPrimary => colorScheme.onSurface;
  Color get textSecondary => colorScheme.onSurfaceVariant;
  Color get textMuted => AppColors.mutedOf[brightness]!;
  Color get accent => colorScheme.primary;
  Color get success => brightness == Brightness.dark ? AppColors.success : AppColors.lightSuccess;
  Color get danger => colorScheme.error;
  Color get warning => colorScheme.tertiary;
  Color get aiColor => brightness == Brightness.dark ? AppColors.ai : AppColors.lightAi;
  Color get accentDim => AppColors.accentDimOf[brightness]!;
  Color get dangerDim => AppColors.dangerDimOf[brightness]!;
  Color get warningDim => AppColors.warningDimOf[brightness]!;
  Color get aiDim => AppColors.aiDimOf[brightness]!;
}