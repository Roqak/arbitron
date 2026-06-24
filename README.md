# Arbitron

**AI-Powered Crypto Arbitrage Platform** — Flutter (Android, iOS)

Arbitron is a Flutter mobile app that aggregates crypto prices across CEXs and
DEXs, detects arbitrage opportunities, and uses an OpenAI-compatible LLM to
analyze, score, and (optionally) execute trades within user-defined risk limits.

> ⚠️ This is the **v1.0 MVP**. It ships with a deterministic demo dataset so the
> full UI is explorable without live exchange credentials or an LLM API key. The
> data layer is isolated and will be wired to real exchange feeds + LLM in v1.5.

## Status

| Area | v2.0.0 |
|------|--------|
| CEX support | **Live WebSocket feeds**: Binance, Coinbase, Kraken, OKX, Bybit |
| DEX support | Catalog of 10 DEXs (config UI only; live feeds in v2.5) |
| Strategies | 3 seeded strategies, full editor, 5 strategy types |
| Execution modes | Manual, Semi-Auto, **Autonomous with live LLM execution decisions** |
| Opportunity scanner | **Live cross-exchange spread detection** net of fees + slippage |
| LLM integration | **Live OpenAI-compatible API**: analysis, execution decisions, debriefs, daily summary |
| Trade export | CSV / JSON export of full audit log |
| Persistence | HydratedBloc (strategies, trades, LLM config, theme) |

## Project structure

Feature-first Clean Architecture:

```
lib/
  core/
    data/         live price feeds (WebSocket), opportunity scanner, demo fallback
    domain/       ticker, exchange catalog, strategy, opportunity, trade, llm_config
    theme/        design tokens: colors, spacing, typography, theme
    widgets/      shared components (ArbitronCard, OpportunityCard, AiAnalysisBlock…)
    utils/        formatters, RNG
    app_cubit.dart    global HydratedBloc state + live feed lifecycle
    app_state.dart
  features/
    dashboard/        live overview, ticker strip, portfolio, AI feed, market health
    opportunities/    live opportunity list + filters + detail sheet + execute
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

See `PRD.md §12` for the full phased roadmap. v2.5 adds strategy backtesting,
LLM fine-tuning on user trade history, and cross-chain bridge integrations.

---

*Cryptocurrency trading involves significant risk of loss. AI analysis is not
financial advice. Past performance does not predict future results.*