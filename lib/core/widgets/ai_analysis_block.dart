import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';
import '../utils/fmt.dart';

/// LLM-generated text container with a 3px `info` left border and `infoDim`
/// background at 0.5 opacity. Header row shows the "AI" badge + disclaimer.
/// See DESIGN.md §5.11 — mandatory visual treatment for all LLM output.
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
      decoration: BoxDecoration(
        color: theme.infoDim.withOpacity(0.5),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: theme.info),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.infoDim,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('AI',
                              style: theme.textTheme.labelSmall!.copyWith(
                                  color: theme.info, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        ),
                        if (title != null) ...[
                          const SizedBox(width: 8),
                          Text(title!, style: theme.textTheme.labelMedium!.copyWith(color: theme.textSecondary, fontWeight: FontWeight.w600)),
                        ],
                        const Spacer(),
                        if (timestamp != null)
                          Text(Fmt.relative(timestamp!),
                              style: theme.textTheme.labelSmall!.copyWith(color: theme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(text, style: theme.textTheme.bodyLarge!.copyWith(color: theme.textPrimary, height: 1.5)),
                    if (showDisclaimer) ...[
                      const SizedBox(height: 8),
                      Text('AI analysis \u2014 not financial advice',
                          style: theme.textTheme.labelSmall!.copyWith(color: theme.textMuted, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}