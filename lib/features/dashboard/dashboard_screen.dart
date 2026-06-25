import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/exchange.dart';
import '../../core/domain/strategy.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/widgets.dart';
import 'leaderboard_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (a, b) =>
          a.opportunities != b.opportunities ||
          a.trades != b.trades ||
          a.strategies != b.strategies ||
          a.feedsConnected != b.feedsConnected ||
          a.llmConfigured != b.llmConfigured ||
          a.feedStatuses != b.feedStatuses ||
          a.lastDailySummary != b.lastDailySummary ||
          a.portfolioLoading != b.portfolioLoading ||
          a.llmError != b.llmError ||
          a.tradeError != b.tradeError,
      builder: (context, state) {
        final topOpps = state.opportunities.take(8).toList();
        final activeStrategies = state.strategies.where((s) => s.enabled).toList();

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<AppCubit>().refreshOpportunities();
                await context.read<AppCubit>().refreshPortfolio();
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.xxxl + 56),
                children: [
                  // Error banner
                  if (state.tradeError != null || state.llmError != null)
                    _ErrorBanner(tradeError: state.tradeError, llmError: state.llmError),
                  // Header with live status
                  _Header(feedsConnected: state.feedsConnected, llmConfigured: state.llmConfigured),
                  const SizedBox(height: AppSpacing.lg),
                  // Portfolio — no card, just typographic hierarchy
                  _Portfolio(valueUsd: state.portfolioValue, todayPnl: state.todayPnl, totalPnl: state.totalPnl, loading: state.portfolioLoading),
                  const SizedBox(height: AppSpacing.section),
                  // Ticker strip
                  TickerStrip(opportunities: topOpps),
                  const SizedBox(height: AppSpacing.section),
                  // Active strategies
                  SectionLabel(label: 'Active Strategies', trailing: state.strategies.isNotEmpty ? MonoText('${activeStrategies.length}/${state.strategies.length}', size: 11, color: theme.textMuted) : null),
                  if (activeStrategies.isEmpty)
                    Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text('No active strategies. Enable one in STRAT.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.textSecondary)))
                  else
                    ...activeStrategies.map((s) => _StrategyRow(strategy: s)),
                  // AI activity
                  SectionLabel(label: 'AI Activity', trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (state.trades.length >= 5) Padding(padding: const EdgeInsets.only(right: 6), child: StatusChip(label: 'LEARNING', tone: ChipTone.ai)),
                    StatusChip(label: state.llmConfigured ? 'LLM ON' : 'LLM OFF', tone: state.llmConfigured ? ChipTone.accent : ChipTone.neutral),
                  ])),
                  if (topOpps.isEmpty)
                    Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text('No AI activity yet.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.textSecondary)))
                  else
                    ...topOpps.take(4).map((o) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: AiAnalysisBlock(text: o.analysisText, title: '${o.pair} ${o.confidenceScore}', timestamp: o.detectedAt, showDisclaimer: false))),
                  // Daily summary
                  if (state.lastDailySummary != null) ...[
                    SectionLabel(label: 'Daily Summary'),
                    AiAnalysisBlock(text: state.lastDailySummary!, title: 'LLM Daily', timestamp: state.lastDailySummaryAt),
                  ],
                  // Market health
                  SectionLabel(label: 'Market Health'),
                  ...state.enabledExchangeIds.map((id) => _ExchangeStatusRow(id: id, status: state.feedStatuses[id])),
                  // Community
                  SectionLabel(label: 'Community'),
                  _CommunityEntry(onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const LeaderboardSheet())),
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
  final bool feedsConnected;
  final bool llmConfigured;
  const _Header({required this.feedsConnected, required this.llmConfigured});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = feedsConnected ? theme.accent : theme.warning;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('ARBITRON', style: AppTypography.mono(size: 18, weight: FontWeight.w700, color: theme.textPrimary)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            MonoText(feedsConnected ? 'LIVE' : 'CONNECTING', size: 11, weight: FontWeight.w600, color: statusColor),
            const SizedBox(width: 12),
            MonoText(llmConfigured ? 'AI ON' : 'AI OFF', size: 11, weight: FontWeight.w600, color: llmConfigured ? theme.accent : theme.textMuted),
          ],
        ),
      ],
    );
  }
}

class _Portfolio extends StatelessWidget {
  final double valueUsd, todayPnl, totalPnl;
  final bool loading;
  const _Portfolio({required this.valueUsd, required this.todayPnl, required this.totalPnl, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayPositive = todayPnl >= 0;
    final totalPositive = totalPnl >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          MonoText('PORTFOLIO', size: 10, weight: FontWeight.w600, color: theme.textMuted),
          if (loading) ...[
            const SizedBox(width: 8),
            SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: theme.textMuted)),
          ],
        ]),
        const SizedBox(height: 4),
        MonoText(Fmt.usd(valueUsd), size: 32, weight: FontWeight.w700, color: theme.textPrimary),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(todayPositive ? Icons.trending_up : Icons.trending_down, size: 14, color: todayPositive ? theme.success : theme.danger),
            const SizedBox(width: 4),
            MonoText(Fmt.signedUsd(todayPnl), size: 14, weight: FontWeight.w600, color: todayPositive ? theme.success : theme.danger),
            const SizedBox(width: 12),
            MonoText('today', size: 12, weight: FontWeight.w400, color: theme.textMuted),
            const SizedBox(width: 20),
            MonoText(Fmt.signedUsd(totalPnl), size: 14, weight: FontWeight.w600, color: totalPositive ? theme.success : theme.danger),
            const SizedBox(width: 4),
            MonoText('total', size: 12, weight: FontWeight.w400, color: theme.textMuted),
          ],
        ),
      ],
    );
  }
}

class TickerStrip extends StatelessWidget {
  final List<dynamic> opportunities;
  const TickerStrip({super.key, required this.opportunities});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (opportunities.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 36,
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: theme.borderSubtle, width: 1)),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: opportunities.length,
        separatorBuilder: (_, __) => VerticalDivider(width: 1, color: theme.borderSubtle, indent: 10, endIndent: 10),
        itemBuilder: (context, i) {
          final o = opportunities[i];
          final positive = o.netProfitPct >= 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(children: [
              MonoText(o.pair, size: 12, weight: FontWeight.w600, color: theme.textPrimary),
              const SizedBox(width: 6),
              MonoText(Fmt.pct(o.netProfitPct), size: 11, weight: FontWeight.w600, color: positive ? theme.success : theme.danger),
            ]),
          );
        },
      ),
    );
  }
}

class _StrategyRow extends StatelessWidget {
  final Strategy strategy;
  const _StrategyRow({required this.strategy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = strategy.totalPnl >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ArbitronPanel(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strategy.name, style: theme.textTheme.titleMedium?.copyWith(color: theme.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(children: [
                    ModeChip(mode: strategy.mode, compact: true),
                    const SizedBox(width: 6),
                    MonoText('${strategy.totalTrades} trades', size: 11, weight: FontWeight.w400, color: theme.textMuted),
                  ]),
                ],
              ),
            ),
            MonoText(Fmt.signedUsd(strategy.totalPnl), size: 14, weight: FontWeight.w600, color: positive ? theme.success : theme.danger),
          ],
        ),
      ),
    );
  }
}

class _ExchangeStatusRow extends StatelessWidget {
  final String id;
  final String? status;
  const _ExchangeStatusRow({required this.id, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ex = ExchangeCatalog.byId(id);
    final connected = status == 'connected';
    final color = connected ? theme.accent : (status == 'connecting' ? theme.warning : (status == 'error' ? theme.danger : theme.textMuted));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ExchangeAvatar(name: ex.name, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(ex.name, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textPrimary))),
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          MonoText((status ?? 'disconnected').toUpperCase(), size: 10, weight: FontWeight.w600, color: color),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String? tradeError;
  final String? llmError;
  const _ErrorBanner({this.tradeError, this.llmError});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = tradeError ?? llmError;
    final isTrade = tradeError != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isTrade ? theme.danger.withOpacity(0.15) : theme.warning.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: isTrade ? theme.danger.withOpacity(0.3) : theme.warning.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(isTrade ? Icons.error_outline : Icons.warning_amber_outlined, size: 16, color: isTrade ? theme.danger : theme.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message!, style: theme.textTheme.bodySmall?.copyWith(color: isTrade ? theme.danger : theme.warning))),
        ]),
      ),
    );
  }
}

class _CommunityEntry extends StatelessWidget {
  final VoidCallback onTap;
  const _CommunityEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ArbitronPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(children: [
        Icon(Icons.leaderboard_outlined, color: theme.accent, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text('Leaderboard', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
        StatusChip(label: 'OPT IN', tone: ChipTone.neutral),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right, size: 18, color: theme.textMuted),
      ]),
    );
  }
}