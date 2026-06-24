import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/marketplace.dart';
import '../../core/domain/strategy.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/widgets.dart';

/// Strategy marketplace. Browse, preview stats, and install community
/// strategies. See PRD §12 (v3.0 — Strategy marketplace).
class MarketplaceSheet extends StatelessWidget {
  const MarketplaceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                children: [
                  Icon(Icons.storefront_outlined, color: theme.accent, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Marketplace', style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Browse and install community strategies. Preview backtest stats before installing.', style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted)),
              const SizedBox(height: AppSpacing.xl),
              ...MarketplaceCatalog.all.map((s) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: _MarketplaceCard(strategy: s))),
            ],
          ),
        );
      },
    );
  }
}

class _MarketplaceCard extends StatelessWidget {
  final MarketplaceStrategy strategy;
  const _MarketplaceCard({required this.strategy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = strategy;
    final positive = s.backtestPnl >= 0;
    return ArbitronCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('by ${s.author}', style: theme.textTheme.labelMedium!.copyWith(color: theme.textMuted)),
                  ],
                ),
              ),
              _RatingChip(rating: s.avgRating),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(s.description, style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary, height: 1.4)),
          const SizedBox(height: AppSpacing.md),
          // Tags
          Wrap(
            spacing: 6, runSpacing: 4,
            children: s.tags.map((t) => StatusChip(label: t, tone: ChipTone.neutral)).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          // Backtest stats
          Row(
            children: [
              _Stat(label: 'Win rate', value: '${(s.backtestWinRate * 100).toStringAsFixed(0)}%'),
              _Stat(label: 'Trades', value: '${s.backtestTrades}'),
              _Stat(label: 'P&L', value: Fmt.signedUsd(s.backtestPnl), color: positive ? theme.success : theme.danger),
              _Stat(label: 'Installs', value: '${s.installCount}'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Install button
          Row(
            children: [
              StatusChip(label: s.type.label, tone: ChipTone.info),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => _install(context, s),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.download_outlined, size: 16), SizedBox(width: 6), Text('Install')]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _install(BuildContext context, MarketplaceStrategy s) {
    final cubit = context.read<AppCubit>();
    final strategy = Strategy(
      id: 'mkt_${s.id}_${DateTime.now().millisecondsSinceEpoch}',
      name: s.name,
      type: s.type,
      enabled: false,
      mode: s.defaultMode,
      minProfitUsd: 10,
      maxTradeUsd: 1000,
      allowedExchangeIds: const [],
      customInstructions: s.description,
    );
    cubit.addStrategy(strategy);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${s.name} installed \u2014 enable it in Strategies'), duration: const Duration(seconds: 3)),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value, style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600, color: color ?? theme.textPrimary, fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.labelSmall!.copyWith(color: theme.textMuted)),
        ],
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final double rating;
  const _RatingChip({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: theme.warningDim, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: theme.warning),
          const SizedBox(width: 4),
          Text(rating.toStringAsFixed(1), style: theme.textTheme.labelMedium!.copyWith(color: theme.warning, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}