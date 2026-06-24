# Arbitron v4.0.0 — Radical Redesign (Terminal-Native)

A complete visual overhaul of Arbitron. The app is reimagined as a
terminal-native trading instrument: monospace-forward, one electric accent,
hierarchy through type instead of cards, and a Kill Switch that feels like a
physical emergency stop.

## Install
Download `arbitron-v4.0.0.apk` — Android 10+, ~57 MB.
- **Version:** 4.0.0 (versionCode 13) · `com.arbitron.arbitron`

## What's new

### New design system (DESIGN.md v2)
A radical departure from the v1 mint-green Material aesthetic:

- **Dual typeface:** JetBrains Mono for ALL numeric data (prices, P&L, spreads,
  scores, timestamps, labels in caps). Inter for prose and UI chrome. The
  visual distinction between "reading" and "scanning numbers" is immediate.
- **Electric cyan accent** `#00E5CC` replaces the old mint green. More energy,
  reads as "live data" on dark surfaces.
- **Violet AI color** `#8B7BFF` for LLM-generated content. Distinct from the
  accent, signals "machine-generated."
- **Killed card-everything.** Sections are now organized by typographic
  hierarchy and hairline dividers, not card containers. Cards used only for
  discrete list items (opportunities, trades).
- **Tighter spacing:** 20dp screen margins (was 24), 28dp sections (was 32).
  Denser without being cramped.
- **Mono caps labels** for all sections and fields (was Inter title case).
- **Nav labels** are now mono caps abbreviations: DASH, OPPS, STRAT, HIST, SETUP.

### New components
- **MonoText** — the atomic numeric display, always JetBrains Mono with tabular
  figures.
- **DataKV** — key-value row: Inter label left, Mono value right.
- **ScoreBar** — 3-segment gauge replacing the old score chip. More scannable.
- **KillSwitchBar** — wide pill bar above bottom nav with "EMERGENCY STOP"
  label. Replaces the floating FAB. More like a physical E-stop.
- **SectionLabel** — mono caps section header with optional trailing widget.
- **Hairline** — the structural divider between sections.

### All 5 screens rebuilt
Every screen has been rebuilt with the new design language:
- **Dashboard:** terminal-style header with LIVE/CONNECTING status, portfolio as
  typographic hierarchy (no card), ticker strip, strategy rows, AI activity,
  market health, community
- **Opportunities:** compact cards with mono numbers, score bars, filter bar
- **Strategies:** panel-based cards with mode chips, backtest buttons
- **History:** trade cards with mono P&L, filter segmented control
- **Settings:** sectioned panels with mono caps headers, all sub-sheets rebuilt

### PRODUCT.md
A new strategic context file defining the product's register (product),
users, brand personality, anti-references, and strategic design principles.

## Verification
- `flutter analyze` → 0 errors, 0 warnings
- `flutter test` → all tests pass
- `flutter build apk --release` → 56.6 MB APK

---

*Cryptocurrency trading involves significant risk of loss. AI analysis is not financial advice.*