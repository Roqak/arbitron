import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/exchange.dart';
import '../../core/domain/opportunity.dart';
import '../../core/domain/strategy.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/fmt.dart';
import '../../core/utils/rng.dart';
import '../../core/widgets/widgets.dart';

/// Dashboard — live overview. See PRD §8.1 and DESIGN.md §12.1.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (a, b) => a.opportunities != b.opportunities || a.trades != b.trades || a.strategies != b.strategies || a.autonomousPaused != b.autonomousPaused,
      builder: (context, state) {
        final todayPnl = state.todayPnl;
        final todayTrades = state.trades.where((t) => DateTime.now().difference(t.executedAt).inHours < 24).length;
        final activeStrategies = state.strategies.where((s) => s.enabled).toList();
        final topOpps = state.opportunities.take(5).toList();
        final tickerItems = topOpps.map((o) => (pair: o.pair, netPct: o.netProfitPct)).toList();

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => context.read<AppCubit>().refreshOpportunities(),
              child: ListView(
                padding: EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.xxxl + 72),
                children: [
                  Padding(
                    padding: AppPaddings.screenH,
                    child: _Header(title: 'Dashboard'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TickerStrip(items: tickerItems),
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: AppPaddings.screenH,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PortfolioSummary(
                          valueUsd: state.portfolioValue,
                          todayPnl: todayPnl,
                          todayTrades: todayTrades,
                          totalPnl: state.totalPnl,
                        ),
                        const SizedBox(height: AppSpacing.section),
                        _SectionHeader(title: 'Active Strategies', trailing: activeStrategies.length > 0 ? null : null),
                        const SizedBox(height: AppSpacing.md),
                        if (activeStrategies.isEmpty)
                          ArbitronCard(child: Text('No active strategies. Enable one in the Strategies tab.', style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary)))
                        else
                          Column(children: activeStrategies.map((s) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: _StrategySummaryCard(strategy: s))).toList()),
                        const SizedBox(height: AppSpacing.section),
                        _SectionHeader(title: 'AI Activity'),
                        const SizedBox(height: AppSpacing.md),
                        _AiActivityFeed(opportunities: state.opportunities.take(6).toList()),
                        const SizedBox(height: AppSpacing.section),
                        _SectionHeader(title: 'Market Health'),
                        const SizedBox(height: AppSpacing.md),
                        _MarketHealth(exchangeIds: state.enabledExchangeIds),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w700)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: theme.accentDim, borderRadius: BorderRadius.circular(999)),
          child: Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Live', style: theme.textTheme.labelMedium!.copyWith(color: theme.accent, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class TickerStrip extends StatelessWidget {
  final List<({String pair, double netPct})> items;
  const TickerStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 44,
      color: theme.colorScheme.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => VerticalDivider(width: 1, color: theme.borderSubtle, indent: 12, endIndent: 12),
        itemBuilder: (context, i) {
          final it = items[i];
          final positive = it.netPct >= 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Text(it.pair, style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text(Fmt.pct(it.netPct),
                    style: theme.textTheme.labelMedium!.copyWith(
                        color: positive ? theme.success : theme.danger, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PortfolioSummary extends StatelessWidget {
  final double valueUsd;
  final double todayPnl;
  final int todayTrades;
  final double totalPnl;
  const _PortfolioSummary({required this.valueUsd, required this.todayPnl, required this.todayTrades, required this.totalPnl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positiveToday = todayPnl >= 0;
    final positiveTotal = totalPnl >= 0;
    return ArbitronCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Portfolio', style: theme.textTheme.labelMedium!.copyWith(color: theme.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Text(Fmt.usd(valueUsd), style: theme.textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(positiveToday ? Icons.trending_up : Icons.trending_down, size: 16, color: positiveToday ? theme.success : theme.danger),
              const SizedBox(width: 4),
              Text(Fmt.signedUsd(todayPnl), style: theme.textTheme.titleMedium!.copyWith(color: positiveToday ? theme.success : theme.danger, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('today \u00b7 $todayTrades trades', style: theme.textTheme.labelMedium!.copyWith(color: theme.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: theme.borderSubtle),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total P&L', style: theme.textTheme.labelMedium!.copyWith(color: theme.textSecondary)),
              Text(Fmt.signedUsd(totalPnl),
                  style: theme.textTheme.labelMedium!.copyWith(
                      color: positiveTotal ? theme.success : theme.danger, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w600)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _StrategySummaryCard extends StatelessWidget {
  final Strategy strategy;
  const _StrategySummaryCard({required this.strategy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = strategy.totalPnl >= 0;
    return ArbitronCard(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(strategy.name, style: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600))),
              ModeChip(mode: strategy.mode, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              StatusChip(label: strategy.status.label, tone: strategy.status == StrategyStatus.active ? ChipTone.accent : ChipTone.warning),
              const SizedBox(width: 8),
              Text('${strategy.totalTrades} trades', style: theme.textTheme.labelMedium!.copyWith(color: theme.textMuted)),
              const Spacer(),
              Text(Fmt.signedUsd(strategy.totalPnl),
                  style: theme.textTheme.labelMedium!.copyWith(
                      color: positive ? theme.success : theme.danger, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiActivityFeed extends StatelessWidget {
  final List<Opportunity> opportunities;
  const _AiActivityFeed({required this.opportunities});

  @override
  Widget build(BuildContext context) {
    if (opportunities.isEmpty) {
      return const EmptyState(icon: Icons.smart_toy_outlined, title: 'No AI activity yet', body: 'LLM analyses will appear here as opportunities are evaluated.');
    }
    return Column(
      children: opportunities.map((o) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AiAnalysisBlock(
            text: o.analysisText,
            title: '${o.pair} \u00b7 score ${o.confidenceScore}',
            timestamp: o.detectedAt,
            showDisclaimer: false,
          ),
        );
      }).toList(),
    );
  }
}

class _MarketHealth extends StatelessWidget {
  final List<String> exchangeIds;
  const _MarketHealth({required this.exchangeIds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exchanges = ExchangeCatalog.all.where((e) => exchangeIds.contains(e.id)).toList();
    if (exchanges.isEmpty) {
      return ArbitronCard(child: Text('No exchanges connected. Configure one in Settings.', style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary)));
    }
    return ArbitronCard(
      child: Column(
        children: exchanges.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                ExchangeAvatar(name: e.name, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(e.name, style: theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500))),
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('connected', style: theme.textTheme.labelSmall!.copyWith(color: theme.textMuted)),
                const SizedBox(width: AppSpacing.md),
                Text('${Rng.nextInt(min: 18, max: 64)}ms', style: theme.textTheme.labelSmall!.copyWith(color: theme.textSecondary, fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}