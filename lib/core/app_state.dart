part of 'app_cubit.dart';

class AppState extends Equatable {
  final List<Strategy> strategies;
  final List<CustomStrategy> customStrategies;
  final List<String> enabledExchangeIds;
  final List<Opportunity> opportunities;
  final List<TradeRecord> trades;
  final LlmConfig llmConfig;
  final bool autonomousPaused;
  final double dailyLossCapUsd;
  final String themeBrightness; // 'dark' | 'light'
  final DateTime lastUpdated;
  final Map<String, String> feedStatuses;
  final bool feedsConnected;
  final bool llmConfigured;
  final DateTime? lastLlmAnalysisAt;
  final String? lastDailySummary;
  final DateTime? lastDailySummaryAt;
  final bool apiRunning;
  final int? apiPort;
  final String? apiToken;
  final double portfolioValue; // real, fetched from exchanges
  final bool executing; // a trade is being placed right now
  final bool portfolioLoading; // portfolio fetch in progress
  final String? llmError; // last LLM analysis error message
  final String? tradeError; // last trade execution error message

  const AppState({
    required this.strategies,
    this.customStrategies = const [],
    required this.enabledExchangeIds,
    required this.opportunities,
    required this.trades,
    required this.llmConfig,
    required this.autonomousPaused,
    required this.dailyLossCapUsd,
    required this.themeBrightness,
    required this.lastUpdated,
    this.feedStatuses = const {},
    this.feedsConnected = false,
    this.llmConfigured = false,
    this.lastLlmAnalysisAt,
    this.lastDailySummary,
    this.lastDailySummaryAt,
    this.apiRunning = false,
    this.apiPort,
    this.apiToken,
    this.portfolioValue = 0,
    this.executing = false,
    this.portfolioLoading = false,
    this.llmError,
    this.tradeError,
  });

  factory AppState.initial() {
    return AppState(
      strategies: _defaultStrategies,
      enabledExchangeIds: const ['binance', 'coinbase', 'kraken'],
      opportunities: const [], // empty — filled by live scanner only
      trades: const [], // empty — filled by real executions only
      llmConfig: const LlmConfig(),
      autonomousPaused: false,
      dailyLossCapUsd: 250,
      themeBrightness: 'dark',
      lastUpdated: DateTime.now(),
    );
  }

  /// Default strategies shipped with the app — all with zero stats. Stats
  /// are computed from real trades, not seeded.
  static const _defaultStrategies = [
    Strategy(id: 'strat_simple_1', name: 'Simple Cross-Exchange', type: StrategyType.simpleCrossExchange, enabled: true, mode: ExecutionMode.manual, minProfitUsd: 15, maxTradeUsd: 2000, allowedExchangeIds: ['binance', 'coinbase', 'kraken', 'okx', 'bybit']),
    Strategy(id: 'strat_tri_1', name: 'Triangular BTC/ETH/USDT', type: StrategyType.triangular, enabled: false, mode: ExecutionMode.semiAuto, minProfitUsd: 8, maxTradeUsd: 1500, allowedExchangeIds: ['binance']),
    Strategy(id: 'strat_dexcex_1', name: 'DEX-CEX ETH', type: StrategyType.dexCex, enabled: false, mode: ExecutionMode.autonomous, minProfitUsd: 25, maxTradeUsd: 3000, allowedExchangeIds: ['jupiter', 'binance']),
  ];

  AppState copyWith({
    List<Strategy>? strategies,
    List<CustomStrategy>? customStrategies,
    List<String>? enabledExchangeIds,
    List<Opportunity>? opportunities,
    List<TradeRecord>? trades,
    LlmConfig? llmConfig,
    bool? autonomousPaused,
    double? dailyLossCapUsd,
    String? themeBrightness,
    DateTime? lastUpdated,
    Map<String, String>? feedStatuses,
    bool? feedsConnected,
    bool? llmConfigured,
    DateTime? lastLlmAnalysisAt,
    String? lastDailySummary,
    DateTime? lastDailySummaryAt,
    bool? apiRunning,
    int? apiPort,
    String? apiToken,
    double? portfolioValue,
    bool? executing,
    bool? portfolioLoading,
    String? llmError,
    String? tradeError,
  }) {
    return AppState(
      strategies: strategies ?? this.strategies,
      customStrategies: customStrategies ?? this.customStrategies,
      enabledExchangeIds: enabledExchangeIds ?? this.enabledExchangeIds,
      opportunities: opportunities ?? this.opportunities,
      trades: trades ?? this.trades,
      llmConfig: llmConfig ?? this.llmConfig,
      autonomousPaused: autonomousPaused ?? this.autonomousPaused,
      dailyLossCapUsd: dailyLossCapUsd ?? this.dailyLossCapUsd,
      themeBrightness: themeBrightness ?? this.themeBrightness,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      feedStatuses: feedStatuses ?? this.feedStatuses,
      feedsConnected: feedsConnected ?? this.feedsConnected,
      llmConfigured: llmConfigured ?? this.llmConfigured,
      lastLlmAnalysisAt: lastLlmAnalysisAt ?? this.lastLlmAnalysisAt,
      lastDailySummary: lastDailySummary ?? this.lastDailySummary,
      lastDailySummaryAt: lastDailySummaryAt ?? this.lastDailySummaryAt,
      apiRunning: apiRunning ?? this.apiRunning,
      apiPort: apiPort ?? this.apiPort,
      apiToken: apiToken ?? this.apiToken,
      portfolioValue: portfolioValue ?? this.portfolioValue,
      executing: executing ?? this.executing,
      portfolioLoading: portfolioLoading ?? this.portfolioLoading,
      llmError: llmError,
      tradeError: tradeError,
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

  @override
  List<Object?> get props => [
        strategies, customStrategies, enabledExchangeIds, opportunities, trades, llmConfig,
        autonomousPaused, dailyLossCapUsd, themeBrightness, lastUpdated,
        feedStatuses, feedsConnected, llmConfigured, lastLlmAnalysisAt,
        lastDailySummary, lastDailySummaryAt, apiRunning, apiPort, apiToken,
        portfolioValue, executing, portfolioLoading, llmError, tradeError,
      ];

  // ── JSON persistence ─────────────────────────────────────────────────────────
  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      strategies: (json['strategies'] as List? ?? []).map((e) => Strategy.fromJson(e as Map<String, dynamic>)).toList(),
      customStrategies: (json['customStrategies'] as List? ?? []).map((e) => CustomStrategy.fromJson(e as Map<String, dynamic>)).toList(),
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
        'customStrategies': customStrategies.map((e) => e.toJson()).toList(),
        'enabledExchangeIds': enabledExchangeIds,
        'trades': trades.map((e) => e.toJson()).toList(),
        'llmConfig': llmConfig.toJson(),
        'autonomousPaused': autonomousPaused,
        'dailyLossCapUsd': dailyLossCapUsd,
        'themeBrightness': themeBrightness,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}