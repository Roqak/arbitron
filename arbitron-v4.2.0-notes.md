# Arbitron v4.2.0 — All Mock Data Removed

Every trace of placeholder, demo, and synthetic data has been eliminated.
The app now operates entirely on real data: live exchange prices, real order
execution, real portfolio balances, and real trade history.

## Install
Download `arbitron-v4.2.0.apk` — Android 10+, ~57 MB.
- **Version:** 4.2.0 (versionCode 15) · `com.arbitron.arbitron`

## What changed

### Deleted: DemoDataService + Rng utility
- `lib/core/data/demo_data_service.dart` — deleted entirely
- `lib/core/utils/rng.dart` — deleted entirely
- All references to `DemoDataService.opportunities()`, `DemoDataService.tradeHistory()`,
  and `DemoDataService.defaultStrategies()` removed

### Fixed: Opportunities start empty
- AppState initializes with `opportunities: const []` — the live scanner
  populates them from real WebSocket feeds
- `refreshOpportunities()` clears the list; the scanner repopulates from live
  data. No fake opportunities are ever generated.

### Fixed: Strategy stats are zero, not fake
- Default strategies ship with `totalTrades: 0`, `winRate: 0`, `totalPnl: 0`
- Stats are computed from real trades only

### Fixed: Leaderboard has no fake peers
- `LeaderboardService._generatePeers()` removed (12 fake entries gone)
- Leaderboard shows only the user's entry when opted in
- Empty state shown when not opted in (no podium, no fake rankings)

### Fixed: Marketplace is empty (no backend)
- `MarketplaceCatalog.all` is now an empty list
- Marketplace sheet shows "Marketplace coming soon" empty state
- No fake community strategies

### Fixed: Backtest uses real current prices
- `BacktestEngine` now takes a `PriceFeedService` and uses real live mid
  prices from the current snapshot as the starting point
- If no live price data is available, returns an empty result (0 trades)
- The random walk simulates price movement around real current prices

### Fixed: Portfolio value converts all assets using live prices
- `TradingService.fetchPortfolioValueUsd()` now uses the price feed service
  to convert non-stablecoin balances (BTC, ETH, SOL, etc.) to USD using live
  mid prices
- Non-stablecoin assets with no available price contribute 0 (can't value
  without a live price)

### What's real now
| Data source | Before | After |
|-------------|--------|-------|
| Prices | Live WebSocket ✓ | Live WebSocket ✓ |
| Opportunities | Live scanner ✓ | Live scanner ✓ (was seeded with fake on init) |
| Trades | Real execution ✓ | Real execution ✓ |
| Portfolio | Real balances + live price conversion ✓ | Same ✓ (was `0.0` for non-stablecoins) |
| Strategy stats | Fake numbers | Zero, computed from real trades |
| Backtest | Synthetic random | Uses real current prices as starting point |
| Leaderboard | 12 fake peers | User only |
| Marketplace | 6 fake strategies | Empty |

## Verification
- `flutter analyze` → 0 errors, 0 warnings
- `flutter test` → all tests pass
- `flutter build apk --release` → 56.7 MB APK

---

*Cryptocurrency trading involves significant risk of loss. Real order execution can result in actual financial loss.*