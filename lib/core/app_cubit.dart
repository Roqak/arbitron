import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'domain/enums.dart';
import 'domain/exchange.dart';
import 'domain/llm_config.dart';
import 'domain/opportunity.dart';
import 'domain/strategy.dart';
import 'domain/trade.dart';
import 'data/demo_data_service.dart';
import 'data/price_feed_service.dart';
import 'data/price_feed.dart';
import 'data/opportunity_scanner.dart';

part 'app_state.dart';

/// The pairs monitored by the live feed. For MVP we watch the top 10 by
/// volume; users will be able to customize this in a later release.
const List<String> _monitoredPairs = [
  'BTC/USDT', 'ETH/USDT', 'SOL/USDT', 'BNB/USDT', 'XRP/USDT',
  'ADA/USDT', 'DOGE/USDT', 'AVAX/USDT', 'LINK/USDT', 'MATIC/USDT',
];

class AppCubit extends HydratedCubit<AppState> {
  AppCubit() : super(AppState.initial()) {
    _initLiveFeeds();
  }

  late final PriceFeedService _priceFeedService = PriceFeedService();
  late final OpportunityScanner _scanner = OpportunityScanner(priceFeedService: _priceFeedService);

  StreamSubscription<Map<String, FeedStatus>>? _statusSub;
  StreamSubscription<List<Opportunity>>? _oppSub;
  bool _feedsStarted = false;

  void _initLiveFeeds() {
    // Seed demo opportunities so the UI has content while feeds connect.
    emit(state.copyWith(
      opportunities: DemoDataService.opportunities(count: 14),
      lastUpdated: DateTime.now(),
    ));

    _statusSub = _priceFeedService.statusChanges.listen(_onFeedStatus);
    _oppSub = _scanner.opportunities.listen(_onOpportunities);
    _scanner.start();
    _restartFeeds();
  }

  void _restartFeeds() {
    // Only start CEX feeds for enabled exchanges that we have implementations for.
    final supported = state.enabledExchangeIds.where((id) {
      final ex = ExchangeCatalog.byId(id);
      return ex.kind == ExchangeKind.cex && _supportedFeedIds.contains(id);
    }).toList();
    if (supported.isEmpty) return;
    _priceFeedService.start(enabledExchangeIds: supported, pairs: _monitoredPairs);
    _feedsStarted = true;
  }

  static const _supportedFeedIds = {'binance', 'coinbase', 'kraken', 'okx', 'bybit'};

  void _onFeedStatus(Map<String, FeedStatus> statuses) {
    // Map FeedStatus -> simple bool: connected if any feed is connected.
    final anyConnected = statuses.values.any((s) => s == FeedStatus.connected);
    emit(state.copyWith(
      feedStatuses: statuses.map((k, v) => MapEntry(k, v.name)),
      feedsConnected: anyConnected,
    ));
  }

  void _onOpportunities(List<Opportunity> opps) {
    // Merge: keep live opportunities, but only emit if we have at least one
    // (avoid wiping the list if a scan produces nothing momentarily).
    if (opps.isEmpty) return;
    emit(state.copyWith(opportunities: opps, lastUpdated: DateTime.now()));
  }

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
    // Restart feeds with the new exchange set.
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
    // Manual refresh: re-seed from demo data (live feed will replace shortly).
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
  }

  // ── LLM config ──────────────────────────────────────────────────────────────
  void updateLlmConfig(LlmConfig c) => emit(state.copyWith(llmConfig: c));

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
    _scanner.dispose();
    _priceFeedService.dispose();
    return super.close();
  }
}