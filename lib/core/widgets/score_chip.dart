import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Score chip showing "score N" with a dot indicating tier. See DESIGN.md §5.3.
/// 0–40 muted, 41–70 warning, 71–100 accent.
class ScoreChip extends StatelessWidget {
  final int score; // 0..100
  final bool compact;

  const ScoreChip({super.key, required this.score, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = score <= 40
        ? (theme.surfaceRaised, theme.textMuted)
        : score <= 70
            ? (theme.warningDim, theme.warning)
            : (theme.accentDim, theme.accent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(compact ? '$score' : 'score $score',
              style: theme.textTheme.labelMedium!.copyWith(color: fg, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}