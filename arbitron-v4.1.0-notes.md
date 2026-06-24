# Arbitron v4.1.0 — Real Trade Execution

The app is now functional. Tapping "Execute" places real market orders on
connected exchanges via their REST APIs. Portfolio value is fetched from real
balances. Demo trade history seeding has been removed.

## Install
Download `arbitron-v4.1.0.apk` — Android 10+, ~57 MB.
- **Version:** 4.1.0 (versionCode 14) · `com.arbitron.arbitron`

## What's new

### Real trade execution (the core fix)
`executeOpportunity` now calls the `TradingService` which:
1. Reads stored API credentials for the buy and sell exchanges from secure
   storage
2. Places a **real market BUY** order on the buy exchange via its REST API
3. Places a **real market SELL** order on the sell exchange via its REST API
4. Records the actual fill prices, computes real gross/net P&L
5. Generates an LLM debrief from the actual execution outcome

If credentials are missing, the exchange isn't supported for trading, or
either order fails, a **failed trade** is recorded with the specific reason
("No API credentials for Binance", "Buy leg failed: insufficient balance",
etc.) — the user always knows why execution didn't work.

### Exchange REST API clients
Real trading clients for 5 exchanges with proper HMAC-SHA256 auth signing:

| Exchange | Balance endpoint | Order endpoint | Auth |
|----------|------------------|----------------|------|
| Binance | `/api/v3/account` | `/api/v3/order` | HMAC-SHA256 query signing |
| Kraken | `/0/private/Balance` | `/0/private/AddOrder` | HMAC-SHA512 body signing |
| OKX | `/api/v5/account/balance` | `/api/v5/trade/order` | HMAC-SHA256 + passphrase |
| Bybit | `/v5/account/wallet/balance` | `/v5/order/create` | HMAC-SHA256 payload signing |
| Coinbase | `/api/v3/brokerage/accounts` | `/api/v3/brokerage/orders` | HMAC-SHA256 header signing |

### Per-exchange API credential entry
Each exchange row in Settings now has a key icon that opens a credential entry
sheet (API key, API secret, optional passphrase for OKX). Credentials are
stored in the device keychain via `flutter_secure_storage` — never in app
state, never transmitted to Arbitron servers.

### Real portfolio value
The hardcoded `$12,480.00` constant is replaced with a `portfolioValue` field
that's fetched from real exchange balances on app launch and after each trade.
Pull-to-refresh on the Dashboard triggers a portfolio refresh.

### What was removed
- Demo trade history seeding (18 fake trades on first launch) — trades list
  starts empty and fills with real executions
- Hardcoded `portfolioValue` getter

### Files added
- `core/domain/credentials.dart` — `ExchangeCredentials` model
- `core/data/exchange_trading_client.dart` — `ExchangeTradingClient` interface
  + 5 implementations (Binance, Kraken, OKX, Bybit, Coinbase)
- `core/data/trading_service.dart` — orchestrates real execution

### Files changed
- `core/data/secure_key_store.dart` — per-exchange credential storage
- `core/app_cubit.dart` — async `executeOpportunity`, `_refreshPortfolio`,
  credential management methods
- `core/app_state.dart` — `portfolioValue` field (real), `executing` flag,
  no demo trades on init
- Settings: exchange credential entry sheet with key icon per exchange
- Dashboard: pull-to-refresh also refreshes portfolio

## Verification
- `flutter analyze` → 0 errors, 0 warnings
- `flutter test` → all tests pass
- `flutter build apk --release` → 56.8 MB APK

---

*Cryptocurrency trading involves significant risk of loss. Real order execution can result in actual financial loss. Ensure you understand the risks before enabling trade execution.*