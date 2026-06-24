import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Numeric text — always JetBrains Mono with tabular figures.
class MonoText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final Color? color;
  final TextAlign? align;
  const MonoText(this.text, {super.key, this.size = 14, this.weight = FontWeight.w400, this.color, this.align});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.mono(size: size, weight: weight, color: color), textAlign: align);
  }
}

/// A key-value row: label in Inter, value in JetBrains Mono. Right-aligned.
class DataKV extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;
  const DataKV({super.key, required this.label, required this.value, this.valueColor, this.valueBold = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textSecondary)),
        MonoText(value, size: 14, weight: valueBold ? FontWeight.w600 : FontWeight.w500, color: valueColor ?? theme.textPrimary),
      ]),
    );
  }
}

/// Section label — mono caps, with optional trailing widget.
class SectionLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const SectionLabel({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.section, bottom: AppSpacing.sm),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label.toUpperCase(), style: AppTypography.mono(size: 11, weight: FontWeight.w600, color: theme.textMuted, height: 1.2)),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Hairline divider.
class Hairline extends StatelessWidget {
  final Color? color;
  const Hairline({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: color ?? Theme.of(context).borderSubtle);
  }
}

/// Empty state — centered icon circle, title, body, optional action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: theme.surfaceRaised, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: theme.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(color: theme.textPrimary, fontWeight: FontWeight.w600)),
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(body!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textSecondary, height: 1.4)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Segmented control — pill container, accent selected segment.
class SegmentedControl<T> extends StatelessWidget {
  final List<Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool expanded;
  const SegmentedControl({super.key, required this.segments, required this.selected, required this.onChanged, this.expanded = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: theme.surfaceRaised, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              flex: expanded ? 1 : 0,
              child: GestureDetector(
                onTap: () => onChanged(s.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutQuart,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: s.value == selected ? theme.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (s.icon != null) ...[
                        Icon(s.icon, size: 14, color: s.value == selected ? theme.bg : theme.textSecondary),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          s.label,
                          style: AppTypography.mono(size: 12, weight: FontWeight.w500,
                            color: s.value == selected ? theme.bg : theme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Segment<T> {
  final T value;
  final String label;
  final IconData? icon;
  const Segment(this.value, this.label, {this.icon});
}

/// Exchange avatar — circular, first letter, monospace.
class ExchangeAvatar extends StatelessWidget {
  final String name;
  final double size;
  const ExchangeAvatar({super.key, required this.name, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: theme.surfaceRaised, shape: BoxShape.circle, border: Border.all(color: theme.borderSubtle, width: 1)),
      child: Center(child: Text(letter, style: AppTypography.mono(size: size * 0.42, weight: FontWeight.w600, color: theme.textSecondary))),
    );
  }
}