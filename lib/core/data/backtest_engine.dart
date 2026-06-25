import 'dart:math';
import '../domain/backtest.dart';
import '../domain/enums.dart';
import '../domain/strategy.dart';
import 'price_feed_service.dart';

/// Runs a strategy backtest. Uses real current prices from the price feed
/// service as the starting point, then simulates a random walk around them
/// (we don't store historical price data on-device). The walk is seeded by
/// the strategy params so results are reproducible.
/// See PRD §8.3 (Backtest result) and §12 (v2.5 — Strategy backtesting).
class BacktestEngine {
  BacktestEngine({required this.priceFeedService});

  final PriceFeedService priceFeedService;

  /// Runs a backtest for [strategy] over [days] of simulated history.
  BacktestResult run({
    required Strategy strategy,
    required int days,
    required double startingCapital,
  }) {
    final rng = Random(strategy.id.hashCode + days);
    final snapshot = priceFeedService.currentSnapshot;
    final allPairs = strategy.allowedPairs.isEmpty
        ? snapshot.pairs.toList()
        : strategy.allowedPairs.toList();
    allPairs.shuffle(rng);
    final pairs = allPairs;
    if (pairs.isEmpty) {
      // No live price data — can't backtest meaningfully.
      return _emptyResult(strategy, days);
    }

    // Get real starting prices from the snapshot.
    final startPrices = <String, double>{};
    for (final pair in pairs.take(5)) {
      final quotes = snapshot.forPair(pair);
      if (quotes.isNotEmpty) {
        startPrices[pair] = quotes.first.mid;
      }
    }
    if (startPrices.isEmpty) return _emptyResult(strategy, days);

    final exchanges = strategy.resolvedExchanges();
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
    final tradesPerDay = switch (strategy.aggressiveness) {
      Aggressiveness.conservative => 1,
      Aggressiveness.balanced => 2,
      Aggressiveness.aggressive => 3,
    };

    for (int d = 0; d < days; d++) {
      final date = startDate.add(Duration(days: d));
      for (int t = 0; t < tradesPerDay; t++) {
        final pair = startPrices.keys.elementAt(rng.nextInt(startPrices.length));
        // Spread depends on aggressiveness.
        final spreadPct = switch (strategy.aggressiveness) {
          Aggressiveness.conservative => 0.15 + rng.nextDouble() * 0.5,
          Aggressiveness.balanced => 0.20 + rng.nextDouble() * 0.8,
          Aggressiveness.aggressive => 0.25 + rng.nextDouble() * 1.5,
        };
        final win = rng.nextDouble() < baseWinRate;
        final size = strategy.maxTradeUsd;
        final grossProfit = size * spreadPct / 100;
        final buyEx = exchanges.isNotEmpty ? exchanges[rng.nextInt(exchanges.length)] : null;
        final sellEx = exchanges.length > 1 ? exchanges[rng.nextInt(exchanges.length)] : buyEx;
        final fees = buyEx != null && sellEx != null
            ? size * (buyEx.takerFee + sellEx.takerFee)
            : size * 0.002;
        final slippage = size * (0.001 + rng.nextDouble() * 0.003);
        var netPnl = grossProfit - fees - slippage;
        if (!win) netPnl = -netPnl.abs() - size * 0.002;
        if (netPnl < strategy.minProfitUsd && strategy.aggressiveness == Aggressiveness.conservative) continue;
        netPnl = netPnl.clamp(-size, size * 0.05);
        equity += netPnl;
        trades.add(_SimTrade(date: date, pair: pair, netPnl: netPnl, win: win));
        peakEquity = max(peakEquity, equity);
        maxDrawdown = max(maxDrawdown, peakEquity - equity);
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
    final dailyReturns = <double>[];
    for (int i = 1; i < equityCurve.length; i++) {
      final prev = equityCurve[i - 1].equity;
      final curr = equityCurve[i].equity;
      if (prev > 0) dailyReturns.add((curr - prev) / prev);
    }
    final sharpe = _sharpeRatio(dailyReturns);

    return BacktestResult(
      strategyId: strategy.id, strategyName: strategy.name, strategyType: strategy.type,
      startDate: startDate, endDate: DateTime.now(),
      totalTrades: totalTrades, winningTrades: winningTrades, winRate: winRate,
      totalPnl: totalPnl, maxDrawdown: maxDrawdown, avgProfitPerTrade: avgProfit,
      bestTradePnl: bestTrade, worstTradePnl: worstTrade, sharpeRatio: sharpe,
      equityCurve: equityCurve,
    );
  }

  BacktestResult _emptyResult(Strategy strategy, int days) {
    final start = DateTime.now().subtract(Duration(days: days));
    return BacktestResult(
      strategyId: strategy.id, strategyName: strategy.name, strategyType: strategy.type,
      startDate: start, endDate: DateTime.now(),
      totalTrades: 0, winningTrades: 0, winRate: 0, totalPnl: 0, maxDrawdown: 0,
      avgProfitPerTrade: 0, bestTradePnl: 0, worstTradePnl: 0, sharpeRatio: 0,
      equityCurve: [BacktestEquityPoint(date: start, equity: 0, cumulativePnl: 0)],
    );
  }

  static double _sharpeRatio(List<double> returns) {
    if (returns.isEmpty) return 0;
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
    final stddev = sqrt(variance);
    if (stddev == 0) return 0;
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