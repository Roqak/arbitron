import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

enum ChipTone { accent, warning, danger, ai, neutral }

class StatusChip extends StatelessWidget {
  final String label;
  final ChipTone tone;
  final IconData? icon;
  const StatusChip({super.key, required this.label, this.tone = ChipTone.neutral, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = switch (tone) {
      ChipTone.accent => (theme.accentDim, theme.accent),
      ChipTone.warning => (theme.warningDim, theme.warning),
      ChipTone.danger => (theme.dangerDim, theme.danger),
      ChipTone.ai => (theme.aiDim, theme.aiColor),
      ChipTone.neutral => (theme.surfaceRaised, theme.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 11, color: fg), const SizedBox(width: 4)],
        MonoText(label, size: 11, weight: FontWeight.w600, color: fg),
      ]),
    );
  }
}

class ScoreBar extends StatelessWidget {
  final int score;
  final double width;
  const ScoreBar({super.key, required this.score, this.width = 48});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segColor = score <= 40 ? theme.textMuted : score <= 70 ? theme.warning : theme.accent;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (int i = 0; i < 3; i++)
        Container(width: width / 3 - 2, height: 3, margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(color: i <= (score / 33).floor() ? segColor : theme.borderSubtle, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      MonoText('$score', size: 12, weight: FontWeight.w600, color: segColor),
    ]);
  }
}

/// ModeChip — accepts a generic object with a `label` getter (ExecutionMode).
class ModeChip extends StatelessWidget {
  final dynamic mode;
  final bool compact;
  const ModeChip({super.key, required this.mode, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final labelStr = mode.label.toString();
    final (tone, icon, label) = switch (labelStr) {
      'Manual' => (ChipTone.ai, Icons.pan_tool_outlined, 'MANUAL'),
      'Semi-Auto' => (ChipTone.warning, Icons.timer_outlined, 'SEMI'),
      'Autonomous' => (ChipTone.accent, Icons.auto_mode, 'AUTO'),
      _ => (ChipTone.neutral, Icons.help_outline, labelStr),
    };
    return StatusChip(label: compact ? label : labelStr, tone: tone, icon: icon);
  }
}