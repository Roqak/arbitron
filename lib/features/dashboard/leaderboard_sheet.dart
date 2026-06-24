import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/leaderboard.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/widgets.dart';

/// Social leaderboard sheet (opt-in). See PRD §12 (v3.0 — Social leaderboard).
class LeaderboardSheet extends StatefulWidget {
  const LeaderboardSheet({super.key});

  @override
  State<LeaderboardSheet> createState() => _LeaderboardSheetState();
}

class _LeaderboardSheetState extends State<LeaderboardSheet> {
  bool _optedIn = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        final state = context.read<AppCubit>().state;
        final userWinRate = state.trades.isNotEmpty
            ? state.trades.where((t) => t.profit).length / state.trades.length
            : 0.0;
        final entries = LeaderboardService.generate(
          userPnl: state.totalPnl,
          userWinRate: userWinRate,
          userTrades: state.trades.length,
          userSharpe: 1.2,
          optedIn: _optedIn,
        );
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
                  Icon(Icons.leaderboard_outlined, color: theme.accent, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Leaderboard', style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Risk-adjusted P&L ranking. Opt in to share your stats and see your rank.', style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted)),
              const SizedBox(height: AppSpacing.lg),
              // Opt-in toggle
              ArbitronPanel(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Share my stats', style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('Display your P&L, win rate, and trade count on the public leaderboard.', style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted)),
                        ],
                      ),
                    ),
                    Switch(value: _optedIn, onChanged: (v) => setState(() => _optedIn = v), activeColor: theme.accent),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Top 3 podium
              if (entries.length >= 3) _Podium(top3: entries.take(3).toList()),
              const SizedBox(height: AppSpacing.lg),
              // Full list
              ...entries.map((e) => _LeaderboardRow(entry: e)),
            ],
          ),
        );
      },
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medals = ['🥇', '🥈', '🥉'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final e = top3[i];
        final height = i == 0 ? 100.0 : (i == 1 ? 80.0 : 70.0);
        return Column(
          children: [
            Text(medals[i], style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            _Avatar(name: e.displayName, isYou: e.isYou, size: 48),
            const SizedBox(height: 6),
            Text(e.displayName, style: theme.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600, color: e.isYou ? theme.accent : theme.textPrimary)),
            Text(Fmt.signedUsd(e.totalPnl), style: theme.textTheme.labelSmall!.copyWith(color: e.totalPnl >= 0 ? theme.success : theme.danger, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              width: 64, height: height,
              decoration: BoxDecoration(
                color: e.isYou ? theme.accentDim : theme.surfaceRaised,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: Border.all(color: e.isYou ? theme.accent : theme.borderSubtle, width: 1),
              ),
              child: Center(child: Text('#${e.rank}', style: theme.textTheme.titleLarge!.copyWith(color: e.isYou ? theme.accent : theme.textSecondary, fontWeight: FontWeight.w700))),
            ),
          ],
        );
      }),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ArbitronPanel(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(width: 32, child: Text('#${entry.rank}', style: theme.textTheme.titleMedium!.copyWith(color: entry.isYou ? theme.accent : theme.textMuted, fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]))),
            _Avatar(name: entry.displayName, isYou: entry.isYou, size: 32),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.displayName, style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600, color: entry.isYou ? theme.accent : theme.textPrimary)),
                  Text('${entry.totalTrades} trades \u00b7 ${(entry.winRate * 100).toStringAsFixed(0)}% win \u00b7 Sharpe ${entry.sharpeRatio.toStringAsFixed(2)}',
                      style: theme.textTheme.labelSmall!.copyWith(color: theme.textMuted)),
                ],
              ),
            ),
            Text(Fmt.signedUsd(entry.totalPnl),
                style: theme.textTheme.titleMedium!.copyWith(color: entry.totalPnl >= 0 ? theme.success : theme.danger, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final bool isYou;
  final double size;
  const _Avatar({required this.name, required this.isYou, required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: isYou ? theme.accent : theme.surfaceRaised,
        shape: BoxShape.circle,
        border: Border.all(color: isYou ? theme.accent : theme.borderSubtle, width: 1.5),
      ),
      child: Center(child: Text(letter, style: TextStyle(color: isYou ? theme.bg : theme.textSecondary, fontSize: size * 0.45, fontWeight: FontWeight.w700))),
    );
  }
}