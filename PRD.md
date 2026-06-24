# ARBITRON
## AI-Powered Crypto Arbitrage Platform

**Version:** 1.0 — Initial Release
**Status:** Draft — For Review
**Date:** June 24, 2026
**Platform:** Flutter (iOS & Android)

---

## 1. Executive Summary

Arbitron is a Flutter-based mobile application that enables cryptocurrency traders to discover, evaluate, and execute arbitrage opportunities across centralized exchanges (CEXs) and decentralized exchanges (DEXs). The app integrates an OpenAI-configured LLM as an intelligent co-pilot that analyzes market conditions, evaluates opportunity viability after fees and slippage, and — when authorized — executes trades autonomously on behalf of the user.

Arbitron is not a "guaranteed profit" system. Instead, it is a sophisticated decision-support and execution platform that gives traders a meaningful edge through speed, data aggregation, and AI-driven analysis — while maintaining full transparency about risks, costs, and outcomes.

### Core Value Propositions

- **Unified monitoring** across all major CEXs and DEXs from a single interface
- **AI-powered opportunity scoring** that accounts for fees, slippage, transfer time, and liquidity
- **Flexible execution modes:** Manual (user approves every trade), Semi-Auto (AI recommends, user confirms), and Autonomous (AI executes within user-defined risk limits)
- **Pluggable strategy engine:** users switch between arbitrage strategies without re-configuring the whole app
- **Full audit trail** of every decision, recommendation, and execution

---

## 2. Goals & Non-Goals

### 2.1 Goals

- Aggregate real-time price feeds from 15+ CEXs and 10+ DEXs across major chains
- Surface viable arbitrage opportunities with profit estimates net of all costs
- Support at least 5 distinct arbitrage strategies, switchable at runtime
- Allow users to configure which exchanges are active, with per-exchange API credentials
- Provide three execution modes (Manual, Semi-Auto, Autonomous) togglable per strategy
- Use an LLM (OpenAI-compatible) to explain every opportunity and decision in plain language
- Deliver sub-5-second opportunity detection latency for CEX pairs
- Maintain a complete immutable log of all AI recommendations and executed trades

### 2.2 Non-Goals

- Arbitron does not guarantee profitable outcomes — no trading system can
- Arbitron does not provide tax advice or reporting (future phase)
- Arbitron is not a portfolio management or DeFi yield-farming platform
- Arbitron will not custody user funds — users connect their own exchange accounts and wallets
- High-frequency trading at sub-millisecond latency is out of scope for v1

---

## 3. User Personas

### Persona A — The Active Trader

- **Background:** Experienced retail crypto trader, 3+ years in the market
- **Goal:** Spot and execute arbitrage manually faster than competitors
- **Pain point:** Monitoring 10+ exchanges simultaneously is exhausting
- **Execution mode:** Manual or Semi-Auto
- **Key feature need:** Real-time alerts, clear spread data, one-tap execution

### Persona B — The Algo Delegator

- **Background:** Technical user comfortable with APIs and risk parameters
- **Goal:** Let the AI run approved strategies 24/7 without babysitting
- **Pain point:** Can't monitor markets overnight; misses opportunities
- **Execution mode:** Autonomous with strict risk limits
- **Key feature need:** Strategy configurator, risk caps, detailed audit log

### Persona C — The DeFi Explorer

- **Background:** Web3-native user interacting with DEXs and on-chain protocols
- **Goal:** Exploit cross-chain and DEX-CEX price gaps using wallet connections
- **Pain point:** Gas estimation and bridge latency make DEX arb opaque
- **Execution mode:** Semi-Auto (approves DEX transactions before signing)
- **Key feature need:** Wallet integration, gas estimates, bridge time visibility

---

## 4. Supported Exchanges & DEXs

Users can enable or disable any exchange individually in Settings. Each exchange requires its own API key configuration. DEXs are connected via wallet adapters and read-only RPC endpoints where trading is not required.

### 4.1 Centralized Exchanges (CEX)

| Exchange | Region Focus | Maker/Taker Fee | API Supported |
|----------|-------------|-----------------|---------------|
| Binance | Global | 0.10% / 0.10% | REST + WebSocket |
| Coinbase Advanced | US / EU | 0.00–0.40% | REST + WebSocket |
| Kraken | EU / US | 0.16% / 0.26% | REST + WebSocket |
| OKX | Global | 0.08% / 0.10% | REST + WebSocket |
| Bybit | Global | 0.01% / 0.10% | REST + WebSocket |
| KuCoin | Global | 0.10% / 0.10% | REST + WebSocket |
| Gate.io | Global | 0.20% / 0.20% | REST + WebSocket |
| Bitfinex | Global | 0.10% / 0.20% | REST + WebSocket |
| Huobi / HTX | Asia | 0.20% / 0.20% | REST + WebSocket |
| MEXC | Global | 0.00% / 0.05% | REST + WebSocket |

### 4.2 Decentralized Exchanges (DEX)

| DEX | Chain | Protocol Fee | Integration Method |
|-----|-------|--------------|-------------------|
| Uniswap v3/v4 | Ethereum / L2s | 0.05–1.00% | SDK + RPC |
| PancakeSwap | BNB Chain | 0.25% | SDK + RPC |
| Curve Finance | Ethereum / Multi | 0.04% | SDK + RPC |
| dYdX v4 | Cosmos / dYdX Chain | 0.05% / 0.20% | REST API |
| Raydium | Solana | 0.25% | Solana Web3.js |
| Jupiter Aggregator | Solana | Variable | Jupiter API |
| Velodrome | Optimism | 0.02–0.05% | SDK + RPC |
| Aerodrome | Base | 0.02–0.05% | SDK + RPC |
| Orca | Solana | 0.30% | Solana Web3.js |
| SushiSwap | Multi-chain | 0.30% | SDK + RPC |

> **Note:** DEX transactions require the user to connect a self-custody wallet (MetaMask, Phantom, WalletConnect). Arbitron never holds private keys.

---

## 5. Arbitrage Strategies

Users can enable one or more strategies simultaneously. Each strategy can be independently configured with its own execution mode, risk limits, and AI persona instructions.

### 5.1 Strategy Overview

| Strategy | Description | Complexity | Latency Need |
|----------|-------------|------------|--------------|
| Simple Cross-Exchange | Buy on Exchange A, sell on Exchange B for the same asset | Low | Medium (2–10s) |
| Triangular Arbitrage | Exploit rate inefficiencies across 3 trading pairs within one exchange | Medium | Low (<1s) |
| DEX-CEX Arbitrage | Price gap between a DEX pool and a centralized order book | High | High (<3s) |
| Statistical / Pairs Trading | Mean-reversion on historically correlated asset pairs | High | Low |
| Flash Loan Arbitrage | DeFi on-chain atomic arbitrage using flash loans (no capital needed) | Very High | On-chain |

### 5.2 Strategy Configuration

Each strategy exposes the following configurable parameters in the Strategy Editor:

- **Enabled / Disabled** toggle
- **Execution Mode:** Manual | Semi-Auto | Autonomous
- **Minimum net profit threshold** (USD or %) — opportunities below this are suppressed
- **Maximum trade size** (USD)
- **Maximum concurrent positions**
- **Allowed asset pairs** (whitelist or all)
- **Allowed exchanges** (subset of enabled exchanges)
- **AI aggressiveness:** Conservative | Balanced | Aggressive (affects LLM risk scoring)
- **Custom LLM instructions** (plain text field to steer the AI's reasoning)
- **Stop-loss trigger:** auto-disable strategy if daily loss exceeds threshold

---

## 6. Execution Modes

Each strategy can run in one of three execution modes. The mode can be changed at any time from the Strategy Editor without interrupting active monitoring.

### Manual Mode

The app monitors markets and surfaces opportunities via alerts. The LLM provides an analysis and recommendation for each opportunity. The user reviews the analysis and decides whether to execute. All order placement is manual — the app generates the order parameters; the user taps "Execute" to confirm.

> **Best for:** new users, high-value trades, situations where the user wants full control.

### Semi-Auto Mode

The LLM evaluates each opportunity and, if it meets the configured thresholds, presents a pre-filled execution proposal with a countdown timer (default: 30 seconds, configurable). If the user does not cancel within the countdown, the trade executes automatically. The user can also tap "Execute Now" to skip the countdown or "Reject" to dismiss.

> **Best for:** users who want speed but still want a review window and the ability to veto.

### Autonomous Mode

The LLM operates within the user-defined risk parameters and executes trades without requiring confirmation. All actions are logged in real time and the user receives push notifications for every execution. The user can pause autonomous mode globally at any time via a one-tap "Kill Switch" accessible from any screen.

> **Best for:** experienced users comfortable with their configured risk limits who want 24/7 coverage.

> **Requires explicit opt-in** with a risk acknowledgement prompt. Re-confirmation required after app update.

### 6.1 Global Kill Switch

A persistent floating action button is visible across all screens when Autonomous mode is active on any strategy. Tapping it immediately pauses all autonomous execution, cancels any pending LLM decisions, and notifies the user. Autonomous mode must be manually re-enabled per strategy.

---

## 7. LLM Integration (AI Co-Pilot)

Arbitron integrates with any OpenAI-compatible API endpoint. The LLM acts as the reasoning layer: it interprets raw market data, scores opportunities, generates human-readable explanations, and — in Autonomous mode — makes execution decisions.

### 7.1 LLM Configuration

| Parameter | Description |
|-----------|-------------|
| API Endpoint | User-configurable (OpenAI default; supports any OpenAI-compatible host) |
| Model | User-selectable from a dropdown populated via `/v1/models` (defaults to `gpt-4o`) |
| API Key | Stored in device keychain (never transmitted to Arbitron servers) |
| System Prompt | Base prompt injected by the app; user can append custom instructions per strategy |
| Temperature | Fixed at 0.2 for decision tasks; 0.7 for explanation generation |
| Max Tokens | 2048 for analysis; 512 for execution decisions (JSON only) |

### 7.2 LLM Task Types

#### Opportunity Analysis

Triggered when a new opportunity meets the minimum threshold. The LLM receives: pair, spread %, estimated net profit, exchange fees, estimated transfer/block time, liquidity depth, recent volatility, and the user's custom instructions. Output: a plain-language explanation (3–5 sentences) and a score from 0–100.

#### Execution Decision (Autonomous Mode)

Triggered after Opportunity Analysis if score exceeds the strategy's minimum. The LLM receives the analysis output plus current portfolio exposure, open positions, and daily P&L. Output: a structured JSON object with fields: `execute` (boolean), `confidence` (0–1), `reasoning` (string), `suggested_size_usd` (number).

#### Post-Trade Debrief

Triggered after a trade closes. The LLM receives entry/exit prices, actual vs. estimated profit, and slippage. Output: a short debrief explaining what happened and any lessons for future decisions.

#### Daily Summary

Generated once per day (user-configurable time). The LLM receives the full day's trade log and produces a performance narrative including P&L summary, best/worst opportunities, and a recommendation for strategy parameter adjustments.

---

## 8. Feature Specifications

### 8.1 Dashboard

- Live ticker strip showing top 5 active opportunities sorted by net profit
- Portfolio summary: total allocated capital, unrealised P&L, day's realised P&L
- Active strategies summary cards with current mode indicator
- Recent AI activity feed (last 10 LLM decisions/analyses)
- Global Kill Switch button (visible when any strategy is in Autonomous mode)
- Market health indicator: aggregate exchange connectivity status

### 8.2 Opportunities Screen

- Filterable list of all detected opportunities (active and historical)
- Each card: asset pair, buy exchange, sell exchange, gross spread, estimated fees, net profit, confidence score, time detected
- Tap to expand: full LLM analysis text, order book depth chart, fee breakdown, execution button
- Filters: strategy, exchange, minimum profit, asset class, mode
- Sort: net profit, confidence score, detected time, spread %

### 8.3 Strategy Manager

- List of all strategies with status badge (Active / Paused / Disabled) and current mode
- Tap to enter Strategy Editor with all configurable parameters
- Drag-to-reorder strategy evaluation priority
- Quick-toggle execution mode without entering full editor
- Strategy performance stats: total trades, win rate, average profit, total P&L

### 8.4 Exchange & DEX Configuration

- Per-exchange configuration screen: API Key, API Secret, Passphrase (if required), enabled pairs
- Connection test button with live latency readout
- DEX configuration: chain selection, RPC endpoint (default or custom), wallet connection
- Wallet adapter: WalletConnect v2, MetaMask mobile deep link, Phantom (Solana)
- Gas settings for DEX: auto / custom gwei, max gas spend per transaction
- Exchange enable/disable toggle — disabled exchanges are excluded from all strategy scans

### 8.5 Trade History & Audit Log

- Complete immutable log of every trade executed through the app
- Each entry: timestamp, strategy, pair, exchanges, sizes, entry/exit prices, gross/net P&L, execution mode, LLM decision JSON
- Export to CSV or JSON
- AI debrief visible inline per trade
- Filter by date range, strategy, exchange, outcome (profit/loss)

### 8.6 Settings

- LLM API configuration (endpoint, model, key)
- Notification preferences (per event type: opportunity found, trade executed, strategy paused, daily summary)
- Risk defaults: global maximum daily loss cap (auto-pauses all autonomous strategies if hit)
- Theme: Light / Dark / System
- Currency display: USD, EUR, BTC, ETH
- Biometric lock for settings and trade execution
- Data retention: configurable log retention period

---

## 9. Screen Map & Navigation

Arbitron uses a bottom navigation bar with 5 top-level destinations. Deep flows (strategy editor, exchange config, trade detail) live in modal sheets or pushed routes.

| Nav Tab | Icon | Screens / Sub-flows |
|---------|------|---------------------|
| Dashboard | Chart line | Live overview, opportunity ticker, portfolio summary, AI feed |
| Opportunities | Sparkles | Opportunity list → Opportunity detail (analysis + execute) |
| Strategies | Sliders | Strategy list → Strategy editor → Backtest result |
| History | Clock | Trade log → Trade detail → AI debrief |
| Settings | Gear | Exchange config, Wallet config, LLM config, Notifications, Risk limits |

---

## 10. Technical Requirements

### 10.1 Flutter App Architecture

| Parameter | Specification |
|-----------|--------------|
| Architecture pattern | Feature-first Clean Architecture with BLoC state management |
| Min Flutter version | Flutter 3.19+ / Dart 3.3+ |
| Min OS support | iOS 16+ / Android 10 (API 29)+ |
| State management | flutter_bloc + Hydrated BLoC for persistence |
| Networking | dio with retry interceptors; WebSocket via web_socket_channel |
| Secure storage | flutter_secure_storage (keychain / keystore) |
| Local DB | drift (SQLite) for trade logs and opportunity cache |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Wallet integration | walletconnect_flutter_v2, solana_web3 |

### 10.2 Backend / Infrastructure

| Component | Technology |
|-----------|------------|
| Price aggregation | Edge worker (Cloudflare Workers or AWS Lambda@Edge) polling exchange APIs and broadcasting via WebSocket |
| LLM proxy | Thin serverless proxy to add auth headers; user's API key is passed per-request, not stored server-side |
| Analytics | PostHog (self-hostable) for anonymous usage analytics |
| Crash reporting | Sentry |
| No server-side custody | All keys, credentials, and funds remain on-device or directly on exchanges |

### 10.3 Performance Requirements

| Metric | Target |
|--------|--------|
| Opportunity detection (CEX) | < 5 seconds from price update to in-app alert |
| Opportunity detection (DEX) | < 15 seconds (on-chain block latency) |
| LLM analysis response | < 8 seconds (p95) |
| App cold start | < 2.5 seconds on mid-range device |
| Exchange API polling interval | 500ms for WebSocket; 2s polling fallback |
| Offline behavior | Read-only access to cached data; all execution disabled |

---

## 11. Risk & Compliance

Arbitron is a tool that facilitates user-directed trading. The following safeguards are built into the product by design.

### 11.1 Built-In Risk Controls

- **Global daily loss cap:** autonomous strategies auto-pause if aggregate daily loss exceeds user-set limit
- **Per-trade size caps:** configurable maximum order size per strategy
- **Concurrent position limit:** maximum number of open positions across all strategies
- **Slippage guard:** orders that would execute with > N% worse than expected price are cancelled and flagged
- **Exchange connectivity check:** autonomous execution is blocked if exchange WebSocket connection is stale (> 10s)
- **Dry Run mode:** users can test any strategy in simulation mode without real capital

### 11.2 Legal & Regulatory

- Arbitron does not provide financial advice. All LLM outputs are clearly labelled "AI analysis — not financial advice"
- Users are responsible for compliance with local regulations on automated trading
- Terms of Service explicitly state that profit is not guaranteed and past AI performance does not predict future results
- The app must comply with App Store and Google Play policies on financial apps
- GDPR / CCPA: no personal data stored server-side; all data is on-device or on user's exchange accounts

---

## 12. Phased Roadmap

| Phase | Timeline | Scope |
|-------|----------|-------|
| **v1.0 — MVP** | Month 1–3 | CEX monitoring (5 exchanges), Simple Cross-Exchange strategy, Manual + Semi-Auto modes, LLM analysis, Basic dashboard, Trade history |
| **v1.5 — DEX & Auto** | Month 4–5 | DEX support (Uniswap, PancakeSwap, Jupiter), Autonomous mode + Kill Switch, Strategy Manager with 3 strategies, Exchange config screen |
| **v2.0 — Full Platform** | Month 6–8 | All 15+ CEXs and 10 DEXs, All 5 strategies, Flash loan support (Ethereum), Daily LLM summary, CSV/JSON export, Biometric lock |
| **v2.5 — Intelligence+** | Month 9–11 | Strategy backtesting, LLM fine-tuning on user's own trade history, Cross-chain bridge integrations, Custom strategy builder (no-code) |
| **v3.0 — Ecosystem** | Month 12+ | Social leaderboard (opt-in), Strategy marketplace, API access for power users, Tax export integrations |

---

## 13. Success Metrics

### 13.1 Product KPIs

| Metric | v1.0 Target | v2.0 Target |
|--------|-------------|-------------|
| DAU / MAU ratio | 30% | 45% |
| Opportunities detected / DAU | > 10 | > 25 |
| LLM analysis satisfaction (thumbs up) | > 70% | > 80% |
| Autonomous mode adoption (of active users) | — | > 25% |
| Trade execution error rate | < 2% | < 0.5% |
| App crash-free rate | > 99% | > 99.5% |
| Avg opportunity detection latency | < 5s | < 3s |

### 13.2 Business KPIs

- Month 3: 1,000 active users; 200 connected exchange accounts
- Month 6: 5,000 active users; 500 Autonomous mode users
- Month 12: 20,000 active users; App Store rating ≥ 4.4

---

*Arbitron PRD v1.0 — Confidential & Internal — Subject to change*

*This document does not constitute financial advice. Cryptocurrency trading involves significant risk of loss.*
