# Arbitron Design System

**Version:** 1.0 — MVP
**Last updated:** June 24, 2026

This document is the single source of truth for Arbitron's visual language. Every screen, component, and interaction in the app must conform to the tokens, patterns, and principles defined here. When in doubt, defer to this document.

---

## 1. Design Principles

1. **Calm competence.** Trading apps are loud by default. Arbitron is not. Information is dense but legible; motion is purposeful; color carries meaning, not decoration.
2. **Numbers first.** This is a numbers product. Every monetary figure, percentage, and timestamp is treated as a first-class citizen — right-aligned, tabular figures, never truncated, never ambiguous.
3. **Trust through clarity.** The app handles risk. Surfaces, labels, and confirmation flows must make the cost, the consequence, and the source of every value unambiguous. No dark patterns, no hidden fees, no surprise executions.
4. **Dark-native, not dark-adapted.** The default theme is dark and is designed against dark surfaces first. Light mode is a faithful translation, not an afterthought.
5. **One accent, used sparingly.** A single mint-green accent carries the brand and signals positive/active state. Red signals loss or danger. Everything else lives on a neutral ramp. Restraint is the brand.

---

## 2. Color System

All colors are defined as semantic tokens in `lib/core/theme/app_colors.dart`. Never reference raw hex values in feature code — always use the token.

### 2.1 Dark Theme (default)

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#0A0E14` | App canvas, the deepest layer |
| `surface` | `#121821` | Cards, sheets, elevated surfaces |
| `surfaceRaised` | `#1A2330` | Inputs, nested cards, hover states |
| `surfaceOverlay` | `#222E40` | Modals, popovers, menus |
| `borderSubtle` | `#1F2937` | Hairline dividers, card outlines |
| `borderStrong` | `#2D3A4F` | Focused inputs, active selection |
| `textPrimary` | `#F1F5F9` | Primary text, headings |
| `textSecondary` | `#94A3B8` | Labels, secondary copy |
| `textMuted` | `#64748B` | Placeholders, disabled, timestamps |
| `accent` | `#34F5A0` | Mint — primary brand, positive, active, CTAs |
| `accentDim` | `#0F3D2E` | Accent backgrounds (chips, selected states) |
| `success` | `#34F5A0` | Profit, completed (same as accent) |
| `danger` | `#FF5470` | Loss, error, kill switch, destructive |
| `dangerDim` | `#3D0F1A` | Danger backgrounds |
| `warning` | `#FFB547` | Caution, semi-auto countdown, slippage flag |
| `warningDim` | `#3D2E0F` | Warning backgrounds |
| `info` | `#5B9DFF` | Neutral informational, AI feed accents |
| `infoDim` | `#0F2A3D` | Info backgrounds |

### 2.2 Light Theme

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#F7F9FC` | App canvas |
| `surface` | `#FFFFFF` | Cards, sheets |
| `surfaceRaised` | `#F1F5F9` | Inputs, nested cards |
| `surfaceOverlay` | `#FFFFFF` | Modals (with shadow) |
| `borderSubtle` | `#E2E8F0` | Hairline dividers |
| `borderStrong` | `#CBD5E1` | Focused inputs |
| `textPrimary` | `#0F172A` | Primary text |
| `textSecondary` | `#475569` | Secondary copy |
| `textMuted` | `#94A3B8` | Placeholders, timestamps |
| `accent` | `#0FB372` | Mint (darkened for contrast on light) |
| `accentDim` | `#D6F5E8` | Accent backgrounds |
| `success` | `#0FB372` | Profit |
| `danger` | `#E11D48` | Loss, error |
| `dangerDim` | `#FCE7ED` | Danger backgrounds |
| `warning` | `#D97706` | Caution |
| `warningDim` | `#FEF3C7` | Warning backgrounds |
| `info` | `#2563EB` | Information |
| `infoDim` | `#DBEAFE` | Info backgrounds |

### 2.3 Semantic Usage Rules

- **Profit/loss** must always use `success`/`danger`. Never use green/red from any other ramp.
- **The accent (mint)** is reserved for: primary CTAs, active/selected states, brand marks, and positive P&L. Do not use it for decorative gradients or large background fills.
- **Kill Switch** uses `danger` as a solid fill on the FAB — it is the only persistently red element in the app.
- **Semi-Auto countdown** uses `warning` for the timer ring and numeric countdown.
- **AI-originated content** (LLM analysis text, AI feed items) carries a thin `info` left border or `info`-tinted background to distinguish it from user/system content.
- Disabled controls reduce opacity to 0.4, never change hue.

---

## 3. Typography

**Typeface:** Inter (variable). Loaded via `google_fonts` package with `GoogleFonts.interTextTheme()`.

If Inter fails to load, the system sans-serif fallback is acceptable; never use serif or monospace for UI chrome.

### 3.1 Type Scale

| Token | Size / Weight / Line-height | Usage |
|-------|------------------------------|-------|
| `displayLarge` | 32 / 700 / 1.15 | Empty-state hero, onboarding titles |
| `displayMedium` | 28 / 700 / 1.2 | Screen titles on Dashboard |
| `headlineMedium` | 22 / 600 / 1.25 | Section headers |
| `headlineSmall` | 18 / 600 / 1.3 | Card titles, sheet headers |
| `titleLarge` | 16 / 600 / 1.3 | List item titles, strategy names |
| `titleMedium` | 14 / 600 / 1.4 | Row titles, tab labels (active) |
| `bodyLarge` | 16 / 400 / 1.5 | Primary body, LLM analysis text |
| `bodyMedium` | 14 / 400 / 1.5 | Secondary body, descriptions |
| `bodySmall` | 12 / 400 / 1.45 | Metadata, helper text |
| `labelLarge` | 14 / 600 / 1.2 | Button text |
| `labelMedium` | 12 / 600 / 1.2 | Badges, chip text, status labels |
| `labelSmall` | 11 / 600 / 1.2 | Micro-labels, ticker symbols suffix |

### 3.2 Numeric Typography

All monetary values, percentages, spreads, and timestamps use **tabular figures** (`fontFeatures: [FontFeature.tabularFigures()]`). This is non-negotiable for a trading UI — proportional digits make price columns jitter.

| Context | Style |
|---------|-------|
| Large P&L / portfolio value | `displayMedium`, tabular figures, color follows sign |
| Opportunity net profit | `titleLarge`, tabular figures, `success`/`danger` |
| Price / spread cells in lists | `bodyMedium`, tabular figures, `textPrimary` |
| Timestamps | `bodySmall`, `textMuted`, tabular figures |
| Percentage change | `bodyMedium`, tabular figures, sign-prefixed (`+`/`−`), color follows sign |

Use the Unicode minus (`−`, U+2212) for negative numbers, not the ASCII hyphen.

---

## 4. Spacing & Layout

### 4.1 Spacing Scale

A 4pt base grid. Tokens are exposed as `AppSpacing.xs` … `AppSpacing.xxl`.

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4 | Tight gaps within a chip/badge, icon-to-text padding |
| `sm` | 8 | Default interior gap inside cards, list row leading/trailing |
| `md` | 12 | Gap between fields in a form, gap between card contents |
| `lg` | 16 | Card padding, section-to-section gap |
| `xl` | 24 | Screen horizontal margin, section header to content |
| `xxl` | 32 | Major section breaks, empty-state illustration padding |
| `xxxl` | 48 | Screen top/bottom safe padding on scroll views |

### 4.2 Screen Layout

- **Horizontal screen margin:** `AppSpacing.xl` (24) on phones. Reduces to `lg` (16) at <360dp width.
- **Card padding:** `AppSpacing.lg` (16) all sides.
- **List row padding:** `sm` (8) vertical, `lg` (16) horizontal when in a card, `xl` (24) when full-bleed.
- **Section spacing:** `xxl` (32) between major sections on a scroll view.
- **Bottom nav:** fixed 56dp height plus bottom inset; content scroll views add `MediaQuery.padding.bottom + 72` as bottom sliver padding so content never hides behind the bar.

### 4.3 Corner Radius

| Token | Radius | Usage |
|-------|--------|-------|
| `xs` | 6 | Chips, badges, small inline pills |
| `sm` | 10 | Inputs, small buttons, segmented controls |
| `md` | 14 | Standard cards, list items in cards |
| `lg` | 20 | Large feature cards (portfolio summary, opportunity hero) |
| `xl` | 28 | Sheets, bottom sheets top corners, FAB |
| `pill` | 999 | Circular pills, status dots, the Kill Switch FAB |

Cards and inputs use `md`/`sm` by default. Do not mix radii within a single screen's card set.

### 4.4 Elevation (Dark Theme)

In dark mode, elevation is communicated by **surface color lift**, not shadow. The `surface` ramp (`#121821` → `#1A2330` → `#222E40`) encodes depth. Shadows are reserved for overlays that float above all content (modals, menus, the Kill Switch FAB).

| Level | Surface | Shadow | Usage |
|-------|---------|--------|-------|
| 0 | `background` | none | Screen canvas |
| 1 | `surface` | none | Cards in a list |
| 2 | `surfaceRaised` | none | Inputs, nested cards, hover |
| 3 | `surfaceOverlay` | `0 8 24 rgba(0,0,0,0.6)` | Modals, popovers, menus |
| FAB | `danger` | `0 6 16 rgba(255,84,112,0.4)` | Kill Switch only |

In light mode, use Material shadow tokens: level 1 = `0 1 3 rgba(15,23,42,0.08)`, level 2 = `0 2 8 rgba(15,23,42,0.10)`, level 3 = `0 8 24 rgba(15,23,42,0.14)`.

---

## 5. Components

### 5.1 Cards (`ArbitronCard`)

The fundamental surface. `surface` background, `borderSubtle` 1px border, `md` radius, `lg` padding. No shadow at level 1. A card may contain a header row (title + optional trailing action), body, and optional footer divider.

```
┌───────────────────────────────────┐
│  Title                     [icon] │
│  ─────────────────────────────────│
│  Body content                     │
│                                   │
│  ─────────────────────────────────│
│  Optional footer                  │
└───────────────────────────────────┘
```

### 5.2 Opportunity Card

The signature component. Compact form in lists, expanded form in detail.

**Compact:** buy/sell exchanges with a connecting arrow, asset pair as title, net profit in `titleLarge` with sign color, spread % and confidence score as `labelMedium` chips, time-detected in `bodySmall` trailing.

```
┌─────────────────────────────────────────────┐
│  BTC/USDT                          +$42.18   │
│  Binance → Kraken                  +0.42%    │
│  [score 87] [2s ago]                        │
└─────────────────────────────────────────────┘
```

**Expanded:** adds LLM analysis block (with `info` left border), order book depth mini-chart, fee breakdown rows, and the Execute button pinned to the card footer.

### 5.3 Chips & Badges

- **Status chip:** `labelMedium` text, `xs` radius, `xs` horizontal padding, colored `xxxDim` background with matching `xxx` text. e.g. Active = `accentDim`/`accent`, Paused = `warningDim`/`warning`, Disabled = `surfaceRaised`/`textMuted`.
- **Score chip:** pill, `accentDim` background, accent text, shows "score N" with a small dot indicating tier (0–40 muted, 41–70 warning, 71–100 accent).
- **Mode chip:** shows the execution mode icon + label. Manual = `info`, Semi-Auto = `warning`, Autonomous = `accent`.

### 5.4 Buttons

| Variant | Appearance | Usage |
|---------|-----------|-------|
| Primary | `accent` fill, `background` text, `sm` radius | Main CTA: Execute, Save, Connect |
| Danger | `danger` fill, `background` text | Destructive: Disconnect, Delete, Reject |
| Secondary | transparent, `borderStrong` border, `textPrimary` text | Cancel, secondary actions |
| Ghost | transparent, `textSecondary` text | Inline actions, "View all" |
| Pill | `surfaceRaised` fill, `textPrimary`, `pill` radius | Filter chips, segmented control |

All buttons: 44dp minimum tap height, `labelLarge` text, `sm` horizontal padding (min 16). Primary buttons use a subtle `accent` glow shadow in dark mode (`0 4 12 rgba(52,245,160,0.25)`).

### 5.5 Inputs (`ArbitronField`)

`surfaceRaised` background, `sm` radius, `borderSubtle` 1px (becomes `borderStrong` on focus), 48dp height, `md` internal padding. Label above as `labelMedium` `textSecondary`. Helper/error text below as `bodySmall`. Error state: `danger` border + `danger` helper text. Never use underlines for inputs in this app.

### 5.6 Segmented Control

For choosing between 2–4 options (execution mode, theme, timeframe). `surfaceRaised` container, `pill` segments, selected segment gets `accent` background + `background` text. Unselected: `textSecondary`.

### 5.7 Kill Switch FAB

Persistent when any strategy is in Autonomous mode. 56dp circle, `danger` fill, white pause icon, `xl` shadow with danger tint. Positioned bottom-right, 16dp from edges, lifted above the bottom nav. Tapping opens a confirmation sheet: "Pause all autonomous strategies?" with Danger/Cancel buttons. After activation, the FAB becomes an `accent` play button to resume.

### 5.8 Bottom Navigation

5 tabs as defined in the PRD screen map. Dark: `background` bar, `borderSubtle` top border, inactive icons `textMuted`, active icon + label `accent`. Icons: `Icons.show_chart` (Dashboard), `Icons.auto_awesome` (Opportunities), `Icons.tune` (Strategies), `Icons.history` (History), `Icons.settings` (Settings). Selected tab shows a 4dp-tall, 24dp-wide `accent` pill indicator above the icon.

### 5.9 Top App Bar

Transparent, blends with `background`. Leading: screen title in `headlineMedium`. Trailing: contextual action (filter icon, add button). Height 56dp + status bar inset. Only gets a `borderSubtle` bottom border when content scrolls beneath it (use a scroll-aware fade).

### 5.10 Ticker Strip

Horizontal auto-scrolling row on the Dashboard showing top 5 opportunities. Each item: asset symbol `titleMedium`, net profit `labelMedium` in sign color. Items separated by a 1px `borderSubtle` vertical divider. Scrolls horizontally; pauses on tap.

### 5.11 AI Analysis Block

LLM-generated text is always presented in a container with a 3px-wide `info` left border, `infoDim` background at 0.5 opacity, `md` radius on the right side (square on the left). Header row: a small "AI" badge (`infoDim`/`info`) + "AI analysis — not financial advice" in `labelSmall` `textMuted`. Body in `bodyLarge` `textPrimary`. This visual treatment is mandatory for all LLM output to distinguish it from system data.

### 5.12 Sheets

Bottom sheets use `surfaceOverlay`, `xl` top radius, `xl` top padding with a 32dp-wide `borderStrong` drag handle centered. Sheet title in `headlineSmall`. Content scrolls; primary action pinned to bottom with `xl` padding and safe-area inset.

---

## 6. Iconography

**Library:** Material Symbols (rounded variant). Do not mix icon families.

- Stroke weight: 400 (regular) for nav and inline, 500 for actions.
- Size: 20dp inline, 24dp in app bars and nav, 16dp in chips.
- Color follows context: `textSecondary` by default, `accent` for active, `danger` for destructive.
- Exchange/chain logos are out of scope for MVP — use a generic circular avatar with the exchange's first letter in `titleMedium` on `surfaceRaised`.

---

## 7. Motion

Motion is quiet and functional. No bouncing, no parallax, no decorative animation.

| Transition | Duration | Curve |
|-----------|----------|-------|
| Tab switch | 200ms | `Curves.easeOutCubic` |
| Card tap → detail | 250ms | `Curves.easeOutCubic` (shared element where possible) |
| Sheet present | 280ms | `Curves.easeOutCubic` |
| Sheet dismiss | 200ms | `Curves.easeInCubic` |
| Dialog present | 150ms | `Curves.easeOutCubic` |
| List item enter | 180ms, staggered 40ms | `Curves.easeOut` |
| Value change (P&L) | 350ms color pulse | `Curves.easeInOut` — flash `success`/`danger` at 0.15 opacity then settle |
| Semi-auto countdown ring | linear with wall clock | n/a |
| Kill switch activation | 120ms scale to 0.92 then back | `Curves.easeOut` |

Avoid animating layout-affecting properties (width/height of cards). Animate opacity, transform, and explicit `SizedBox` heights only.

---

## 8. Empty & Error States

### 8.1 Empty States

Every list screen ships with a purpose-built empty state. Center-aligned, `xxl` top padding:

- Illustration: a simple line icon in `textMuted`, 64dp, inside a `surfaceRaised` 96dp circle.
- Title: `headlineSmall` `textPrimary`.
- Body: `bodyMedium` `textSecondary`, max 2 lines.
- Action: a Secondary or Primary button if the user can resolve it (e.g. "Connect an exchange" on Opportunities empty).

Example copy:
- Opportunities empty: "No opportunities yet" / "Connect an exchange and enable a strategy to start scanning."
- History empty: "No trades yet" / "Executed trades will appear here with full audit details."
- Strategies empty: "No strategies configured" / "Add your first arbitrage strategy to begin."

### 8.2 Error States

Inline errors use `danger` text on the relevant field. Full-screen error (network down, no exchanges connected) uses a centered block: `danger` icon, "Something went wrong" title, specific message, retry button. Never show a bare stack trace or raw exception to the user.

---

## 9. Theming Implementation

- `lib/core/theme/app_colors.dart` — defines `AppColors` with `dark` and `light` static `ColorScheme`-compatible tokens.
- `lib/core/theme/app_theme.dart` — `appTheme(Brightness)` returns a `ThemeData` wired to the color tokens, Inter text theme, component defaults (card shape, input decoration, button themes, nav bar theme, FAB theme).
- `lib/core/theme/app_spacing.dart` — spacing + radius constants.
- `lib/core/theme/app_typography.dart` — text styles with tabular figures applied to numeric styles.
- `lib/core/widgets/` — shared components (`ArbitronCard`, `ArbitronField`, `StatusChip`, `ScoreChip`, `AiAnalysisBlock`, `SegmentedControl`, `EmptyState`, `KillSwitchFab`, `OpportunityCard`).

Features consume these widgets and tokens exclusively. No feature file imports `Colors` or defines its own `TextStyle`.

---

## 10. Accessibility

- Minimum tap target: 44dp (enforced in button/input themes).
- Text contrast: all `textPrimary` on `background`/`surface` pairs exceed 7:1 (AAA). `textSecondary` exceeds 4.5:1 (AA). `textMuted` is used only for non-essential metadata and stays above 3:1.
- Color is never the sole carrier of meaning: profit/loss values are also sign-prefixed (`+$42.18` / `−$42.18`), status chips include a text label.
- Respect `MediaQuery.textScaler` — all text uses token type styles, never hardcoded sizes.
- The Kill Switch is reachable from every screen and operable with one hand.

---

## 11. Icon Usage Cheat Sheet

| Concept | Icon |
|---------|------|
| Dashboard | `Icons.show_chart` |
| Opportunities | `Icons.auto_awesome` |
| Strategies | `Icons.tune` |
| History | `Icons.history` |
| Settings | `Icons.settings` |
| Execute | `Icons.bolt` |
| Pause / Kill | `Icons.pause_circle` |
| Resume | `Icons.play_circle` |
| Manual mode | `Icons.pan_tool` |
| Semi-auto | `Icons.timer` |
| Autonomous | `Icons.auto_mode` |
| Connect exchange | `Icons.link` |
| Disconnect | `Icons.link_off` |
| Filter | `Icons.filter_list` |
| Sort | `Icons.sort` |
| AI / analysis | `Icons.smart_toy` |
| Profit up | `Icons.trending_up` (colored `success`) |
| Profit down | `Icons.trending_down` (colored `danger`) |
| Slippage warning | `Icons.warning_amber` (colored `warning`) |
| Audit / log | `Icons.receipt_long` |
| Wallet | `Icons.account_balance_wallet` |
| Risk / shield | `Icons.shield` |
| Arrow (buy→sell) | `Icons.arrow_forward` (inline, `textMuted`) |

---

## 12. Layout Examples

### 12.1 Dashboard (top of scroll)

```
┌─────────────────────────────────────────────┐
│  Dashboard                         [filter] │
├─────────────────────────────────────────────┤
│  [ticker strip: BTC +0.42% │ ETH +0.18% … ] │
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐   │
│  │  Portfolio                          │   │
│  │  $12,480.00                         │   │
│  │  +$182.40 today  ▲ 1.48%            │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  Active Strategies                          │
│  ┌─────────────────────────────────────┐   │
│  │  Simple Cross-Exchange    [Active]  │   │
│  │  Manual · 14 trades · +$210.40      │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  AI Activity                                │
│  ┌─────────────────────────────────────┐   │
│  │ ▌ AI · 2m ago                       │   │
│  │ ▌ Scored BTC/USDT at 87/100…        │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

### 12.2 Opportunity Detail

```
┌─────────────────────────────────────────────┐
│  ← Opportunities                            │
├─────────────────────────────────────────────┤
│  BTC/USDT                                   │
│  Binance ──→ Kraken                         │
│                                             │
│  Net profit      +$42.18  (+0.42%)          │
│  Spread          0.52%                      │
│  Est. fees       $8.40                      │
│  Est. slippage   $1.20                      │
│  Confidence      87/100                     │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │▌ AI                                  │   │
│  │▌ Spread is within the 30-day median  │   │
│  │▌ range for this pair. Kraken liquidity│   │
│  │▌ is healthy at this size…            │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  [ Reject ]              [   Execute   ]     │
└─────────────────────────────────────────────┘
```

---

*This document is the source of truth. When a design decision is not covered here, defer to the principles in §1. Update this document when new patterns are introduced — never let the code drift from it.*