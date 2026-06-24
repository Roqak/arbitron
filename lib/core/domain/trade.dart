import 'package:equatable/equatable.dart';
import 'enums.dart';

/// An executed trade recorded in the audit log. See PRD §8.5.
class TradeRecord extends Equatable {
  final String id;
  final DateTime executedAt;
  final String strategyId;
  final String strategyName;
  final StrategyType strategyType;
  final String pair;
  final String buyExchangeId;
  final String sellExchangeId;
  final double sizeUsd;
  final double entryPrice;
  final double exitPrice;
  final double grossPnl;
  final double netPnl;
  final double feesUsd;
  final double slippageUsd;
  final ExecutionMode mode;
  final String llmDecisionJson;
  final String debrief;
  final bool profit;

  const TradeRecord({
    required this.id,
    required this.executedAt,
    required this.strategyId,
    required this.strategyName,
    required this.strategyType,
    required this.pair,
    required this.buyExchangeId,
    required this.sellExchangeId,
    required this.sizeUsd,
    required this.entryPrice,
    required this.exitPrice,
    required this.grossPnl,
    required this.netPnl,
    required this.feesUsd,
    required this.slippageUsd,
    required this.mode,
    this.llmDecisionJson = '',
    this.debrief = '',
    this.profit = true,
  });

  @override
  List<Object?> get props => [id];

  // ── JSON persistence ─────────────────────────────────────────────────────────
  factory TradeRecord.fromJson(Map<String, dynamic> json) {
    return TradeRecord(
      id: json['id'] as String,
      executedAt: DateTime.tryParse(json['executedAt'] as String? ?? '') ?? DateTime.now(),
      strategyId: json['strategyId'] as String,
      strategyName: json['strategyName'] as String,
      strategyType: StrategyType.values.byName(json['strategyType'] as String? ?? 'simpleCrossExchange'),
      pair: json['pair'] as String,
      buyExchangeId: json['buyExchangeId'] as String,
      sellExchangeId: json['sellExchangeId'] as String,
      sizeUsd: (json['sizeUsd'] as num?)?.toDouble() ?? 0,
      entryPrice: (json['entryPrice'] as num?)?.toDouble() ?? 0,
      exitPrice: (json['exitPrice'] as num?)?.toDouble() ?? 0,
      grossPnl: (json['grossPnl'] as num?)?.toDouble() ?? 0,
      netPnl: (json['netPnl'] as num?)?.toDouble() ?? 0,
      feesUsd: (json['feesUsd'] as num?)?.toDouble() ?? 0,
      slippageUsd: (json['slippageUsd'] as num?)?.toDouble() ?? 0,
      mode: ExecutionMode.values.byName(json['mode'] as String? ?? 'manual'),
      llmDecisionJson: json['llmDecisionJson'] as String? ?? '',
      debrief: json['debrief'] as String? ?? '',
      profit: json['profit'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'executedAt': executedAt.toIso8601String(),
        'strategyId': strategyId, 'strategyName': strategyName, 'strategyType': strategyType.name,
        'pair': pair, 'buyExchangeId': buyExchangeId, 'sellExchangeId': sellExchangeId,
        'sizeUsd': sizeUsd, 'entryPrice': entryPrice, 'exitPrice': exitPrice,
        'grossPnl': grossPnl, 'netPnl': netPnl, 'feesUsd': feesUsd, 'slippageUsd': slippageUsd,
        'mode': mode.name, 'llmDecisionJson': llmDecisionJson, 'debrief': debrief, 'profit': profit,
      };
}