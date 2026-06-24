import 'dart:convert';
import 'package:dio/dio.dart';
import '../domain/llm_config.dart';
import '../domain/llm_result.dart';
import '../domain/opportunity.dart';
import '../domain/strategy.dart';
import '../domain/trade.dart';
import 'secure_key_store.dart';
import 'llm_prompts.dart';
import 'trade_history_summarizer.dart';

/// Client for the OpenAI-compatible LLM API. Handles chat completions for
/// analysis, decisions, debriefs, and daily summaries. See PRD §7.
///
/// The user's API key is read from [SecureKeyStore] per-request and never
/// persisted in app state. If the key is missing or the endpoint is
/// unreachable, all calls return null and the app falls back to the
/// scanner-generated analysis.
class LlmService {
  LlmService({required this.keyStore});

  final SecureKeyStore keyStore;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 10),
  ));

  bool _disposed = false;

  /// The user's trade history, injected into the system prompt so the LLM
  /// learns from past outcomes (in-context fine-tuning, PRD §12 v2.5).
  List<TradeRecord> _tradeHistory = const [];
  set tradeHistory(List<TradeRecord> value) => _tradeHistory = value;

  /// The enhanced system prompt with trade history summary injected.
  String get _systemPrompt =>
      TradeHistorySummarizer.buildEnhancedSystemPrompt(LlmPrompts.systemPrompt, _tradeHistory);

  /// Whether the LLM is configured (endpoint set + key present).
  Future<bool> isConfigured() async {
    final key = await keyStore.readApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Generic chat completion call. Returns the assistant message content, or
  /// null on any failure.
  Future<String?> _chat({
    required LlmConfig config,
    required String userPrompt,
    required double temperature,
    required int maxTokens,
  }) async {
    if (_disposed) return null;
    final apiKey = await keyStore.readApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final endpoint = config.endpoint.endsWith('/')
          ? '${config.endpoint}chat/completions'
          : '${config.endpoint}/chat/completions';

      final response = await _dio.post<dynamic>(
        endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode({
          'model': config.model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode != 200) return null;
      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;
      final message = (choices[0] as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
      return message?['content'] as String?;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Generates an opportunity analysis. Returns null if unconfigured/failed.
  Future<LlmAnalysis?> analyzeOpportunity({
    required LlmConfig config,
    required Opportunity opportunity,
    required Strategy strategy,
    required String customInstructions,
  }) async {
    final prompt = LlmPrompts.opportunityAnalysis(
      opportunity: opportunity,
      strategy: strategy,
      customInstructions: customInstructions,
    );
    final content = await _chat(
      config: config,
      userPrompt: prompt,
      temperature: config.analysisTemperature,
      maxTokens: config.analysisMaxTokens,
    );
    if (content == null) return null;
    return _parseAnalysis(content);
  }

  /// Generates an autonomous execution decision.
  Future<LlmDecision?> executionDecision({
    required LlmConfig config,
    required Opportunity opportunity,
    required LlmAnalysis analysis,
    required Strategy strategy,
    required double portfolioExposure,
    required int openPositions,
    required double dailyPnl,
  }) async {
    final prompt = LlmPrompts.executionDecision(
      opportunity: opportunity,
      analysis: analysis,
      strategy: strategy,
      portfolioExposure: portfolioExposure,
      openPositions: openPositions,
      dailyPnl: dailyPnl,
    );
    final content = await _chat(
      config: config,
      userPrompt: prompt,
      temperature: config.decisionTemperature,
      maxTokens: config.decisionMaxTokens,
    );
    if (content == null) return null;
    return _parseDecision(content);
  }

  /// Generates a post-trade debrief (plain text).
  Future<String?> postTradeDebrief({
    required LlmConfig config,
    required TradeRecord trade,
  }) async {
    final prompt = LlmPrompts.postTradeDebrief(trade);
    return _chat(
      config: config,
      userPrompt: prompt,
      temperature: config.analysisTemperature,
      maxTokens: 256,
    );
  }

  /// Generates a daily summary.
  Future<LlmDailySummary?> dailySummary({
    required LlmConfig config,
    required List<TradeRecord> trades,
    required double totalPnl,
  }) async {
    final prompt = LlmPrompts.dailySummary(trades, totalPnl);
    final content = await _chat(
      config: config,
      userPrompt: prompt,
      temperature: config.analysisTemperature,
      maxTokens: config.analysisMaxTokens,
    );
    if (content == null) return null;
    return _parseDailySummary(content);
  }

  // ── JSON parsing helpers ────────────────────────────────────────────────────
  /// Extracts the first JSON object from a possibly markdown-wrapped string.
  Map<String, dynamic>? _extractJson(String content) {
    try {
      // Strip markdown code fences if present.
      var cleaned = content.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```(?:json)?\s*'), '').replaceAll(RegExp(r'\s*```$'), '').trim();
      }
      // Find the first { ... } block.
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) return null;
      final jsonStr = cleaned.substring(start, end + 1);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  LlmAnalysis? _parseAnalysis(String content) {
    final json = _extractJson(content);
    if (json == null) return null;
    final explanation = json['explanation'] as String? ?? content;
    final score = (json['score'] as num?)?.toInt() ?? 50;
    final profitable = json['profitable'] as bool? ?? score >= 60;
    return LlmAnalysis(explanation: explanation, score: score.clamp(0, 100), profitable: profitable);
  }

  LlmDecision? _parseDecision(String content) {
    final json = _extractJson(content);
    if (json == null) return null;
    return LlmDecision(
      execute: json['execute'] as bool? ?? false,
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0).clamp(0, 1),
      reasoning: json['reasoning'] as String? ?? '',
      suggestedSizeUsd: (json['suggested_size_usd'] as num?)?.toDouble() ?? 0,
    );
  }

  LlmDailySummary? _parseDailySummary(String content) {
    final json = _extractJson(content);
    if (json == null) return null;
    return LlmDailySummary(
      narrative: json['narrative'] as String? ?? content,
      pnlSummary: (json['pnl_summary'] as num?)?.toDouble() ?? 0,
      bestOpportunity: json['best_opportunity'] as String? ?? '',
      worstOpportunity: json['worst_opportunity'] as String? ?? '',
      recommendation: json['recommendation'] as String? ?? '',
    );
  }

  void dispose() {
    _disposed = true;
    _dio.close();
  }
}