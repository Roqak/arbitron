import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/trade.dart';
import '../../core/domain/exchange.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AppCubit, AppState>(
          buildWhen: (a, b) => a.trades != b.trades,
          builder: (context, state) {
            final trades = state.trades.where((t) => switch (_filter) { _Filter.all => true, _Filter.profit => t.profit, _Filter.loss => !t.profit }).toList();
            return CustomScrollView(slivers: [
              SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm), child: _Header(count: state.trades.length))),
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.sm), child: SegmentedControl<_Filter>(segments: const [Segment(_Filter.all, 'ALL'), Segment(_Filter.profit, 'GAIN'), Segment(_Filter.loss, 'LOSS')], selected: _filter, onChanged: (f) => setState(() => _filter = f)))),
              if (trades.isEmpty)
                const SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.history_outlined, title: 'No trades yet', body: 'Executed trades will appear here with full audit details.'))
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xxxl + 56),
                  sliver: SliverList.builder(itemCount: trades.length, itemBuilder: (context, i) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: _TradeCard(trade: trades[i], onTap: () => _showDetail(context, trades[i])))),
                ),
            ]);
          },
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, TradeRecord t) => showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _TradeDetailSheet(trade: t));
}

enum _Filter { all, profit, loss }

class _Header extends StatelessWidget {
  final int count;
  const _Header({required this.count});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('HISTORY', style: AppTypography.mono(size: 16, weight: FontWeight.w700, color: theme.textPrimary)),
      MonoText('$count trades', size: 11, weight: FontWeight.w400, color: theme.textMuted),
    ]);
  }
}

class _TradeCard extends StatelessWidget {
  final TradeRecord trade;
  final VoidCallback onTap;
  const _TradeCard({required this.trade, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = trade.profit;
    final color = positive ? theme.success : theme.danger;
    return ArbitronPanel(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            MonoText(trade.pair, size: 15, weight: FontWeight.w600, color: theme.textPrimary),
            const SizedBox(height: 2),
            MonoText('${ExchangeCatalog.byId(trade.buyExchangeId).name.split(" ").first} \u2192 ${ExchangeCatalog.byId(trade.sellExchangeId).name.split(" ").first}', size: 11, color: theme.textSecondary),
            const SizedBox(height: 2),
            Text(trade.strategyName, style: theme.textTheme.labelSmall?.copyWith(color: theme.textMuted)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            MonoText(Fmt.signedUsd(trade.netPnl), size: 15, weight: FontWeight.w600, color: color),
            MonoText(Fmt.dateTime(trade.executedAt), size: 11, color: theme.textMuted),
          ]),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          ModeChip(mode: trade.mode, compact: true),
          const SizedBox(width: 8),
          MonoText('SIZE ${Fmt.compactUsd(trade.sizeUsd)}', size: 11, color: theme.textMuted),
          const Spacer(),
          Icon(positive ? Icons.trending_up : Icons.trending_down, size: 14, color: color),
        ]),
      ]),
    );
  }
}

class _TradeDetailSheet extends StatelessWidget {
  final TradeRecord trade;
  const _TradeDetailSheet({required this.trade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = trade.profit;
    final color = positive ? theme.success : theme.danger;
    return DraggableScrollableSheet(initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (context, sc) {
      return Container(color: theme.surfaceOverlay, child: ListView(controller: sc, padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl), children: [
        Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.borderStrong, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: AppSpacing.xl),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            MonoText(trade.pair, size: 22, weight: FontWeight.w700, color: theme.textPrimary),
            const SizedBox(height: 4),
            MonoText('${ExchangeCatalog.byId(trade.buyExchangeId).name} \u2192 ${ExchangeCatalog.byId(trade.sellExchangeId).name}', size: 12, color: theme.textSecondary),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            MonoText(Fmt.signedUsd(trade.netPnl), size: 22, weight: FontWeight.w700, color: color),
            MonoText(Fmt.dateTime(trade.executedAt), size: 11, color: theme.textMuted),
          ]),
        ]),
        const SizedBox(height: AppSpacing.xl),
        Hairline(),
        const SizedBox(height: AppSpacing.lg),
        DataKV(label: 'Strategy', value: trade.strategyName),
        DataKV(label: 'Mode', value: trade.mode.label),
        DataKV(label: 'Size', value: Fmt.usd(trade.sizeUsd)),
        DataKV(label: 'Entry', value: '\$${Fmt.price(trade.entryPrice)}'),
        DataKV(label: 'Exit', value: '\$${Fmt.price(trade.exitPrice)}'),
        DataKV(label: 'Gross P&L', value: Fmt.signedUsd(trade.grossPnl), valueColor: trade.grossPnl >= 0 ? theme.success : theme.danger),
        DataKV(label: 'Fees', value: Fmt.usd(trade.feesUsd)),
        DataKV(label: 'Slippage', value: Fmt.usd(trade.slippageUsd)),
        DataKV(label: 'Net P&L', value: Fmt.signedUsd(trade.netPnl), valueColor: color, valueBold: true),
        if (trade.debrief.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('DEBRIEF', style: AppTypography.mono(size: 10, weight: FontWeight.w600, color: theme.textMuted)),
          const SizedBox(height: 8),
          AiAnalysisBlock(text: trade.debrief, title: 'Post-trade', showDisclaimer: false),
        ],
      ]));
    });
  }
}