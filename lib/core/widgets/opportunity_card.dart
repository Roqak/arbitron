import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';
import '../domain/opportunity.dart';
import '../domain/exchange.dart';
import '../utils/fmt.dart';
import 'score_chip.dart';

/// The signature component — a detected arbitrage opportunity rendered as a
/// card. Compact form for lists; expand with [expanded] for detail.
/// See DESIGN.md §5.2.
class OpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final bool expanded;
  final VoidCallback? onTap;

  const OpportunityCard({super.key, required this.opportunity, this.expanded = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = opportunity;
    final buyEx = ExchangeCatalog.byId(o.buyExchangeId);
    final sellEx = ExchangeCatalog.byId(o.sellExchangeId);
    final profitable = o.netProfitUsd >= 0;

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.borderSubtle, width: 1),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: pair + net profit
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.pair, style: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(buyEx.name, style: theme.textTheme.labelMedium!.copyWith(color: theme.textSecondary)),
                            Icon(Icons.arrow_forward, size: 14, color: theme.textMuted),
                            Text(sellEx.name, style: theme.textTheme.labelMedium!.copyWith(color: theme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(Fmt.signedUsd(o.netProfitUsd),
                          style: theme.textTheme.titleLarge!.copyWith(
                              color: profitable ? theme.success : theme.danger, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(Fmt.pct(o.netProfitPct),
                          style: theme.textTheme.labelMedium!.copyWith(
                              color: profitable ? theme.success : theme.danger, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: AppSpacing.lg),
                _DetailRow(label: 'Buy price', value: '\$${Fmt.price(o.buyPrice)}'),
                _DetailRow(label: 'Sell price', value: '\$${Fmt.price(o.sellPrice)}'),
                _DetailRow(label: 'Gross spread', value: Fmt.pctRaw(o.grossSpreadPct)),
                _DetailRow(label: 'Est. fees', value: Fmt.usd(o.estFeesUsd)),
                _DetailRow(label: 'Est. slippage', value: Fmt.usd(o.estSlippageUsd)),
                const SizedBox(height: AppSpacing.md),
                if (o.analysisText.isNotEmpty) ...[
                  Text(o.analysisText,
                      style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary, height: 1.5)),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
              // Footer chips
              Row(
                children: [
                  ScoreChip(score: o.confidenceScore),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: theme.surfaceRaised, borderRadius: BorderRadius.circular(6)),
                    child: Text(o.strategy.label,
                        style: theme.textTheme.labelMedium!.copyWith(color: theme.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Text(Fmt.relative(o.detectedAt),
                      style: theme.textTheme.labelMedium!.copyWith(color: theme.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary)),
          Text(value,
              style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.textPrimary, fontFeatures: const [FontFeature.tabularFigures()], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}