import 'package:equatable/equatable.dart';
import 'enums.dart';

/// A single rule in a no-code custom strategy. See PRD §12 (v2.5 — Custom
/// strategy builder). Rules compose into a [CustomStrategy] that the engine
/// evaluates against live opportunities.
class StrategyRule extends Equatable {
  final RuleField field;
  final RuleOperator op;
  final double value;
  final String? textValue;

  const StrategyRule({
    required this.field,
    required this.op,
    this.value = 0,
    this.textValue,
  });

  String get displayValue => textValue ?? value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);

  String describe() {
    return '${field.label} ${op.label} ${field.isText ? (textValue ?? '') : displayValue}';
  }

  factory StrategyRule.fromJson(Map<String, dynamic> json) {
    return StrategyRule(
      field: RuleField.values.byName(json['field'] as String? ?? 'netProfitUsd'),
      op: RuleOperator.values.byName(json['op'] as String? ?? 'gte'),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      textValue: json['textValue'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field.name, 'op': op.name, 'value': value, 'textValue': textValue,
      };

  @override
  List<Object?> get props => [field, op, value, textValue];
}

/// The fields a rule can test.
enum RuleField {
  netProfitUsd('Net profit (USD)', false),
  netProfitPct('Net profit (%)', false),
  grossSpreadPct('Gross spread (%)', false),
  confidenceScore('Confidence score', false),
  pair('Asset pair', true),
  buyExchange('Buy exchange', true),
  sellExchange('Sell exchange', true),
  estFeesUsd('Est. fees (USD)', false),
  estSlippageUsd('Est. slippage (USD)', false);

  final String label;
  final bool isText;
  const RuleField(this.label, this.isText);
}

enum RuleOperator {
  gt('>', false),
  gte('\u2265', false),
  lt('<', false),
  lte('\u2264', false),
  eq('=', true),
  neq('\u2260', true),
  contains('contains', true);

  final String label;
  final bool forText;
  const RuleOperator(this.label, this.forText);
}

/// A composable custom strategy built from rules. See PRD §12 (v2.5).
class CustomStrategy extends Equatable {
  final String id;
  final String name;
  final RuleComposition composition; // AND / OR
  final List<StrategyRule> rules;
  final ExecutionMode mode;
  final double maxTradeUsd;
  final double stopLossDailyUsd;

  const CustomStrategy({
    required this.id,
    required this.name,
    this.composition = RuleComposition.and,
    this.rules = const [],
    this.mode = ExecutionMode.manual,
    this.maxTradeUsd = 1000,
    this.stopLossDailyUsd = 100,
  });

  CustomStrategy copyWith({
    String? id,
    String? name,
    RuleComposition? composition,
    List<StrategyRule>? rules,
    ExecutionMode? mode,
    double? maxTradeUsd,
    double? stopLossDailyUsd,
  }) {
    return CustomStrategy(
      id: id ?? this.id,
      name: name ?? this.name,
      composition: composition ?? this.composition,
      rules: rules ?? this.rules,
      mode: mode ?? this.mode,
      maxTradeUsd: maxTradeUsd ?? this.maxTradeUsd,
      stopLossDailyUsd: stopLossDailyUsd ?? this.stopLossDailyUsd,
    );
  }

  @override
  List<Object?> get props => [id, name, composition, rules, mode, maxTradeUsd, stopLossDailyUsd];

  factory CustomStrategy.fromJson(Map<String, dynamic> json) {
    return CustomStrategy(
      id: json['id'] as String,
      name: json['name'] as String,
      composition: RuleComposition.values.byName(json['composition'] as String? ?? 'and'),
      rules: (json['rules'] as List? ?? []).map((e) => StrategyRule.fromJson(e as Map<String, dynamic>)).toList(),
      mode: ExecutionMode.values.byName(json['mode'] as String? ?? 'manual'),
      maxTradeUsd: (json['maxTradeUsd'] as num?)?.toDouble() ?? 1000,
      stopLossDailyUsd: (json['stopLossDailyUsd'] as num?)?.toDouble() ?? 100,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'composition': composition.name,
        'rules': rules.map((e) => e.toJson()).toList(),
        'mode': mode.name, 'maxTradeUsd': maxTradeUsd, 'stopLossDailyUsd': stopLossDailyUsd,
      };
}

enum RuleComposition { and, or }

extension RuleCompositionX on RuleComposition {
  String get label => this == RuleComposition.and ? 'ALL (AND)' : 'ANY (OR)';
}