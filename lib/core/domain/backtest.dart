import 'package:equatable/equatable.dart';
import '../domain/enums.dart';

/// Result of a strategy backtest. See PRD §8.3 (Backtest result) and §12 (v2.5).
class BacktestResult extends Equatable {
  final String strategyId;
  final String strategyName;
  final StrategyType strategyType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalTrades;
  final int winningTrades;
  final double winRate; // 0..1
  final double totalPnl;
  final double maxDrawdown; // largest peak-to-trough drop, positive number
  final double avgProfitPerTrade;
  final double bestTradePnl;
  final double worstTradePnl;
  final double sharpeRatio; // simplified
  final List<BacktestEquityPoint> equityCurve;

  const BacktestResult({
    required this.strategyId,
    required this.strategyName,
    required this.strategyType,
    required this.startDate,
    required this.endDate,
    required this.totalTrades,
    required this.winningTrades,
    required this.winRate,
    required this.totalPnl,
    required this.maxDrawdown,
    required this.avgProfitPerTrade,
    required this.bestTradePnl,
    required this.worstTradePnl,
    required this.sharpeRatio,
    required this.equityCurve,
  });

  double get lossRate => 1 - winRate;

  @override
  List<Object?> get props => [strategyId, startDate, endDate, totalTrades, totalPnl];
}

/// A single point on the backtest equity curve.
class BacktestEquityPoint extends Equatable {
  final DateTime date;
  final double equity;
  final double cumulativePnl;

  const BacktestEquityPoint({required this.date, required this.equity, required this.cumulativePnl});

  @override
  List<Object?> get props => [date, equity];
}