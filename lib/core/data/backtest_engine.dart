import 'dart:math';
import '../domain/backtest.dart';
import '../domain/enums.dart';
import '../domain/strategy.dart';

/// Runs a strategy backtest against simulated historical price data. In a full
/// implementation this would replay historical candles/tickers; for v2.5 we
/// generate deterministic synthetic price walks seeded by the strategy params
/// so results are reproducible and reflect the strategy's risk profile.
/// See PRD §8.3 (Backtest result) and §12 (v2.5 — Strategy backtesting).
class BacktestEngine {
  BacktestEngine._();

  /// Runs a backtest for [strategy] over [days] of simulated history.
  static BacktestResult run({
    required Strategy strategy,
    required int days,
    required double startingCapital,
  }) {
    final rng = Random(strategy.id.hashCode + days);
    final exchanges = strategy.resolvedExchanges();
    final pairs = strategy.allowedPairs.isEmpty
        ? ['BTC/USDT', 'ETH/USDT', 'SOL/USDT', 'BNB/USDT', 'XRP/USDT']
        : strategy.allowedPairs;

    // Generate a daily series of synthetic trades.
    final trades = <_SimTrade>[];
    var equity = startingCapital;
    var peakEquity = startingCapital;
    var maxDrawdown = 0.0;
    final equityCurve = <BacktestEquityPoint>[];

    final startDate = DateTime.now().subtract(Duration(days: days));
    final baseWinRate = switch (strategy.aggressiveness) {
      Aggressiveness.conservative => 0.62,
      Aggressiveness.balanced => 0.55,
      Aggressiveness.aggressive => 0.48,
    };
    // More trades per day for more aggressive strategies.
    final tradesPerDay = switch (strategy.aggressiveness) {
      Aggressiveness.conservative => 1,
      Aggressiveness.balanced => 2,
      Aggressiveness.aggressive => 3,
    };

    for (int d = 0; d < days; d++) {
      final date = startDate.add(Duration(days: d));
      for (int t = 0; t < tradesPerDay; t++) {
        final pair = pairs[rng.nextInt(pairs.length)];
        final buyEx = exchanges[rng.nextInt(exchanges.length)];
        var sellEx = exchanges[rng.nextInt(exchanges.length)];
        while (sellEx.id == buyEx.id && exchanges.length > 1) {
          sellEx = exchanges[rng.nextInt(exchanges.length)];
        }
        // Spread magnitude depends on aggressiveness + randomness.
        final spreadPct = switch (strategy.aggressiveness) {
          Aggressiveness.conservative => 0.15 + rng.nextDouble() * 0.5,
          Aggressiveness.balanced => 0.20 + rng.nextDouble() * 0.8,
          Aggressiveness.aggressive => 0.25 + rng.nextDouble() * 1.5,
        };
        // Win probability.
        final win = rng.nextDouble() < baseWinRate;
        // Size capped by strategy max trade.
        final size = strategy.maxTradeUsd;
        // Gross profit from spread, minus fees + slippage.
        final grossProfit = size * spreadPct / 100;
        final fees = size * (buyEx.takerFee + sellEx.takerFee);
        final slippage = size * (0.001 + rng.nextDouble() * 0.003);
        var netPnl = grossProfit - fees - slippage;
        if (!win) {
          // Losing trade: slippage exceeds the edge.
          netPnl = -netPnl.abs() - size * 0.002;
        }
        // Apply min profit threshold filter (conservative skips sub-threshold).
        if (netPnl < strategy.minProfitUsd && strategy.aggressiveness == Aggressiveness.conservative) {
          continue;
        }
        netPnl = netPnl.clamp(-size, size * 0.05);
        equity += netPnl;
        trades.add(_SimTrade(date: date, pair: pair, netPnl: netPnl, win: win));
        peakEquity = max(peakEquity, equity);
        final drawdown = peakEquity - equity;
        maxDrawdown = max(maxDrawdown, drawdown);
      }
      equityCurve.add(BacktestEquityPoint(date: date, equity: equity, cumulativePnl: equity - startingCapital));
    }

    final totalTrades = trades.length;
    final winningTrades = trades.where((t) => t.win).length;
    final winRate = totalTrades > 0 ? winningTrades / totalTrades : 0.0;
    final totalPnl = equity - startingCapital;
    final avgProfit = totalTrades > 0 ? totalPnl / totalTrades : 0.0;
    final pnls = trades.map((t) => t.netPnl).toList();
    final bestTrade = pnls.isEmpty ? 0.0 : pnls.reduce(max);
    final worstTrade = pnls.isEmpty ? 0.0 : pnls.reduce(min);
    // Simplified Sharpe: mean / stddev of daily returns.
    final dailyReturns = <double>[];
    for (int i = 1; i < equityCurve.length; i++) {
      final prev = equityCurve[i - 1].equity;
      final curr = equityCurve[i].equity;
      if (prev > 0) dailyReturns.add((curr - prev) / prev);
    }
    final sharpe = _sharpeRatio(dailyReturns);

    return BacktestResult(
      strategyId: strategy.id,
      strategyName: strategy.name,
      strategyType: strategy.type,
      startDate: startDate,
      endDate: DateTime.now(),
      totalTrades: totalTrades,
      winningTrades: winningTrades,
      winRate: winRate,
      totalPnl: totalPnl,
      maxDrawdown: maxDrawdown,
      avgProfitPerTrade: avgProfit,
      bestTradePnl: bestTrade,
      worstTradePnl: worstTrade,
      sharpeRatio: sharpe,
      equityCurve: equityCurve,
    );
  }

  static double _sharpeRatio(List<double> returns) {
    if (returns.isEmpty) return 0;
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
    final stddev = sqrt(variance);
    if (stddev == 0) return 0;
    // Annualized (daily returns * sqrt(365)).
    return (mean / stddev) * sqrt(365);
  }
}

class _SimTrade {
  final DateTime date;
  final String pair;
  final double netPnl;
  final bool win;
  _SimTrade({required this.date, required this.pair, required this.netPnl, required this.win});
}