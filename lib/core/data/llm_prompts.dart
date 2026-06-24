import '../domain/enums.dart';
import '../domain/llm_result.dart';
import '../domain/opportunity.dart';
import '../domain/strategy.dart';
import '../domain/trade.dart';

/// Builds the prompts sent to the LLM for each task type. See PRD §7.2.
/// The base system prompt is injected by the app; the user can append custom
/// instructions per strategy (PRD §5.2).
class LlmPrompts {
  LlmPrompts._();

  /// Base system prompt — defines the AI's role and constraints.
  static const String systemPrompt = '''You are Arbitron's AI co-pilot, an arbitrage analysis assistant. You evaluate crypto arbitrage opportunities by analyzing spreads, fees, slippage, liquidity, and market conditions. You are calm, precise, and transparent about risk. You never guarantee profit. All your output must be clearly understood as analysis, not financial advice.''';

  /// Opportunity Analysis prompt. Returns a JSON object with explanation + score.
  static String opportunityAnalysis({
    required Opportunity opportunity,
    required Strategy strategy,
    required String customInstructions,
  }) {
    final o = opportunity;
    return '''Analyze this arbitrage opportunity and respond as JSON.

Opportunity:
- Pair: ${o.pair}
- Buy on: ${o.buyExchangeId} at \$${o.buyPrice}
- Sell on: ${o.sellExchangeId} at \$${o.sellPrice}
- Gross spread: ${o.grossSpreadPct.toStringAsFixed(2)}%
- Estimated fees: \$${o.estFeesUsd.toStringAsFixed(2)}
- Estimated slippage: \$${o.estSlippageUsd.toStringAsFixed(2)}
- Net profit: \$${o.netProfitUsd.toStringAsFixed(2)} (${o.netProfitPct.toStringAsFixed(2)}%)

Strategy context:
- Strategy: ${strategy.name} (${strategy.type.label})
- Mode: ${strategy.mode.label}
- Min profit threshold: \$${strategy.minProfitUsd}
- Max trade size: \$${strategy.maxTradeUsd}
- AI aggressiveness: ${strategy.aggressiveness.label}

${customInstructions.isNotEmpty ? 'Additional user instructions: $customInstructions' : ''}

Respond with JSON in this exact format:
{"explanation": "3-5 sentence analysis of the opportunity", "score": <integer 0-100>, "profitable": <true|false>}''';
  }

  /// Execution Decision prompt (Autonomous mode). Returns structured JSON.
  static String executionDecision({
    required Opportunity opportunity,
    required LlmAnalysis analysis,
    required Strategy strategy,
    required double portfolioExposure,
    required int openPositions,
    required double dailyPnl,
  }) {
    final o = opportunity;
    return '''You are operating in AUTONOMOUS mode. Decide whether to execute this trade.

Opportunity:
- Pair: ${o.pair}, Buy: ${o.buyExchangeId} @ \$${o.buyPrice}, Sell: ${o.sellExchangeId} @ \$${o.sellPrice}
- Net profit estimate: \$${o.netProfitUsd.toStringAsFixed(2)}

Analysis: ${analysis.explanation} (score ${analysis.score})

Portfolio state:
- Current exposure: \$${portfolioExposure.toStringAsFixed(2)}
- Open positions: $openPositions (max: ${strategy.maxConcurrentPositions})
- Today's P&L: \$${dailyPnl.toStringAsFixed(2)}
- Daily loss cap: \$${strategy.stopLossDailyUsd}
- Max trade size: \$${strategy.maxTradeUsd}

Respond with JSON:
{"execute": <true|false>, "confidence": <0-1>, "reasoning": "one sentence", "suggested_size_usd": <number>}''';
  }

  /// Post-trade debrief prompt.
  static String postTradeDebrief(TradeRecord trade) {
    final t = trade;
    return '''Provide a brief debrief on this completed trade.

Trade:
- Pair: ${t.pair}, Strategy: ${t.strategyName}
- Entry: \$${t.entryPrice}, Exit: \$${t.exitPrice}
- Gross P&L: \$${t.grossPnl.toStringAsFixed(2)}, Net P&L: \$${t.netPnl.toStringAsFixed(2)}
- Fees: \$${t.feesUsd.toStringAsFixed(2)}, Slippage: \$${t.slippageUsd.toStringAsFixed(2)}
- Outcome: ${t.profit ? 'profit' : 'loss'}

Respond with 2-3 sentences explaining what happened and any lessons.''';
  }

  /// Daily summary prompt.
  static String dailySummary(List<TradeRecord> trades, double totalPnl) {
    final tradeLines = trades.map((t) => '- ${t.pair}: net \$${t.netPnl.toStringAsFixed(2)} (${t.profit ? 'win' : 'loss'})').join('\\n');
    return '''Generate a daily performance summary.

Today's trades ($trades count):
$tradeLines

Total net P&L: \$${totalPnl.toStringAsFixed(2)}

Respond with JSON:
{"narrative": "performance narrative", "pnl_summary": <number>, "best_opportunity": "description", "worst_opportunity": "description", "recommendation": "parameter adjustment suggestion"}''';
  }
}