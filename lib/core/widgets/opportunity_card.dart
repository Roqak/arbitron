import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';
import '../domain/opportunity.dart';
import '../domain/exchange.dart';
import '../utils/fmt.dart';
import 'status_chip.dart';
import 'ai_analysis_block.dart';
import 'shared_widgets.dart';

class OpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final bool expanded;
  final VoidCallback? onTap;
  const OpportunityCard({super.key, required this.opportunity, this.expanded = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = opportunity;
    final profitable = o.netProfitUsd >= 0;
    final buyEx = ExchangeCatalog.byId(o.buyExchangeId);
    final sellEx = ExchangeCatalog.byId(o.sellExchangeId);
    final profitColor = profitable ? theme.success : theme.danger;
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: theme.borderSubtle, width: 1)),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                MonoText(o.pair, size: 15, weight: FontWeight.w600, color: theme.textPrimary),
                const SizedBox(height: 4),
                Row(children: [
                  MonoText(buyEx.name.split(' ').first, size: 11, color: theme.textSecondary),
                  Icon(Icons.arrow_forward, size: 12, color: theme.textMuted),
                  MonoText(sellEx.name.split(' ').first, size: 11, color: theme.textSecondary),
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                MonoText(Fmt.signedUsd(o.netProfitUsd), size: 15, weight: FontWeight.w600, color: profitColor),
                const SizedBox(height: 2),
                MonoText(Fmt.pct(o.netProfitPct), size: 11, weight: FontWeight.w600, color: profitColor),
              ]),
            ]),
            if (expanded) ...[
              const SizedBox(height: AppSpacing.lg),
              DataKV(label: 'Buy price', value: '\$${Fmt.price(o.buyPrice)}'),
              DataKV(label: 'Sell price', value: '\$${Fmt.price(o.sellPrice)}'),
              DataKV(label: 'Gross spread', value: Fmt.pctRaw(o.grossSpreadPct)),
              DataKV(label: 'Est. fees', value: Fmt.usd(o.estFeesUsd)),
              DataKV(label: 'Est. slippage', value: Fmt.usd(o.estSlippageUsd)),
              if (o.requiresBridge) ...[
                DataKV(label: 'Bridge', value: o.bridgeName ?? ''),
                DataKV(label: 'Bridge cost', value: Fmt.usd(o.bridgeCostUsd ?? 0)),
              ],
              if (o.analysisText.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), AiAnalysisBlock(text: o.analysisText, title: 'Opportunity', timestamp: o.detectedAt)],
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              ScoreBar(score: o.confidenceScore, width: 42),
              const SizedBox(width: 8),
              StatusChip(label: o.strategy.name.split(' ').first.toUpperCase(), tone: ChipTone.neutral),
              const Spacer(),
              MonoText(Fmt.relative(o.detectedAt), size: 11, color: theme.textMuted),
            ]),
          ]),
        ),
      ),
    );
  }
}