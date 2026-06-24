import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'domain/enums.dart';
import 'domain/exchange.dart';
import 'domain/llm_config.dart';
import 'domain/opportunity.dart';
import 'domain/strategy.dart';
import 'domain/trade.dart';
import 'data/demo_data_service.dart';

part 'app_state.dart';

class AppCubit extends HydratedCubit<AppState> {
  AppCubit() : super(AppState.initial());

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
  }

  // ── Kill switch ─────────────────────────────────────────────────────────────
  void pauseAllAutonomous() => emit(state.copyWith(autonomousPaused: true));
  void resumeAutonomous() => emit(state.copyWith(autonomousPaused: false));

  bool get anyAutonomousActive =>
      !state.autonomousPaused &&
      state.strategies.any((s) => s.enabled && s.mode == ExecutionMode.autonomous);

  // ── Opportunities ──────────────────────────────────────────────────────────
  void refreshOpportunities() {
    final opps = DemoDataService.opportunities(count: 14);
    emit(state.copyWith(
      opportunities: opps,
      lastUpdated: DateTime.now(),
    ));
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
}