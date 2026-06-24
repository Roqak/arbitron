import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Status chip — `labelMedium` text, `accentDim`/`warningDim`/etc background
/// with matching text color. See DESIGN.md §5.3.
enum ChipTone { accent, warning, danger, info, neutral }

class StatusChip extends StatelessWidget {
  final String label;
  final ChipTone tone;
  final IconData? icon;
  final double? size;

  const StatusChip({
    super.key,
    required this.label,
    this.tone = ChipTone.neutral,
    this.icon,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = switch (tone) {
      ChipTone.accent => (theme.accentDim, theme.accent),
      ChipTone.warning => (theme.warningDim, theme.warning),
      ChipTone.danger => (theme.dangerDim, theme.danger),
      ChipTone.info => (theme.infoDim, theme.info),
      ChipTone.neutral => (theme.surfaceRaised, theme.textSecondary),
    };
    final style = theme.textTheme.labelMedium!.copyWith(color: fg, fontWeight: FontWeight.w600);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
          Text(label, style: style),
        ],
      ),
    );
  }
}