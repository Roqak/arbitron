# Arbitron v2.5.5 — Full Exchange Coverage (10 CEX + 1 DEX Live)

All 10 CEXs now have live WebSocket feeds, plus the first DEX live feed
(Jupiter Aggregator on Solana). This completes the v2.5 phase.

## Install
Download `arbitron-v2.5.5.apk` — Android 10+, ~56 MB.
- **Version:** 2.5.5 (versionCode 8) · `com.arbitron.arbitron`

## What's new

### Remaining 5 CEX WebSocket feeds
- **KuCoin** — `wss://push.kucoin.com/endpoint` ticker channel
- **Gate.io** — `wss://api.gate.com/ws/v4/` spot.tickers channel
- **Bitfinex** — `wss://api-pub.bitfinex.com/ws/2` ticker channel
- **Huobi / HTX** — `wss://api-aws.huobi.pro/ws` market.detail channel
- **MEXC** — `wss://contract.mexc.com/edge` sub.ticker channel

All 10 CEXs (Binance, Coinbase, Kraken, OKX, Bybit + the 5 new) now feed live
tickers into the PriceFeedService. Enabling any of them in Settings
immediately starts its WebSocket feed.

### First DEX live feed: Jupiter Aggregator (Solana)
DEXs don't offer WebSocket ticker streams, so a new `DexPollFeed` base class
polls public REST price APIs at 2s intervals (per PRD §10.3). The first
implementation is `JupiterFeed` using the Jupiter price API
(`price.jup.ag`). This brings DEX prices into the opportunity scanner for the
first time, enabling real DEX-CEX arbitrage detection with bridge cost
awareness (from v2.5.4).

### Files added
- `core/data/dex_feeds.dart` — `DexPollFeed` (REST polling base) + `JupiterFeed`

### Files changed
- `core/data/exchange_feeds.dart` — added KuCoin, Gate.io, Bitfinex, Huobi, MEXC feeds
- `core/data/price_feed_service.dart` — registers all 10 CEX + 1 DEX feeds
- `core/app_cubit.dart` — supported feed IDs expanded to all 11

## Verification
- `flutter analyze` → 0 errors, 0 warnings
- `flutter test` → all tests pass
- `flutter build apk --release` → 55.9 MB APK

---

*Cryptocurrency trading involves significant risk of loss. Exchange WebSocket and REST APIs may change without notice.*