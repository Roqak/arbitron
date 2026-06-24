# Arbitron Design System v2

**Terminal-native. In control.**
**Last updated:** June 24, 2026

A radical redesign of Arbitron's visual language. The app reads like a
professional trading terminal reimagined for mobile: dense but legible,
monospace-forward, one electric accent, zero decoration that doesn't carry
meaning. See PRODUCT.md for strategic context.

---

## 1. Principles

1. **Numbers are the hero.** Every price, spread, and score is the most important thing on screen. JetBrains Mono with tabular figures for all numeric data. Inter for prose and labels. The visual distinction between "reading" and "scanning numbers" is immediate.

2. **Density without clutter.** Pack information tightly but use whitespace as structure, not padding. Every pixel earns its place.

3. **Color is semantic, never decorative.** Cyan = profit/active. Coral = loss/danger. Amber = caution. Violet = AI/system. No gradients, no colored cards for visual variety. A colored element means something.

4. **Hierarchy through type, not cards.** Cards are used only for discrete list items (opportunities, trades). Sections are organized by typographic hierarchy and hairline dividers, not card containers.

5. **The Kill Switch is sacred.** It is the most visible, most accessible control in the app. A wide pill bar with "EMERGENCY STOP" label, impossible to miss, always above the bottom nav when autonomous is active.

6. **Motion is signal.** No bouncing, no parallax, no decorative animation. The only motion is state transitions, value changes, and navigation.

---

## 2. Color

### Dark theme (default)

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#070A0F` | App canvas, deepest layer |
| `surface` | `#0D1117` | Panels, list items |
| `surfaceRaised` | `#151B24` | Inputs, nested surfaces |
| `surfaceOverlay` | `#1B2330` | Sheets, modals |
| `borderSubtle` | `#1E2632` | Hairline dividers |
| `borderStrong` | `#2A3645` | Focused inputs |
| `textPrimary` | `#E6EDF3` | Primary text |
| `textSecondary` | `#8B95A5` | Labels, secondary copy |
| `textMuted` | `#5C6470` | Timestamps, placeholders |
| `accent` | `#00E5CC` | Electric cyan, profit, active, CTAs |
| `accentDim` | `#0A2926` | Accent backgrounds |
| `danger` | `#FF5C7A` | Loss, error, kill switch |
| `dangerDim` | `#2A0E14` | Danger backgrounds |
| `warning` | `#FFB547` | Caution, semi-auto countdown |
| `warningDim` | `#2A2010` | Warning backgrounds |
| `ai` | `#8B7BFF` | Violet, AI/system content |
| `aiDim` | `#1A1628` | AI backgrounds |

### Light theme

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#F2F4F8` | App canvas |
| `surface` | `#FFFFFF` | Panels |
| `surfaceRaised` | `#EBEDF2` | Inputs |
| `surfaceOverlay` | `#FFFFFF` | Sheets (with shadow) |
| `borderSubtle` | `#D8DCE3` | Dividers |
| `borderStrong` | `#B8BFCA` | Focused inputs |
| `textPrimary` | `#0E1116` | Primary text |
| `textSecondary` | `#4A5260` | Secondary copy |
| `textMuted` | `#8A909C` | Timestamps |
| `accent` | `#00B89A` | Cyan (darkened for light) |
| `danger` | `#D11D48` | Loss |
| `warning` | `#B86E00` | Caution |
| `ai` | `#6B4FDB` | AI/system |

---

## 3. Typography

**Dual typeface:**
- **Inter** (Google Fonts) — prose, labels, navigation, UI chrome
- **JetBrains Mono** (Google Fonts) — ALL numeric data: prices, P&L, spreads, scores, timestamps, percentages, counts, labels in caps

### Type scale

| Context | Face | Size / Weight |
|---------|------|---------------|
| Portfolio value | Mono | 32 / 700 |
| Screen title | Mono | 16 / 700 (caps) |
| Pair name (card) | Mono | 15 / 600 |
| Net profit (card) | Mono | 15 / 600 (sign-colored) |
| P&L percentage | Mono | 11 / 600 |
| Exchange name | Mono | 11 / 400 |
| Timestamps | Mono | 11 / 400 |
| Section labels | Mono | 10-11 / 600 (caps) |
| Field labels | Mono | 10 / 600 (caps) |
| Strategy name | Inter | 14 / 600 |
| Body text | Inter | 14 / 400 |
| Button text | Inter | 14 / 600 |
| Helper text | Inter | 12 / 400 |

All monospace text uses tabular figures (`FontFeature.tabularFigures()`).

---

## 4. Spacing & Radius

### Spacing (4pt grid, tighter than v1)

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4 | Chip internals, icon-to-text |
| `sm` | 8 | Interior card gaps, row vertical |
| `md` | 12 | Form fields, card contents |
| `lg` | 16 | Panel padding |
| `xl` | 20 | Screen horizontal margin |
| `xxl` | 28 | Section breaks |
| `xxxl` | 40 | Screen top/bottom padding |

### Radius

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4 | Chips |
| `sm` | 8 | Panels, inputs, buttons |
| `md` | 10 | Large panels |
| `lg` | 14 | Dialogs |
| `xl` | 20 | Sheet tops |
| `pill` | 999 | Segmented controls, FAB |

---

## 5. Components

### ArbitronPanel
Bordered surface for discrete list items. `surface` bg, `borderSubtle` 1px, `sm` radius, `lg` padding. NOT used for sections or layout — only for bounded list entries.

### MonoText
The atomic numeric display. JetBrains Mono, tabular figures, configurable size/weight/color. Used for every number in the app.

### DataKV
Key-value row: Inter label left, Mono value right. The atomic unit of data display in detail sheets.

### SectionLabel
Mono caps text with optional trailing widget. Separates sections without card containers.

### Hairline
1px `borderSubtle` divider. The structural element between sections.

### ScoreBar
3-segment horizontal bar + numeric score. Muted (0-40), amber (41-70), cyan (71-100). Replaces the old chip — more scannable as a gauge.

### StatusChip
Compact mono label on dim background. 4px radius, 8px horizontal padding.

### OpportunityCard
Pair name (mono, 15/600) left, profit (mono, 15/600, sign-colored) right. Exchange flow beneath. Score bar + strategy + time in footer.

### AiAnalysisBlock
Full-width, violet-tinted background, no left-border-stripe. Header: icon + "AI ANALYSIS" in mono caps + optional title + relative time. Body in Inter. "NOT FINANCIAL ADVICE" footer in mono caps.

### KillSwitchBar
Wide pill bar above bottom nav. Danger fill, "EMERGENCY STOP" in mono caps with stop icon. Pulsing shadow. Only visible when autonomous is active.

### Bottom Navigation
5 tabs with mono caps labels (DASH, OPPS, STRAT, HIST, SETUP). Active: accent icon + label + 2px accent top-border. Inactive: muted icon only. 56dp + bottom inset.

---

## 6. Motion

| Transition | Duration | Curve |
|-----------|----------|-------|
| Tab switch | 180ms | easeOutQuart |
| Sheet present | 280ms | easeOutQuart |
| Sheet dismiss | 200ms | easeInQuart |
| Kill switch pulse | 1400ms loop | easeInOut |
| Segmented control | 180ms | easeOutQuart |
| Price flash | 200ms | opacity pulse (cyan up, coral down) |

---

## 7. What Changed from v1

- **Palette:** Mint green replaced with electric cyan `#00E5CC`. New violet `#8B7BFF` for AI content (was blue).
- **Typography:** Dual typeface. JetBrains Mono for all numbers. Inter for prose. v1 used Inter only.
- **Cards:** Radically reduced. v1 wrapped everything in cards. v2 uses typographic hierarchy + hairlines for sections.
- **Score:** Chip replaced with ScoreBar (3-segment gauge).
- **Kill Switch:** FAB replaced with wide pill bar above bottom nav.
- **Labels:** All section/field labels are now mono caps (was Inter title case).
- **Nav labels:** Mono caps abbreviations (DASH, OPPS, STRAT, HIST, SETUP).
- **Spacing:** Tighter across the board (20dp screen margin vs 24dp, 28dp sections vs 32dp).
- **AI block:** Left-border-stripe removed (banned). Full background tint instead.

---

*This document is the source of truth. Update when patterns evolve.*