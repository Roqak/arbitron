# Arbitron v3.0.2 — Strategy Marketplace

Browse, preview, and install community strategies from an in-app marketplace.

## Install
Download `arbitron-v3.0.2.apk` — Android 10+, ~56 MB.
- **Version:** 3.0.2 (versionCode 10) · `com.arbitron.arbitron`

## What's new

### Strategy marketplace (PRD §12 v3.0 — Strategy marketplace)
A "Market" button on the Strategies screen opens the marketplace sheet:

- **6 curated strategies:** BTC Grid Scout, ETH Triangular Pro, Solana DEX-CEX
  Bridge, Statistical Pairs ETH/BTC, Flash Loan Atomic, Altcoin Sweep
- **Each listing shows:** author, description, tags, backtest stats (win rate,
  trade count, P&L), install count, and a star rating
- **Install button:** one-tap install creates a new strategy in the user's
  Strategies list (disabled by default — the user reviews and enables it)
- **Installed strategies** are fully editable like any user-created strategy

### Files added
- `core/domain/marketplace.dart` — `MarketplaceStrategy`, `MarketplaceCatalog`
- `features/strategies/marketplace_sheet.dart` — listing cards with install

### Changes
- Strategies screen header: "Market" button alongside "Builder"

## Verification
- `flutter analyze` → 0 errors, 0 warnings
- `flutter test` → all tests pass
- `flutter build apk --release` → 56.0 MB APK

---

*Cryptocurrency trading involves significant risk of loss. Marketplace strategies are community-created and their backtest results do not predict future performance.*