import 'package:equatable/equatable.dart';
import 'enums.dart';

/// A detected arbitrage opportunity. See PRD §8.2.
class Opportunity extends Equatable {
  final String id;
  final String pair; // e.g. "BTC/USDT"
  final String buyExchangeId;
  final String sellExchangeId;
  final double buyPrice;
  final double sellPrice;
  final double grossSpreadPct;
  final double estFeesUsd;
  final double estSlippageUsd;
  final double netProfitUsd;
  final double netProfitPct;
  final int confidenceScore; // 0..100
  final StrategyType strategy;
  final DateTime detectedAt;
  final String analysisText;
  final bool isLive;
  // Cross-chain bridge fields (v2.5). Null when no bridge is needed.
  final String? bridgeName;
  final double? bridgeCostUsd;
  final Duration? bridgeTime;

  const Opportunity({
    required this.id,
    required this.pair,
    required this.buyExchangeId,
    required this.sellExchangeId,
    required this.buyPrice,
    required this.sellPrice,
    required this.grossSpreadPct,
    required this.estFeesUsd,
    required this.estSlippageUsd,
    required this.netProfitUsd,
    required this.netProfitPct,
    required this.confidenceScore,
    required this.strategy,
    required this.detectedAt,
    this.analysisText = '',
    this.isLive = true,
    this.bridgeName,
    this.bridgeCostUsd,
    this.bridgeTime,
  });

  /// Whether this opportunity requires a cross-chain bridge.
  bool get requiresBridge => bridgeName != null;

  @override
  List<Object?> get props => [id];
}