import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/trade.dart';
import '../../core/domain/exchange.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/widgets.dart';

/// History screen — immutable trade log. See PRD §8.5.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _TradeFilter _filter = _TradeFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AppCubit, AppState>(
          buildWhen: (a, b) => a.trades != b.trades,
          builder: (context, state) {
            final trades = state.trades.where((t) {
              switch (_filter) {
                case _TradeFilter.all: return true;
                case _TradeFilter.profit: return t.profit;
                case _TradeFilter.loss: return !t.profit;
              }
            }).toList();
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, 0), child: _Header())),
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.md), child: _FilterBar(filter: _filter, onChanged: (f) => setState(() => _filter = f)))),
                if (trades.isEmpty)
                  const SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.history_outlined, title: 'No trades yet', body: 'Executed trades will appear here with full audit details.'))
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xxxl + 72),
                    sliver: SliverList.builder(
                      itemCount: trades.length,
                      itemBuilder: (context, i) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: _TradeCard(trade: trades[i], onTap: () => _showDetail(context, trades[i]))),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, TradeRecord t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TradeDetailSheet(trade: t),
    );
  }
}

enum _TradeFilter { all, profit, loss }

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('History', style: theme.textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w700)),
        BlocBuilder<AppCubit, AppState>(
          buildWhen: (a, b) => a.trades.length != b.trades.length,
          builder: (context, state) => Text('${state.trades.length} trades', style: theme.textTheme.labelMedium!.copyWith(color: theme.textMuted)),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _TradeFilter filter;
  final void Function(_TradeFilter) onChanged;
  const _FilterBar({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedControl<_TradeFilter>(
      segments: const [Segment(_TradeFilter.all, 'All'), Segment(_TradeFilter.profit, 'Profit'), Segment(_TradeFilter.loss, 'Loss')],
      selected: filter,
      onChanged: onChanged,
    );
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
    return ArbitronCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trade.pair, style: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${ExchangeCatalog.byId(trade.buyExchangeId).name} \u2192 ${ExchangeCatalog.byId(trade.sellExchangeId).name}',
                        style: theme.textTheme.labelMedium!.copyWith(color: theme.textSecondary)),
                    const SizedBox(height: 4),
                    Text(trade.strategyName, style: theme.textTheme.labelMedium!.copyWith(color: theme.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Fmt.signedUsd(trade.netPnl),
                      style: theme.textTheme.titleLarge!.copyWith(color: positive ? theme.success : theme.danger, fontWeight: FontWeight.w600)),
                  Text(Fmt.dateTime(trade.executedAt), style: theme.textTheme.labelMedium!.copyWith(color: theme.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              ModeChip(mode: trade.mode, compact: true),
              const SizedBox(width: 8),
              Text('Size ${Fmt.compactUsd(trade.sizeUsd)}', style: theme.textTheme.labelMedium!.copyWith(color: theme.textMuted)),
              const Spacer(),
              Icon(positive ? Icons.trending_up : Icons.trending_down, size: 16, color: positive ? theme.success : theme.danger),
            ],
          ),
        ],
      ),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          color: theme.surfaceOverlay,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl),
            children: [
              Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.borderStrong, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: AppSpacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trade.pair, style: theme.textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('${ExchangeCatalog.byId(trade.buyExchangeId).name} \u2192 ${ExchangeCatalog.byId(trade.sellExchangeId).name}',
                            style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(Fmt.signedUsd(trade.netPnl), style: theme.textTheme.displayMedium!.copyWith(color: positive ? theme.success : theme.danger, fontWeight: FontWeight.w700)),
                      Text(Fmt.dateTime(trade.executedAt), style: theme.textTheme.labelMedium!.copyWith(color: theme.textMuted)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              ArbitronCard(
                child: Column(
                  children: [
                    _DetailRow(label: 'Strategy', value: trade.strategyName),
                    _DetailRow(label: 'Mode', value: trade.mode.label),
                    _DetailRow(label: 'Size', value: Fmt.usd(trade.sizeUsd)),
                    _DetailRow(label: 'Entry price', value: '\$${Fmt.price(trade.entryPrice)}'),
                    _DetailRow(label: 'Exit price', value: '\$${Fmt.price(trade.exitPrice)}'),
                    _DetailRow(label: 'Gross P&L', value: Fmt.signedUsd(trade.grossPnl), color: trade.grossPnl >= 0 ? theme.success : theme.danger),
                    _DetailRow(label: 'Fees', value: Fmt.usd(trade.feesUsd)),
                    _DetailRow(label: 'Slippage', value: Fmt.usd(trade.slippageUsd)),
                    _DetailRow(label: 'Net P&L', value: Fmt.signedUsd(trade.netPnl), color: positive ? theme.success : theme.danger, bold: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('AI Debrief', style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.md),
              AiAnalysisBlock(text: trade.debrief, title: 'Post-trade analysis', showDisclaimer: false),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;
  const _DetailRow({required this.label, required this.value, this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary)),
          Text(value, style: theme.textTheme.bodyMedium!.copyWith(color: color ?? theme.textPrimary, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}