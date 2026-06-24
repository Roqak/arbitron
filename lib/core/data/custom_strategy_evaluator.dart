import '../domain/custom_strategy.dart';
import '../domain/opportunity.dart';

/// Evaluates a [CustomStrategy]'s rules against a live [Opportunity].
/// Used by the opportunity scanner to filter/customize which opportunities
/// match a user-built strategy. See PRD §12 (v2.5 — Custom strategy builder).
class CustomStrategyEvaluator {
  CustomStrategyEvaluator._();

  /// Returns true if [opportunity] satisfies [strategy]'s rules.
  static bool matches(CustomStrategy strategy, Opportunity o) {
    if (strategy.rules.isEmpty) return true;
    final results = strategy.rules.map((r) => _evalRule(r, o));
    return strategy.composition == RuleComposition.and
        ? results.every((v) => v)
        : results.any((v) => v);
  }

  static bool _evalRule(StrategyRule rule, Opportunity o) {
    final fieldValue = _getFieldValue(rule.field, o);
    if (rule.field.isText) {
      final strVal = fieldValue as String? ?? '';
      final target = rule.textValue ?? '';
      return switch (rule.op) {
        RuleOperator.eq => strVal == target,
        RuleOperator.neq => strVal != target,
        RuleOperator.contains => strVal.contains(target),
        _ => false,
      };
    }
    final numVal = (fieldValue as num?)?.toDouble() ?? 0;
    return switch (rule.op) {
      RuleOperator.gt => numVal > rule.value,
      RuleOperator.gte => numVal >= rule.value,
      RuleOperator.lt => numVal < rule.value,
      RuleOperator.lte => numVal <= rule.value,
      RuleOperator.eq => numVal == rule.value,
      RuleOperator.neq => numVal != rule.value,
      RuleOperator.contains => false,
    };
  }

  static dynamic _getFieldValue(RuleField field, Opportunity o) {
    return switch (field) {
      RuleField.netProfitUsd => o.netProfitUsd,
      RuleField.netProfitPct => o.netProfitPct,
      RuleField.grossSpreadPct => o.grossSpreadPct,
      RuleField.confidenceScore => o.confidenceScore.toDouble(),
      RuleField.pair => o.pair,
      RuleField.buyExchange => o.buyExchangeId,
      RuleField.sellExchange => o.sellExchangeId,
      RuleField.estFeesUsd => o.estFeesUsd,
      RuleField.estSlippageUsd => o.estSlippageUsd,
    };
  }
}