import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';

/// A discrete bounded surface for list items. NOT the default container.
/// Use [ArbitronPanel] only for discrete list items (opportunities, trades).
class ArbitronPanel extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool showBorder;

  const ArbitronPanel({super.key, this.child, this.onTap, this.padding = AppPaddings.panel, this.showBorder = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          decoration: showBorder ? BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: theme.borderSubtle, width: 1)) : null,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}