import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/exchange.dart';
import '../../core/domain/opportunity.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/widgets.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  _SortBy _sortBy = _SortBy.netProfit;
  double _minProfit = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AppCubit, AppState>(
          buildWhen: (a, b) => a.opportunities != b.opportunities,
          builder: (context, state) {
            final opps = state.opportunities.where((o) => o.netProfitUsd >= _minProfit).toList();
            opps.sort((Opportunity a, Opportunity b) {
              switch (_sortBy) {
                case _SortBy.netProfit: return b.netProfitUsd.compareTo(a.netProfitUsd);
                case _SortBy.confidence: return b.confidenceScore.compareTo(a.confidenceScore);
                case _SortBy.time: return b.detectedAt.compareTo(a.detectedAt);
                case _SortBy.spread: return b.grossSpreadPct.compareTo(a.grossSpreadPct);
              }
            });
            return RefreshIndicator(
              onRefresh: () async => context.read<AppCubit>().refreshOpportunities(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm), child: _Header())),
                  SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.sm), child: _FiltersBar(onSort: (s) => setState(() => _sortBy = s), sortBy: _sortBy, onMinProfit: (v) => setState(() => _minProfit = v), minProfit: _minProfit))),
                  if (opps.isEmpty)
                    const SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.auto_awesome_outlined, title: 'No opportunities yet', body: 'Connect an exchange and enable a strategy to start scanning.'))
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xxxl + 56),
                      sliver: SliverList.builder(
                        itemCount: opps.length,
                        itemBuilder: (context, i) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: OpportunityCard(opportunity: opps[i], onTap: () => _showDetail(context, opps[i]))),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Opportunity o) {
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _OpportunityDetailSheet(opportunity: o));
  }
}

enum _SortBy { netProfit, confidence, time, spread }

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('OPPORTUNITIES', style: AppTypography.mono(size: 16, weight: FontWeight.w700, color: theme.textPrimary)),
        IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: () => context.read<AppCubit>().refreshOpportunities()),
      ],
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final void Function(_SortBy) onSort;
  final _SortBy sortBy;
  final void Function(double) onMinProfit;
  final double minProfit;
  const _FiltersBar({required this.onSort, required this.sortBy, required this.onMinProfit, required this.minProfit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: SegmentedControl<_SortBy>(
            segments: const [Segment(_SortBy.netProfit, 'PROFIT'), Segment(_SortBy.confidence, 'SCORE'), Segment(_SortBy.time, 'TIME')],
            selected: sortBy, onChanged: onSort,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        PopupMenuButton<double>(
          onSelected: onMinProfit,
          itemBuilder: (_) => const [PopupMenuItem(value: 0, child: Text('All')), PopupMenuItem(value: 10, child: Text('\$10+')), PopupMenuItem(value: 25, child: Text('\$25+')), PopupMenuItem(value: 50, child: Text('\$50+'))],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: theme.surfaceRaised, borderRadius: BorderRadius.circular(999)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.filter_list, size: 14, color: theme.textSecondary),
              const SizedBox(width: 4),
              MonoText(minProfit == 0 ? 'ALL' : '\$${minProfit.toStringAsFixed(0)}+', size: 11, weight: FontWeight.w600, color: theme.textSecondary),
            ]),
          ),
        ),
      ],
    );
  }
}

class _OpportunityDetailSheet extends StatelessWidget {
  final Opportunity opportunity;
  const _OpportunityDetailSheet({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = opportunity;
    final profitable = o.netProfitUsd >= 0;
    final profitColor = profitable ? theme.success : theme.danger;
    return DraggableScrollableSheet(
      initialChildSize: 0.92, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
      builder: (context, sc) {
        return Container(
          color: theme.surfaceOverlay,
          child: ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl),
            children: [
              Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.borderStrong, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: AppSpacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MonoText(o.pair, size: 22, weight: FontWeight.w700, color: theme.textPrimary),
                      const SizedBox(height: 4),
                      Row(children: [
                        MonoText(ExchangeCatalog.byId(o.buyExchangeId).name, size: 12, color: theme.textSecondary),
                        Icon(Icons.arrow_forward, size: 14, color: theme.textMuted),
                        MonoText(ExchangeCatalog.byId(o.sellExchangeId).name, size: 12, color: theme.textSecondary),
                      ]),
                    ],
                  )),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    MonoText(Fmt.signedUsd(o.netProfitUsd), size: 22, weight: FontWeight.w700, color: profitColor),
                    MonoText(Fmt.pct(o.netProfitPct), size: 12, weight: FontWeight.w600, color: profitColor),
                  ]),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Hairline(),
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
              DataKV(label: 'Confidence', value: '${o.confidenceScore}/100'),
              DataKV(label: 'Strategy', value: o.strategy.label),
              DataKV(label: 'Detected', value: Fmt.dateTime(o.detectedAt)),
              if (o.analysisText.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                AiAnalysisBlock(text: o.analysisText, title: 'Opportunity', timestamp: o.detectedAt),
              ],
              const SizedBox(height: AppSpacing.xxl),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Reject'))),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: FilledButton(
                  onPressed: () {
                    context.read<AppCubit>().executeOpportunity(o);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(profitable ? 'Executed ${o.pair} net ${Fmt.signedUsd(o.netProfitUsd)}' : 'Executed ${o.pair}'), duration: const Duration(seconds: 3)));
                  },
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bolt, size: 16), SizedBox(width: 6), Text('Execute')]),
                )),
              ]),
            ],
          ),
        );
      },
    );
  }
}