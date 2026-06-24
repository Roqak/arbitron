import '../domain/trade.dart';
import '../domain/enums.dart';

/// Summarizes a user's trade history so the LLM can learn from past outcomes.
/// This is the "fine-tuning on user's own trade history" feature from PRD §12
/// (v2.5). Rather than actual model fine-tuning (which requires server-side
/// training), we inject a compressed summary of the user's past trades into
/// the LLM system prompt — a context-window-efficient form of in-context
/// learning that adapts the AI's analysis to the user's actual results.
class TradeHistorySummarizer {
  TradeHistorySummarizer._();

  /// Builds a concise summary of the user's trade history for LLM context.
  /// Returns null if there's insufficient history (< 5 trades).
  static String? summarize(List<TradeRecord> trades) {
    if (trades.length < 5) return null;

    final total = trades.length;
    final wins = trades.where((t) => t.profit).length;
    final losses = total - wins;
    final winRate = (wins / total * 100).toStringAsFixed(0);
    final totalPnl = trades.fold(0.0, (s, t) => s + t.netPnl);
    final avgWin = wins > 0
        ? trades.where((t) => t.profit).fold(0.0, (s, t) => s + t.netPnl) / wins
        : 0.0;
    final avgLoss = losses > 0
        ? trades.where((t) => !t.profit).fold(0.0, (s, t) => s + t.netPnl) / losses
        : 0.0;

    // Best/worst pairs.
    final pairPnl = <String, double>{};
    final pairCount = <String, int>{};
    for (final t in trades) {
      pairPnl[t.pair] = (pairPnl[t.pair] ?? 0) + t.netPnl;
      pairCount[t.pair] = (pairCount[t.pair] ?? 0) + 1;
    }
    final sortedPairs = pairPnl.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final bestPair = sortedPairs.first;
    final worstPair = sortedPairs.last;

    // Strategy performance.
    final stratPnl = <String, double>{};
    for (final t in trades) {
      stratPnl[t.strategyName] = (stratPnl[t.strategyName] ?? 0) + t.netPnl;
    }
    final stratSummary = stratPnl.entries
        .map((e) => '${e.key}: \$${e.value.toStringAsFixed(2)}')
        .join('; ');

    // Mode performance.
    final modeStats = <ExecutionMode, ({int count, double pnl})>{};
    for (final t in trades) {
      final existing = modeStats[t.mode];
      modeStats[t.mode] = (count: (existing?.count ?? 0) + 1, pnl: (existing?.pnl ?? 0) + t.netPnl);
    }
    final modeSummary = modeStats.entries
        .map((e) => '${e.key.label}: ${e.value.count} trades, \$${e.value.pnl.toStringAsFixed(2)}')
        .join('; ');

    return '''USER TRADE HISTORY SUMMARY (learn from these outcomes):
- Total trades: $total | Win rate: $winRate% | Net P&L: \$${totalPnl.toStringAsFixed(2)}
- Avg win: \$${avgWin.toStringAsFixed(2)} | Avg loss: \$${avgLoss.toStringAsFixed(2)}
- Best pair: ${bestPair.key} (\$${bestPair.value.toStringAsFixed(2)} over ${pairCount[bestPair.key]} trades)
- Worst pair: ${worstPair.key} (\$${worstPair.value.toStringAsFixed(2)} over ${pairCount[worstPair.key]} trades)
- Strategy performance: $stratSummary
- By execution mode: $modeSummary
Use these historical outcomes to calibrate your analysis. Prefer pairs and modes where the user has historically performed well. Flag pairs with consistent losses more cautiously.''';
  }

  /// Builds the enhanced system prompt with trade history injected.
  static String buildEnhancedSystemPrompt(String basePrompt, List<TradeRecord> trades) {
    final summary = summarize(trades);
    if (summary == null) return basePrompt;
    return '$basePrompt\n\n$summary';
  }
}