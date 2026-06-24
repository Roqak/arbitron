# Arbitron v2.5.2 — No-Code Custom Strategy Builder

A visual rule composer for building custom arbitrage strategies without
editing config fields. Compose rules, pick match logic, and save.

## Install
Download `arbitron-v2.5.2.apk` — Android 10+, ~56 MB.
- **Version:** 2.5.2 (versionCode 5) · `com.arbitron.arbitron`

## What's new

### No-code custom strategy builder (PRD §12 v2.5)
A "Builder" button on the Strategies screen opens a visual rule composer:

- **Rule fields:** net profit (USD/%), gross spread, confidence score, asset
  pair, buy/sell exchange, est. fees, est. slippage
- **Operators:** >, ≥, <, ≤, =, ≠, contains (text fields)
- **Match logic:** ALL rules (AND) or ANY rule (OR)
- **Rule cards:** each rule is a numbered card with field/operator/value
  dropdowns and a remove button
- **Execution mode + risk caps:** manual/semi/auto, max trade size, stop-loss
- **Persistence:** custom strategies are saved via HydratedBloc

### Files added
- `core/domain/custom_strategy.dart` — `StrategyRule`, `RuleField`,
  `RuleOperator`, `CustomStrategy`, `RuleComposition` (with JSON persistence)
- `core/data/custom_strategy_evaluator.dart` — evaluates a custom strategy's
  rules against a live `Opportunity`
- `features/strategies/custom_strategy_builder_sheet.dart` — visual builder UI

## Verification
- `flutter analyze` → 0 errors, 0 warnings
- `flutter test` → all tests pass
- `flutter build apk --release` → 55.6 MB APK

---

*Cryptocurrency trading involves significant risk of loss. Custom strategies do not guarantee profitable outcomes.*