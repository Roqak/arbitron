import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/backtest.dart';
import '../../core/domain/strategy.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/widgets.dart';

/// Backtest configuration + result sheet. Launched from the Strategies screen.
/// See PRD §8.3 (Backtest result) and §12 (v2.5).
class BacktestSheet extends StatefulWidget {
  final Strategy strategy;
  const BacktestSheet({super.key, required this.strategy});

  @override
  State<BacktestSheet> createState() => _BacktestSheetState();
}

class _BacktestSheetState extends State<BacktestSheet> {
  int _days = 30;
  double _capital = 10000;
  BacktestResult? _result;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _runBacktest();
  }

  Future<void> _runBacktest() async {
    setState(() => _running = true);
    await Future.delayed(const Duration(milliseconds: 400));
    final result = context.read<AppCubit>().runBacktest(strategy: widget.strategy, days: _days, startingCapital: _capital);
    if (mounted) setState(() { _result = result; _running = false; });
  }

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
                  Icon(Icons.science_outlined, color: theme.accent, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Backtest', style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(widget.strategy.name, style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              _ConfigRow(
                label: 'Period',
                child: SegmentedControl<int>(
                  segments: const [Segment(7, '7d'), Segment(30, '30d'), Segment(90, '90d')],
                  selected: _days,
                  onChanged: (v) { setState(() => _days = v); _runBacktest(); },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ConfigRow(
                label: 'Starting capital',
                child: Text(Fmt.usd(_capital, decimals: 0), style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_running)
                const Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: Center(child: CircularProgressIndicator()))
              else if (_result != null)
                _BacktestResultView(result: _result!),
            ],
          ),
        );
      },
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _ConfigRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary)),
        SizedBox(width: 220, child: child),
      ],
    );
  }
}

class _BacktestResultView extends StatelessWidget {
  final BacktestResult result;
  const _BacktestResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profitable = result.totalPnl >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Headline P&L
        ArbitronPanel(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Net P&L', style: theme.textTheme.labelMedium!.copyWith(color: theme.textSecondary)),
                  Text(Fmt.signedUsd(result.totalPnl),
                      style: theme.textTheme.displayMedium!.copyWith(
                          color: profitable ? theme.success : theme.danger, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Stat(label: 'Trades', value: '${result.totalTrades}'),
                  _Stat(label: 'Win rate', value: '${(result.winRate * 100).toStringAsFixed(0)}%'),
                  _Stat(label: 'Max DD', value: Fmt.usd(result.maxDrawdown, decimals: 0), color: theme.danger),
                  _Stat(label: 'Sharpe', value: result.sharpeRatio.toStringAsFixed(2)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Equity curve
        Text('Equity Curve', style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.md),
        _EquityCurveChart(result: result),
        const SizedBox(height: AppSpacing.lg),
        // Detailed stats
        ArbitronPanel(
          child: Column(
            children: [
              _DetailRow(label: 'Period', value: '${Fmt.date(result.startDate)} \u2013 ${Fmt.date(result.endDate)}'),
              _DetailRow(label: 'Winning trades', value: '${result.winningTrades} / ${result.totalTrades}'),
              _DetailRow(label: 'Avg profit / trade', value: Fmt.signedUsd(result.avgProfitPerTrade), color: result.avgProfitPerTrade >= 0 ? theme.success : theme.danger),
              _DetailRow(label: 'Best trade', value: Fmt.signedUsd(result.bestTradePnl), color: theme.success),
              _DetailRow(label: 'Worst trade', value: Fmt.signedUsd(result.worstTradePnl), color: theme.danger),
              _DetailRow(label: 'Max drawdown', value: Fmt.usd(result.maxDrawdown, decimals: 0), color: theme.danger),
              _DetailRow(label: 'Sharpe ratio', value: result.sharpeRatio.toStringAsFixed(2)),
            ],
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600, color: color ?? theme.textPrimary, fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall!.copyWith(color: theme.textMuted)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _DetailRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary)),
          Text(value, style: theme.textTheme.bodyMedium!.copyWith(color: color ?? theme.textPrimary, fontWeight: FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

class _EquityCurveChart extends StatelessWidget {
  final BacktestResult result;
  const _EquityCurveChart({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = result.equityCurve.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.equity)).toList();
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final profitable = result.totalPnl >= 0;
    final lineColor = profitable ? AppColors.accent : AppColors.danger;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (v) => FlLine(color: theme.borderSubtle, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: (maxY - minY) / 3,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(Fmt.compactUsd(value), style: theme.textTheme.labelSmall!.copyWith(color: theme.textMuted, fontFeatures: const [FontFeature.tabularFigures()]), textAlign: TextAlign.right),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.12),
              ),
            ),
          ],
          minY: minY,
          maxY: maxY,
        ),
      ),
    );
  }
}