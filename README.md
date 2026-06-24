# Arbitron

**AI-Powered Crypto Arbitrage Platform** — Flutter (Android, iOS)

Arbitron is a Flutter mobile app that aggregates crypto prices across CEXs and
DEXs, detects arbitrage opportunities, and uses an OpenAI-compatible LLM to
analyze, score, and (optionally) execute trades within user-defined risk limits.

> ⚠️ This is the **v1.0 MVP**. It ships with a deterministic demo dataset so the
> full UI is explorable without live exchange credentials or an LLM API key. The
> data layer is isolated and will be wired to real exchange feeds + LLM in v1.5.

## Status

| Area | MVP (v1.0) |
|------|-----------|
| CEX support | Catalog of 10 exchanges, 3 enabled by default |
| DEX support | Catalog of 10 DEXs (config UI only in MVP) |
| Strategies | 3 seeded strategies, full editor, 5 strategy types |
| Execution modes | Manual, Semi-Auto, Autonomous (with Kill Switch) |
| LLM integration | Config screen (OpenAI-compatible), analysis rendering |
| Persistence | HydratedBloc (strategies, trades, LLM config, theme) |
| Live feeds | ⏳ v1.5 (currently demo data) |

## Project structure

Feature-first Clean Architecture:

```
lib/
  core/
    data/         demo data service (replaced by live feeds in v1.5)
    domain/       enums, exchange catalog, strategy, opportunity, trade, llm_config
    theme/        design tokens: colors, spacing, typography, theme
    widgets/      shared components (ArbitronCard, OpportunityCard, AiAnalysisBlock…)
    utils/        formatters, RNG
    app_cubit.dart    global HydratedBloc state
    app_state.dart
  features/
    dashboard/        live overview, ticker strip, portfolio, AI feed
    opportunities/    list + filters + detail sheet + execute
    strategies/       list + editor (mode, risk, LLM instructions)
    history/          audit log + trade detail + AI debrief
    settings/         LLM config, exchanges, risk cap, theme, notifications
  main.dart
  app_shell.dart      bottom nav + Kill Switch FAB
```

## Design

The full design system is documented in [DESIGN.md](./DESIGN.md) — colors,
typography, spacing, components, motion, and accessibility. All UI code
consumes semantic tokens from `core/theme/`; no raw hex values in features.

## Getting started

```bash
flutter pub get
flutter run           # debug
flutter build apk --release
```

Requires Flutter 3.19+ / Dart 3.3+ and Android SDK 35.

## Testing

```bash
flutter test
flutter analyze
```

## Roadmap

See `PRD.md §12` for the full phased roadmap. v1.5 adds live DEX support,
Autonomous mode + Kill Switch wiring, and real LLM analysis.

---

*Cryptocurrency trading involves significant risk of loss. AI analysis is not
financial advice. Past performance does not predict future results.*