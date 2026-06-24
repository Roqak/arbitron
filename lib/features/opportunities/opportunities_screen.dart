import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/exchange.dart';
import '../../core/domain/opportunity.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/widgets.dart';

/// Opportunities screen — filterable list. See PRD §8.2 and DESIGN.md §5.2.
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
                  SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, 0), child: _Header())),
                  SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.md), child: _FiltersBar(onSort: (s) => setState(() => _sortBy = s), sortBy: _sortBy, onMinProfit: (v) => setState(() => _minProfit = v), minProfit: _minProfit))),
                  if (opps.isEmpty)
                    const SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.auto_awesome_outlined, title: 'No opportunities yet', body: 'Connect an exchange and enable a strategy to start scanning.'))
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xxxl + 72),
                      sliver: SliverList.builder(
                        itemCount: opps.length,
                        itemBuilder: (context, i) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: OpportunityCard(opportunity: opps[i], onTap: () => _showDetail(context, opps[i]))),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) => _OpportunityDetailSheet(opportunity: o),
    );
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
        Text('Opportunities', style: theme.textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w700)),
        IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<AppCubit>().refreshOpportunities()),
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
    return Row(
      children: [
        Expanded(
          child: SegmentedControl<_SortBy>(
            segments: const [
              Segment(_SortBy.netProfit, 'Profit'),
              Segment(_SortBy.confidence, 'Score'),
              Segment(_SortBy.time, 'Time'),
            ],
            selected: sortBy,
            onChanged: onSort,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _MinProfitChip(minProfit: minProfit, onChanged: onMinProfit),
      ],
    );
  }
}

class _MinProfitChip extends StatelessWidget {
  final double minProfit;
  final void Function(double) onChanged;
  const _MinProfitChip({required this.minProfit, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<double>(
      onSelected: onChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 0, child: Text('All')),
        PopupMenuItem(value: 10, child: Text('\$10+')),
        PopupMenuItem(value: 25, child: Text('\$25+')),
        PopupMenuItem(value: 50, child: Text('\$50+')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: theme.surfaceRaised, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, size: 16, color: theme.textSecondary),
            const SizedBox(width: 6),
            Text(minProfit == 0 ? 'All' : '\$${minProfit.toStringAsFixed(0)}+', style: theme.textTheme.labelMedium!.copyWith(color: theme.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
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
                        Text(o.pair, style: theme.textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Text(ExchangeCatalog.byId(o.buyExchangeId).name, style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary)),
                          Icon(Icons.arrow_forward, size: 16, color: theme.textMuted),
                          Text(ExchangeCatalog.byId(o.sellExchangeId).name, style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary)),
                        ]),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(Fmt.signedUsd(o.netProfitUsd), style: theme.textTheme.displayMedium!.copyWith(color: profitable ? theme.success : theme.danger, fontWeight: FontWeight.w700)),
                      Text(Fmt.pct(o.netProfitPct), style: theme.textTheme.titleMedium!.copyWith(color: profitable ? theme.success : theme.danger, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              ArbitronCard(
                child: Column(
                  children: [
                    _DetailRow(label: 'Buy price', value: '\$${Fmt.price(o.buyPrice)}'),
                    _DetailRow(label: 'Sell price', value: '\$${Fmt.price(o.sellPrice)}'),
                    _DetailRow(label: 'Gross spread', value: Fmt.pctRaw(o.grossSpreadPct)),
                    _DetailRow(label: 'Est. fees', value: Fmt.usd(o.estFeesUsd)),
                    _DetailRow(label: 'Est. slippage', value: Fmt.usd(o.estSlippageUsd)),
                    if (o.requiresBridge) ...[
                      _DetailRow(label: 'Bridge', value: o.bridgeName ?? ''),
                      _DetailRow(label: 'Bridge cost', value: Fmt.usd(o.bridgeCostUsd ?? 0)),
                      _DetailRow(label: 'Bridge time', value: o.bridgeTime != null ? '~${o.bridgeTime!.inMinutes}min' : ''),
                    ],
                    _DetailRow(label: 'Confidence', value: '${o.confidenceScore}/100'),
                    _DetailRow(label: 'Strategy', value: o.strategy.label),
                    _DetailRow(label: 'Detected', value: Fmt.dateTime(o.detectedAt)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AiAnalysisBlock(text: o.analysisText, title: 'Opportunity Analysis', timestamp: o.detectedAt),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Reject'))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        context.read<AppCubit>().executeOpportunity(o);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(profitable ? 'Executed ${o.pair} \u2014 net ${Fmt.signedUsd(o.netProfitUsd)}' : 'Executed ${o.pair} \u2014 logged to history'), duration: const Duration(seconds: 3)),
                        );
                      },
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bolt, size: 18), SizedBox(width: 6), Text('Execute')]),
                    ),
                  ),
                ],
              ),
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
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary)),
          Text(value, style: theme.textTheme.bodyMedium!.copyWith(color: theme.textPrimary, fontWeight: FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}