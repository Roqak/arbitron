# Arbitron v2.5.4 — Cross-Chain Bridge Integrations

The opportunity scanner now factors in cross-chain bridge costs and latency
when a DEX-CEX arbitrage requires moving assets between chains.

## Install
Download `arbitron-v2.5.4.apk` — Android 10+, ~56 MB.
- **Version:** 2.5.4 (versionCode 7) · `com.arbitron.arbitron`

## What's new

### Cross-chain bridge integrations (PRD §12 v2.5)
When a DEX-CEX opportunity involves exchanges on different chains (e.g. buy on
a Solana DEX, sell on an Ethereum CEX), the scanner now:

1. Detects the chain mismatch via a `BridgeCatalog` of 10 routes (Hop, Across,
   Celer, Wormhole, deBridge, Stargate)
2. Finds the cheapest bridge route between the two chains
3. Subtracts the bridge cost (fixed fee + percentage) from the net profit
4. Includes the bridge name and estimated time in the opportunity analysis

The Opportunity detail sheet now shows **Bridge**, **Bridge cost**, and
**Bridge time** rows when a bridge is required. The LLM analysis text notes the
bridge requirement and estimated latency.

### Files added
- `core/domain/bridge.dart` — `BridgeRoute`, `BridgeCatalog` with 10 routes

### Changes
- `Opportunity` model: added `bridgeName`, `bridgeCostUsd`, `bridgeTime` fields
- `OpportunityScanner`: detects chain mismatches, finds cheapest bridge,
  deducts bridge cost from net profit, includes bridge info in analysis
- Opportunity detail sheet: shows bridge rows when required

## Verification
- `flutter analyze` → 0 errors, 0 warnings
- `flutter test` → all tests pass
- `flutter build apk --release` → 55.7 MB APK

---

*Cryptocurrency trading involves significant risk of loss. Bridge costs and latency estimates are approximate.*