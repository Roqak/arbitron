import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';

/// The fundamental surface. `surface` background, 1px subtle border, `md`
/// radius, `lg` padding. No shadow at level 1. See DESIGN.md §5.1.
class ArbitronCard extends StatelessWidget {
  final Widget? child;
  final Widget? header;
  final Widget? trailing;
  final Widget? footer;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  const ArbitronCard({
    super.key,
    this.child,
    this.header,
    this.trailing,
    this.footer,
    this.padding = AppPaddings.card,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Card(
      color: color ?? theme.cardTheme.color,
      margin: EdgeInsets.zero,
      shape: theme.cardTheme.shape,
      elevation: theme.cardTheme.elevation,
      surfaceTintColor: theme.cardTheme.surfaceTintColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (header != null || trailing != null)
                Padding(
                  padding: EdgeInsets.only(bottom: child != null ? AppSpacing.sm : 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (header != null) Expanded(child: DefaultTextStyle.merge(style: theme.textTheme.headlineSmall!, child: header!)),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
              if (child != null) Flexible(child: child!),
              if (footer != null) ...[
                Divider(height: 1, color: theme.borderSubtle.withOpacity(0.6)),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: footer,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return card;
  }
}