import 'package:equatable/equatable.dart';

/// Result of an LLM opportunity analysis. See PRD §7.2 (Opportunity Analysis).
class LlmAnalysis extends Equatable {
  final String explanation; // 3-5 sentence plain-language analysis
  final int score; // 0..100
  final bool profitable;

  const LlmAnalysis({
    required this.explanation,
    required this.score,
    required this.profitable,
  });

  @override
  List<Object?> get props => [explanation, score, profitable];
}

/// Structured LLM execution decision for Autonomous mode. See PRD §7.2.
class LlmDecision extends Equatable {
  final bool execute;
  final double confidence; // 0..1
  final String reasoning;
  final double suggestedSizeUsd;

  const LlmDecision({
    required this.execute,
    required this.confidence,
    required this.reasoning,
    required this.suggestedSizeUsd,
  });

  @override
  List<Object?> get props => [execute, confidence, reasoning, suggestedSizeUsd];
}

/// Daily LLM summary. See PRD §7.2 (Daily Summary).
class LlmDailySummary extends Equatable {
  final String narrative;
  final double pnlSummary;
  final String bestOpportunity;
  final String worstOpportunity;
  final String recommendation;

  const LlmDailySummary({
    required this.narrative,
    required this.pnlSummary,
    required this.bestOpportunity,
    required this.worstOpportunity,
    required this.recommendation,
  });

  @override
  List<Object?> get props => [narrative, pnlSummary, bestOpportunity, worstOpportunity, recommendation];
}