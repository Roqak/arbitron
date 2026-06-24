import 'package:equatable/equatable.dart';

/// LLM (OpenAI-compatible) configuration. The API key is stored separately in
/// secure storage; this holds only non-secret config. See PRD §7.1.
class LlmConfig extends Equatable {
  final String endpoint;
  final String model;
  final bool configured;
  final double analysisTemperature;
  final double decisionTemperature;
  final int analysisMaxTokens;
  final int decisionMaxTokens;

  const LlmConfig({
    this.endpoint = 'https://api.openai.com/v1',
    this.model = 'gpt-4o',
    this.configured = false,
    this.analysisTemperature = 0.7,
    this.decisionTemperature = 0.2,
    this.analysisMaxTokens = 2048,
    this.decisionMaxTokens = 512,
  });

  LlmConfig copyWith({
    String? endpoint,
    String? model,
    bool? configured,
    double? analysisTemperature,
    double? decisionTemperature,
    int? analysisMaxTokens,
    int? decisionMaxTokens,
  }) {
    return LlmConfig(
      endpoint: endpoint ?? this.endpoint,
      model: model ?? this.model,
      configured: configured ?? this.configured,
      analysisTemperature: analysisTemperature ?? this.analysisTemperature,
      decisionTemperature: decisionTemperature ?? this.decisionTemperature,
      analysisMaxTokens: analysisMaxTokens ?? this.analysisMaxTokens,
      decisionMaxTokens: decisionMaxTokens ?? this.decisionMaxTokens,
    );
  }

  @override
  List<Object?> get props => [endpoint, model, configured, analysisTemperature, decisionTemperature, analysisMaxTokens, decisionMaxTokens];

  factory LlmConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LlmConfig();
    return LlmConfig(
      endpoint: json['endpoint'] as String? ?? 'https://api.openai.com/v1',
      model: json['model'] as String? ?? 'gpt-4o',
      configured: json['configured'] as bool? ?? false,
      analysisTemperature: (json['analysisTemperature'] as num?)?.toDouble() ?? 0.7,
      decisionTemperature: (json['decisionTemperature'] as num?)?.toDouble() ?? 0.2,
      analysisMaxTokens: json['analysisMaxTokens'] as int? ?? 2048,
      decisionMaxTokens: json['decisionMaxTokens'] as int? ?? 512,
    );
  }

  Map<String, dynamic> toJson() => {
        'endpoint': endpoint, 'model': model, 'configured': configured,
        'analysisTemperature': analysisTemperature, 'decisionTemperature': decisionTemperature,
        'analysisMaxTokens': analysisMaxTokens, 'decisionMaxTokens': decisionMaxTokens,
      };
}