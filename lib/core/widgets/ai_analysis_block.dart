import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';
import 'shared_widgets.dart';

/// AI analysis block — full-width, violet-tinted background, no left-border-
/// stripe (banned by impeccable). Header in mono caps. See DESIGN.md.
class AiAnalysisBlock extends StatelessWidget {
  final String text;
  final String? title;
  final DateTime? timestamp;
  final bool showDisclaimer;

  const AiAnalysisBlock({
    super.key,
    required this.text,
    this.title,
    this.timestamp,
    this.showDisclaimer = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: theme.aiDim, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.smart_toy, size: 14, color: theme.aiColor),
          const SizedBox(width: 6),
          MonoText('AI ANALYSIS', size: 10, weight: FontWeight.w700, color: theme.aiColor),
          if (title != null) ...[const SizedBox(width: 8), Text(title!, style: theme.textTheme.labelSmall?.copyWith(color: theme.textSecondary))],
          const Spacer(),
          if (timestamp != null) MonoText(_relative(timestamp!), size: 11, color: theme.textMuted),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textPrimary, height: 1.5)),
        if (showDisclaimer) ...[const SizedBox(height: AppSpacing.sm), MonoText('NOT FINANCIAL ADVICE', size: 9, color: theme.textMuted)],
      ]),
    );
  }

  String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 5) return 'now';
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}