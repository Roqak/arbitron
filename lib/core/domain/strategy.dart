import 'package:equatable/equatable.dart';
import 'enums.dart';
import 'exchange.dart';

/// A configured arbitrage strategy. See PRD §5.2.
class Strategy extends Equatable {
  final String id;
  final String name;
  final StrategyType type;
  final bool enabled;
  final ExecutionMode mode;
  final double minProfitUsd;
  final double maxTradeUsd;
  final int maxConcurrentPositions;
  final List<String> allowedPairs;
  final List<String> allowedExchangeIds;
  final Aggressiveness aggressiveness;
  final String customInstructions;
  final double stopLossDailyUsd;

  // Runtime stats (computed from trade history).
  final int totalTrades;
  final double winRate;
  final double totalPnl;

  const Strategy({
    required this.id,
    required this.name,
    required this.type,
    this.enabled = false,
    this.mode = ExecutionMode.manual,
    this.minProfitUsd = 10,
    this.maxTradeUsd = 1000,
    this.maxConcurrentPositions = 3,
    this.allowedPairs = const [],
    this.allowedExchangeIds = const [],
    this.aggressiveness = Aggressiveness.balanced,
    this.customInstructions = '',
    this.stopLossDailyUsd = 100,
    this.totalTrades = 0,
    this.winRate = 0,
    this.totalPnl = 0,
  });

  StrategyStatus get status {
    if (!enabled) return StrategyStatus.disabled;
    // We treat "enabled" as the lifecycle switch; pausing is a runtime flag
    // surfaced separately via the kill switch in the app state.
    return StrategyStatus.active;
  }

  Strategy copyWith({
    String? id,
    String? name,
    StrategyType? type,
    bool? enabled,
    ExecutionMode? mode,
    double? minProfitUsd,
    double? maxTradeUsd,
    int? maxConcurrentPositions,
    List<String>? allowedPairs,
    List<String>? allowedExchangeIds,
    Aggressiveness? aggressiveness,
    String? customInstructions,
    double? stopLossDailyUsd,
    int? totalTrades,
    double? winRate,
    double? totalPnl,
  }) {
    return Strategy(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      minProfitUsd: minProfitUsd ?? this.minProfitUsd,
      maxTradeUsd: maxTradeUsd ?? this.maxTradeUsd,
      maxConcurrentPositions: maxConcurrentPositions ?? this.maxConcurrentPositions,
      allowedPairs: allowedPairs ?? this.allowedPairs,
      allowedExchangeIds: allowedExchangeIds ?? this.allowedExchangeIds,
      aggressiveness: aggressiveness ?? this.aggressiveness,
      customInstructions: customInstructions ?? this.customInstructions,
      stopLossDailyUsd: stopLossDailyUsd ?? this.stopLossDailyUsd,
      totalTrades: totalTrades ?? this.totalTrades,
      winRate: winRate ?? this.winRate,
      totalPnl: totalPnl ?? this.totalPnl,
    );
  }

  /// List of [Exchange] objects resolved from [allowedExchangeIds].
  /// Empty list means "all enabled exchanges".
  List<Exchange> resolvedExchanges() => allowedExchangeIds.isEmpty
      ? ExchangeCatalog.all
      : allowedExchangeIds.map(ExchangeCatalog.byId).toList();

  @override
  List<Object?> get props => [
        id, name, type, enabled, mode, minProfitUsd, maxTradeUsd,
        maxConcurrentPositions, allowedPairs, allowedExchangeIds,
        aggressiveness, customInstructions, stopLossDailyUsd,
        totalTrades, winRate, totalPnl,
      ];

  // ── JSON persistence ─────────────────────────────────────────────────────────
  factory Strategy.fromJson(Map<String, dynamic> json) {
    return Strategy(
      id: json['id'] as String,
      name: json['name'] as String,
      type: StrategyType.values.byName(json['type'] as String? ?? 'simpleCrossExchange'),
      enabled: json['enabled'] as bool? ?? false,
      mode: ExecutionMode.values.byName(json['mode'] as String? ?? 'manual'),
      minProfitUsd: (json['minProfitUsd'] as num?)?.toDouble() ?? 10,
      maxTradeUsd: (json['maxTradeUsd'] as num?)?.toDouble() ?? 1000,
      maxConcurrentPositions: json['maxConcurrentPositions'] as int? ?? 3,
      allowedPairs: List<String>.from(json['allowedPairs'] as List? ?? const []),
      allowedExchangeIds: List<String>.from(json['allowedExchangeIds'] as List? ?? const []),
      aggressiveness: Aggressiveness.values.byName(json['aggressiveness'] as String? ?? 'balanced'),
      customInstructions: json['customInstructions'] as String? ?? '',
      stopLossDailyUsd: (json['stopLossDailyUsd'] as num?)?.toDouble() ?? 100,
      totalTrades: json['totalTrades'] as int? ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0,
      totalPnl: (json['totalPnl'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'type': type.name, 'enabled': enabled, 'mode': mode.name,
        'minProfitUsd': minProfitUsd, 'maxTradeUsd': maxTradeUsd,
        'maxConcurrentPositions': maxConcurrentPositions,
        'allowedPairs': allowedPairs, 'allowedExchangeIds': allowedExchangeIds,
        'aggressiveness': aggressiveness.name, 'customInstructions': customInstructions,
        'stopLossDailyUsd': stopLossDailyUsd,
        'totalTrades': totalTrades, 'winRate': winRate, 'totalPnl': totalPnl,
      };
}