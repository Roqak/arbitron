# Arbitron v2.5.3 — LLM Fine-Tuning on Trade History

The LLM now learns from the user's past trade outcomes via in-context learning.
Every LLM call (analysis, decisions, debriefs, daily summaries) now includes a
compressed summary of the user's trade history in the system prompt.

## Install
Download `arbitron-v2.5.3.apk` — Android 10+, ~56 MB.
- **Version:** 2.5.3 (versionCode 6) · `com.arbitron.arbitron`

## What's new

### LLM fine-tuning on user trade history (PRD §12 v2.5)
Rather than server-side model fine-tuning (which would require custody of user
data), Arbitron uses **in-context learning**: a `TradeHistorySummarizer`
compresses the user's trade history into a concise summary — total trades, win
rate, net P&L, avg win/loss, best/worst pairs, per-strategy and per-mode
performance — and injects it into the LLM system prompt on every call.

This adapts the AI's analysis to the user's actual results: it prefers pairs
and modes where the user has historically performed well and flags pairs with
consistent losses more cautiously.

A "Learning" chip appears on the Dashboard's AI Activity section when ≥ 5
trades have been recorded, indicating the LLM is using historical context.

### Files added
- `core/data/trade_history_summarizer.dart` — compresses trade history into
  an LLM-ready system prompt supplement

### Changes
- `LlmService` now holds a `tradeHistory` list and builds an enhanced system
  prompt via `TradeHistorySummarizer.buildEnhancedSystemPrompt()`
- `AppCubit` syncs trade history to the LLM service on init and after each
  executed trade
- Dashboard: "Learning" chip on AI Activity when ≥ 5 trades

## Verification
- `flutter analyze` → 0 errors, 0 warnings
- `flutter test` → all tests pass
- `flutter build apk --release` → 55.6 MB APK

---

*Cryptocurrency trading involves significant risk of loss. AI analysis is not financial advice.*