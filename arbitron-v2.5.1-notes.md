# Arbitron v2.5.1 — Strategy Backtesting

First release of the v2.5 Intelligence+ phase: **strategy backtesting** with
simulated historical performance, equity curves, and risk metrics.

## Install
Download `arbitron-v2.5.1.apk` — Android 10+, ~55 MB.
- **Version:** 2.5.1 (versionCode 4) · `com.arbitron.arbitron`

## What's new

### Strategy backtesting (PRD §8.3, §12 v2.5)
Each strategy card now has a **Backtest** button that opens a results sheet:
- Configurable period (7d / 30d / 90d) and starting capital
- **Equity curve** rendered with fl_chart (green for profit, red for loss)
- Headline metrics: net P&L, total trades, win rate, max drawdown, Sharpe ratio
- Detailed stats: best/worst trade, avg profit per trade, winning trade count

The `BacktestEngine` generates a deterministic synthetic price walk seeded by
the strategy's parameters (aggressiveness, max trade size, min profit
threshold, allowed exchanges/pairs). Conservative strategies produce fewer
trades with higher win rates; aggressive strategies produce more trades with
lower win rates but higher per-trade profit potential. Results are
reproducible across runs.

### Files added
- `core/domain/backtest.dart` — `BacktestResult`, `BacktestEquityPoint`
- `core/data/backtest_engine.dart` — simulation engine with Sharpe ratio
- `features/strategies/backtest_sheet.dart` — results UI with equity curve chart

## Verification
- `flutter analyze` → 0 errors, 0 warnings
- `flutter test` → all tests pass
- `flutter build apk --release` → 55.4 MB APK

---

*Cryptocurrency trading involves significant risk of loss. Backtest results are simulated and do not predict future performance.*