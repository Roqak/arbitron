import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'domain/enums.dart';
import 'domain/exchange.dart';
import 'domain/llm_config.dart';
import 'domain/llm_result.dart';
import 'domain/opportunity.dart';
import 'domain/strategy.dart';
import 'domain/trade.dart';
import 'domain/custom_strategy.dart';
import 'data/demo_data_service.dart';
import 'data/price_feed_service.dart';
import 'data/price_feed.dart';
import 'data/opportunity_scanner.dart';
import 'data/secure_key_store.dart';
import 'data/llm_service.dart';
import 'data/api_server.dart';

part 'app_state.dart';

/// The pairs monitored by the live feed. For MVP we watch the top 10 by
/// volume; users will be able to customize this in a later release.
const List<String> _monitoredPairs = [
  'BTC/USDT', 'ETH/USDT', 'SOL/USDT', 'BNB/USDT', 'XRP/USDT',
  'ADA/USDT', 'DOGE/USDT', 'AVAX/USDT', 'LINK/USDT', 'MATIC/USDT',
];

/// Max opportunities to send to the LLM per scan batch (rate-limit safeguard).
const int _maxLlmBatch = 5;

class AppCubit extends HydratedCubit<AppState> {
  AppCubit() : super(AppState.initial()) {
    _initLiveFeeds();
    _checkLlmConfigured();
  }

  late final PriceFeedService _priceFeedService = PriceFeedService();
  late final OpportunityScanner _scanner = OpportunityScanner(priceFeedService: _priceFeedService);
  late final SecureKeyStore _keyStore = SecureKeyStore();
  late final LlmService _llm = LlmService(keyStore: _keyStore);
  ApiServer? _apiServer;

  bool get apiRunning => _apiServer?.isRunning ?? false;
  int? get apiPort => _apiServer?.port;
  String? get apiToken => _apiServer?.token;

  Future<void> startApiServer({int port = 8765, required String token}) async {
    _apiServer = ApiServer(cubit: this);
    await _apiServer!.start(port: port, token: token);
    emit(state.copyWith(apiRunning: true, apiPort: port, apiToken: token));
  }

  Future<void> stopApiServer() async {
    await _apiServer?.stop();
    _apiServer = null;
    emit(state.copyWith(apiRunning: false, apiPort: null, apiToken: null));
  }

  StreamSubscription<Map<String, FeedStatus>>? _statusSub;
  StreamSubscription<List<Opportunity>>? _oppSub;
  bool _feedsStarted = false;

  // Track which opportunities we've already analyzed to avoid duplicate calls.
  final Set<String> _analyzedOppIds = {};
  // Track in-flight analysis to avoid overlapping calls for the same opp.
  final Set<String> _inFlight = {};
  Timer? _dailySummaryTimer;

  void _initLiveFeeds() {
    // Sync trade history to the LLM service for in-context fine-tuning (v2.5).
    _llm.tradeHistory = state.trades;
    // Seed demo opportunities so the UI has content while feeds connect.
    emit(state.copyWith(
      opportunities: DemoDataService.opportunities(count: 14),
      lastUpdated: DateTime.now(),
    ));

    _statusSub = _priceFeedService.statusChanges.listen(_onFeedStatus);
    _oppSub = _scanner.opportunities.listen(_onOpportunities);
    _scanner.start();
    _restartFeeds();
    _scheduleDailySummary();
  }

  Future<void> _checkLlmConfigured() async {
    final configured = await _llm.isConfigured();
    if (state.llmConfigured != configured) {
      emit(state.copyWith(llmConfigured: configured));
    }
  }

  void _restartFeeds() {
    final supported = state.enabledExchangeIds.where((id) => _supportedFeedIds.contains(id)).toList();
    if (supported.isEmpty) return;
    _priceFeedService.start(enabledExchangeIds: supported, pairs: _monitoredPairs);
    _feedsStarted = true;
  }

  static const _supportedFeedIds = {'binance', 'coinbase', 'kraken', 'okx', 'bybit', 'kucoin', 'gate', 'bitfinex', 'huobi', 'mexc', 'jupiter'};

  void _onFeedStatus(Map<String, FeedStatus> statuses) {
    final anyConnected = statuses.values.any((s) => s == FeedStatus.connected);
    emit(state.copyWith(
      feedStatuses: statuses.map((k, v) => MapEntry(k, v.name)),
      feedsConnected: anyConnected,
    ));
  }

  void _onOpportunities(List<Opportunity> opps) {
    if (opps.isEmpty) return;
    emit(state.copyWith(opportunities: opps, lastUpdated: DateTime.now()));
    // Trigger LLM analysis for top opportunities if configured.
    _maybeAnalyzeBatch(opps);
  }

  // ── LLM analysis ────────────────────────────────────────────────────────────
  Future<void> _maybeAnalyzeBatch(List<Opportunity> opps) async {
    if (!state.llmConfigured) return;
    final toAnalyze = opps.take(_maxLlmBatch).where((o) {
      final key = '${o.id}';
      return !_analyzedOppIds.contains(key) && !_inFlight.contains(key);
    }).toList();
    if (toAnalyze.isEmpty) return;

    for (final o in toAnalyze) {
      _inFlight.add(o.id);
      _analyzeOpportunity(o);
    }
  }

  Future<void> _analyzeOpportunity(Opportunity o) async {
    final strategy = state.strategies.firstWhere(
      (s) => s.type == o.strategy,
      orElse: () => state.strategies.first,
    );
    final analysis = await _llm.analyzeOpportunity(
      config: state.llmConfig,
      opportunity: o,
      strategy: strategy,
      customInstructions: strategy.customInstructions,
    );
    _inFlight.remove(o.id);
    if (analysis == null) return; // LLM failed; keep scanner-generated analysis
    _analyzedOppIds.add(o.id);

    // Enrich the opportunity with the LLM analysis text + score.
    final enriched = Opportunity(
      id: o.id,
      pair: o.pair,
      buyExchangeId: o.buyExchangeId,
      sellExchangeId: o.sellExchangeId,
      buyPrice: o.buyPrice,
      sellPrice: o.sellPrice,
      grossSpreadPct: o.grossSpreadPct,
      estFeesUsd: o.estFeesUsd,
      estSlippageUsd: o.estSlippageUsd,
      netProfitUsd: o.netProfitUsd,
      netProfitPct: o.netProfitPct,
      confidenceScore: analysis.score,
      strategy: o.strategy,
      detectedAt: o.detectedAt,
      analysisText: analysis.explanation,
      isLive: o.isLive,
    );

    final updated = state.opportunities.map((e) => e.id == o.id ? enriched : e).toList();
    emit(state.copyWith(opportunities: updated, lastLlmAnalysisAt: DateTime.now()));

    // If autonomous mode is active, request an execution decision.
    if (anyAutonomousActive && analysis.score >= 60) {
      _maybeExecuteAutonomously(enriched, analysis, strategy);
    }
  }

  // ── Autonomous execution ────────────────────────────────────────────────────
  Future<void> _maybeExecuteAutonomously(Opportunity o, LlmAnalysis analysis, Strategy strategy) async {
    if (state.autonomousPaused) return;
    if (strategy.mode != ExecutionMode.autonomous || !strategy.enabled) return;

    final decision = await _llm.executionDecision(
      config: state.llmConfig,
      opportunity: o,
      analysis: analysis,
      strategy: strategy,
      portfolioExposure: state.portfolioValue,
      openPositions: 0,
      dailyPnl: state.todayPnl,
    );
    if (decision == null || !decision.execute) return;

    // Risk guards (PRD §11.1).
    if (state.todayPnl < -state.dailyLossCapUsd) return;
    if (decision.suggestedSizeUsd > strategy.maxTradeUsd) return;

    executeOpportunity(o, mode: ExecutionMode.autonomous);
  }

  // ── Custom strategies (no-code builder) ────────────────────────────────────
  void addCustomStrategy(CustomStrategy s) => emit(state.copyWith(customStrategies: [...state.customStrategies, s]));
  void removeCustomStrategy(String id) => emit(state.copyWith(customStrategies: state.customStrategies.where((e) => e.id != id).toList()));

  // ── Strategies ─────────────────────────────────────────────────────────────
  void addStrategy(Strategy s) => emit(state.copyWith(strategies: [...state.strategies, s]));
  void updateStrategy(Strategy s) => emit(state.copyWith(strategies: state.strategies.map((e) => e.id == s.id ? s : e).toList()));
  void removeStrategy(String id) => emit(state.copyWith(strategies: state.strategies.where((e) => e.id != id).toList()));
  void toggleStrategyEnabled(String id) {
    emit(state.copyWith(
      strategies: state.strategies.map((e) => e.id == id ? e.copyWith(enabled: !e.enabled) : e).toList(),
    ));
  }
  void setStrategyMode(String id, ExecutionMode mode) {
    emit(state.copyWith(strategies: state.strategies.map((e) => e.id == id ? e.copyWith(mode: mode) : e).toList()));
  }

  // ── Exchanges ──────────────────────────────────────────────────────────────
  void setExchangeEnabled(String id, bool enabled) {
    emit(state.copyWith(
      enabledExchangeIds: enabled
          ? [...state.enabledExchangeIds, id]
          : state.enabledExchangeIds.where((e) => e != id).toList(),
    ));
    if (_supportedFeedIds.contains(id)) _restartFeeds();
  }

  // ── Kill switch ─────────────────────────────────────────────────────────────
  void pauseAllAutonomous() => emit(state.copyWith(autonomousPaused: true));
  void resumeAutonomous() => emit(state.copyWith(autonomousPaused: false));

  bool get anyAutonomousActive =>
      !state.autonomousPaused &&
      state.strategies.any((s) => s.enabled && s.mode == ExecutionMode.autonomous);

  // ── Opportunities ──────────────────────────────────────────────────────────
  void refreshOpportunities() {
    emit(state.copyWith(
      opportunities: DemoDataService.opportunities(count: 14),
      lastUpdated: DateTime.now(),
    ));
    if (!_feedsStarted) _restartFeeds();
  }

  // ── Trades ────────────────────────────────────────────────────────────────
  void executeOpportunity(Opportunity o, {ExecutionMode? mode}) {
    final strategy = state.strategies.firstWhere(
      (s) => s.type == o.strategy,
      orElse: () => state.strategies.first,
    );
    final trade = TradeRecord(
      id: 'trade_${DateTime.now().millisecondsSinceEpoch}',
      executedAt: DateTime.now(),
      strategyId: strategy.id,
      strategyName: strategy.name,
      strategyType: strategy.type,
      pair: o.pair,
      buyExchangeId: o.buyExchangeId,
      sellExchangeId: o.sellExchangeId,
      sizeUsd: strategy.maxTradeUsd,
      entryPrice: o.buyPrice,
      exitPrice: o.sellPrice,
      grossPnl: o.netProfitUsd + o.estFeesUsd + o.estSlippageUsd,
      netPnl: o.netProfitUsd,
      feesUsd: o.estFeesUsd,
      slippageUsd: o.estSlippageUsd,
      mode: mode ?? strategy.mode,
      profit: o.netProfitUsd >= 0,
      llmDecisionJson: o.analysisText,
      debrief: o.netProfitUsd >= 0
          ? 'Trade captured the full spread with slippage within expectations.'
          : 'Slippage exceeded estimate and eroded the edge.',
    );
    emit(state.copyWith(trades: [trade, ...state.trades]));
    // Keep the LLM's trade history context up to date (v2.5 fine-tuning).
    _llm.tradeHistory = [trade, ...state.trades];
    // Generate an LLM debrief if configured.
    _maybeGenerateDebrief(trade);
  }

  Future<void> _maybeGenerateDebrief(TradeRecord trade) async {
    if (!state.llmConfigured) return;
    final debrief = await _llm.postTradeDebrief(config: state.llmConfig, trade: trade);
    if (debrief == null) return;
    final updated = state.trades.map((t) => t.id == trade.id ? TradeRecord(
      id: t.id, executedAt: t.executedAt, strategyId: t.strategyId, strategyName: t.strategyName,
      strategyType: t.strategyType, pair: t.pair, buyExchangeId: t.buyExchangeId, sellExchangeId: t.sellExchangeId,
      sizeUsd: t.sizeUsd, entryPrice: t.entryPrice, exitPrice: t.exitPrice, grossPnl: t.grossPnl, netPnl: t.netPnl,
      feesUsd: t.feesUsd, slippageUsd: t.slippageUsd, mode: t.mode, llmDecisionJson: t.llmDecisionJson,
      debrief: debrief, profit: t.profit,
    ) : t).toList();
    emit(state.copyWith(trades: updated));
  }

  // ── Daily summary ───────────────────────────────────────────────────────────
  void _scheduleDailySummary() {
    _dailySummaryTimer?.cancel();
    // Check every hour if it's time for a daily summary (default: 20:00 local).
    _dailySummaryTimer = Timer.periodic(const Duration(hours: 1), (_) {
      final now = DateTime.now();
      if (now.hour == 20 && now.minute < 5) {
        _maybeGenerateDailySummary();
      }
    });
  }

  Future<void> _maybeGenerateDailySummary() async {
    if (!state.llmConfigured) return;
    final todayTrades = state.trades.where((t) => DateTime.now().difference(t.executedAt).inHours < 24).toList();
    if (todayTrades.isEmpty) return;
    final summary = await _llm.dailySummary(
      config: state.llmConfig,
      trades: todayTrades,
      totalPnl: state.todayPnl,
    );
    if (summary == null) return;
    emit(state.copyWith(lastDailySummary: summary.narrative, lastDailySummaryAt: DateTime.now()));
  }

  /// Manually trigger the daily summary (for the Settings screen).
  Future<void> generateDailySummary() async => _maybeGenerateDailySummary();

  // ── LLM config ──────────────────────────────────────────────────────────────
  Future<void> saveLlmConfig(LlmConfig config, String? apiKey) async {
    emit(state.copyWith(llmConfig: config));
    if (apiKey != null && apiKey.isNotEmpty) {
      await _keyStore.writeApiKey(apiKey);
    }
    await _checkLlmConfigured();
  }

  Future<void> clearLlmKey() async {
    await _keyStore.deleteApiKey();
    await _checkLlmConfigured();
  }

  /// Fetches available models from the configured endpoint. See PRD §7.1.
  Future<List<String>?> fetchLlmModels({required String endpoint, String? apiKey}) async {
    return _llm.fetchModels(endpoint: endpoint, apiKey: apiKey);
  }

  // ── Risk ────────────────────────────────────────────────────────────────────
  void setDailyLossCap(double cap) => emit(state.copyWith(dailyLossCapUsd: cap));

  // ── Theme ───────────────────────────────────────────────────────────────────
  void toggleTheme() => emit(state.copyWith(themeBrightness: state.themeBrightness == 'dark' ? 'light' : 'dark'));

  @override
  AppState? fromJson(Map<String, dynamic> json) => AppState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(AppState state) => state.toJson();

  @override
  Future<void> close() {
    _statusSub?.cancel();
    _oppSub?.cancel();
    _dailySummaryTimer?.cancel();
    _scanner.dispose();
    _priceFeedService.dispose();
    _llm.dispose();
    return super.close();
  }
}