part of 'app_cubit.dart';

class AppState extends Equatable {
  final List<Strategy> strategies;
  final List<String> enabledExchangeIds;
  final List<Opportunity> opportunities;
  final List<TradeRecord> trades;
  final LlmConfig llmConfig;
  final bool autonomousPaused;
  final double dailyLossCapUsd;
  final String themeBrightness; // 'dark' | 'light'
  final DateTime lastUpdated;

  const AppState({
    required this.strategies,
    required this.enabledExchangeIds,
    required this.opportunities,
    required this.trades,
    required this.llmConfig,
    required this.autonomousPaused,
    required this.dailyLossCapUsd,
    required this.themeBrightness,
    required this.lastUpdated,
  });

  factory AppState.initial() {
    final strategies = DemoDataService.defaultStrategies();
    final opps = DemoDataService.opportunities(count: 14);
    final trades = DemoDataService.tradeHistory(count: 18);
    return AppState(
      strategies: strategies,
      enabledExchangeIds: const ['binance', 'coinbase', 'kraken'],
      opportunities: opps,
      trades: trades,
      llmConfig: const LlmConfig(),
      autonomousPaused: false,
      dailyLossCapUsd: 250,
      themeBrightness: 'dark',
      lastUpdated: DateTime.now(),
    );
  }

  AppState copyWith({
    List<Strategy>? strategies,
    List<String>? enabledExchangeIds,
    List<Opportunity>? opportunities,
    List<TradeRecord>? trades,
    LlmConfig? llmConfig,
    bool? autonomousPaused,
    double? dailyLossCapUsd,
    String? themeBrightness,
    DateTime? lastUpdated,
  }) {
    return AppState(
      strategies: strategies ?? this.strategies,
      enabledExchangeIds: enabledExchangeIds ?? this.enabledExchangeIds,
      opportunities: opportunities ?? this.opportunities,
      trades: trades ?? this.trades,
      llmConfig: llmConfig ?? this.llmConfig,
      autonomousPaused: autonomousPaused ?? this.autonomousPaused,
      dailyLossCapUsd: dailyLossCapUsd ?? this.dailyLossCapUsd,
      themeBrightness: themeBrightness ?? this.themeBrightness,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // ── Derived getters ─────────────────────────────────────────────────────────
  List<Exchange> get enabledExchanges =>
      ExchangeCatalog.all.where((e) => enabledExchangeIds.contains(e.id)).toList();

  bool get anyAutonomousActive =>
      !autonomousPaused && strategies.any((s) => s.enabled && s.mode == ExecutionMode.autonomous);

  double get todayPnl => trades
      .where((t) => DateTime.now().difference(t.executedAt).inHours < 24)
      .fold(0.0, (sum, t) => sum + t.netPnl);

  double get totalPnl => trades.fold(0.0, (sum, t) => sum + t.netPnl);

  double get portfolioValue => 12480.00; // demo constant for MVP

  @override
  List<Object?> get props => [
        strategies, enabledExchangeIds, opportunities, trades, llmConfig,
        autonomousPaused, dailyLossCapUsd, themeBrightness, lastUpdated,
      ];

  // ── JSON persistence ─────────────────────────────────────────────────────────
  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      strategies: (json['strategies'] as List? ?? []).map((e) => Strategy.fromJson(e as Map<String, dynamic>)).toList(),
      enabledExchangeIds: List<String>.from(json['enabledExchangeIds'] as List? ?? const ['binance', 'coinbase', 'kraken']),
      opportunities: [], // don't persist ephemeral opportunities
      trades: (json['trades'] as List? ?? []).map((e) => TradeRecord.fromJson(e as Map<String, dynamic>)).toList(),
      llmConfig: LlmConfig.fromJson(json['llmConfig'] as Map<String, dynamic>?),
      autonomousPaused: json['autonomousPaused'] as bool? ?? false,
      dailyLossCapUsd: (json['dailyLossCapUsd'] as num?)?.toDouble() ?? 250,
      themeBrightness: json['themeBrightness'] as String? ?? 'dark',
      lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'strategies': strategies.map((e) => e.toJson()).toList(),
        'enabledExchangeIds': enabledExchangeIds,
        'trades': trades.map((e) => e.toJson()).toList(),
        'llmConfig': llmConfig.toJson(),
        'autonomousPaused': autonomousPaused,
        'dailyLossCapUsd': dailyLossCapUsd,
        'themeBrightness': themeBrightness,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}