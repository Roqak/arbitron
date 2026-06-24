# PRODUCT.md

## Register

**Product.** Arbitron is a mobile app (Flutter, Android/iOS). Design serves the product: it must make trading data legible, decisions fast, and risk visible. The UI is the cockpit, not the brand.

## Users

Three personas, one app:

1. **The Active Trader** — experienced retail crypto trader, monitors 10+ exchanges simultaneously, wants to spot and execute arbitrage faster than competitors. Uses the app on a phone, often alongside a desktop terminal, in mixed lighting. Wants real-time alerts, clear spreads, one-tap execution. Values speed and density.

2. **The Algo Delegator** — technical user comfortable with APIs and risk parameters. Wants to let the AI run approved strategies 24/7 without babysitting. Checks the app periodically, sometimes at 2am in a dark room, to verify performance and adjust limits. Wants strategy configurators, risk caps, detailed audit logs. Values control and transparency.

3. **The DeFi Explorer** — web3-native, interacts with DEXs and on-chain protocols. Exploits cross-chain and DEX-CEX price gaps using wallet connections. Cares about gas estimation, bridge latency, and signing flows. Values precision and on-chain awareness.

## Product Purpose

Aggregate real-time prices across 20+ exchanges, detect arbitrage opportunities net of all costs (fees, slippage, bridge time), use an LLM to analyze and score each opportunity, and optionally execute trades within user-defined risk limits. The app gives traders an edge through speed, data aggregation, and AI-driven analysis, while maintaining full transparency about risks and costs.

## Brand Personality

- **Terminal-native.** Not a consumer fintech app with pastel charts and friendly mascots. This is a professional instrument. The aesthetic borrows from Bloomberg terminals, trading desks, and monospace data displays: dense, precise, high-contrast, no decoration that doesn't carry meaning.
- **Calm competence.** Despite the density, the app never feels frantic. Information is structured, motion is purposeful, color carries semantic weight. The user feels like a pilot with a clean cockpit, not a gambler in a casino.
- **Numbers are the hero.** Every monetary value, spread, and score is the most important thing on screen. Typography exists to serve numbers. Tabular figures, right alignment, sign-prefixed values. The app reads like a live spreadsheet that happens to be beautiful.
- **Honest about risk.** No "guaranteed profit" framing. Loss is as visible as gain. The Kill Switch is the most prominent control in the app. AI output is clearly labelled as analysis, not advice.

## Anti-References

What Arbitron is NOT:

- **Not Robinhood.** No confetti, no celebration animations, no gamification of risk. Trading is serious; the UI reflects that.
- **Not a generic SaaS dashboard.** No rounded cards floating on a pastel gradient, no "Welcome back!" headers, no stock-photo illustrations. This is a tool, not a landing page.
- **Not crypto-bro neon.** No animated flame icons, no rocket emojis, no "TO THE MOON" copy. The crypto aesthetic cliché is explicitly rejected. Professional, not tribal.
- **Not Material Design default.** Flutter ships with Material 3 defaults. Arbitron overrides them comprehensively. The app should not look like a Material template.
- **Not dark-mode-by-default for aesthetic reasons.** Dark mode is chosen because traders work in dim environments and dark surfaces reduce glare on dense numeric data. The choice is functional, not decorative.

## Strategic Design Principles

1. **Density without clutter.** Pack information tightly but use whitespace as a structural element, not padding. Every pixel earns its place. Gaps separate meaning; they don't fill space.

2. **Monospace where numbers live.** Inter for prose and labels; a monospace face for all numeric data (prices, P&L, spreads, timestamps, scores). This creates an immediate visual distinction between "reading" and "scanning" and eliminates digit jitter.

3. **One accent, electric.** A single high-chroma accent (not the current mint green — something with more energy) carries the brand and signals positive/active state. It appears sparingly: CTAs, active states, positive P&L. Everything else lives on a tinted neutral ramp.

4. **Color is semantic, never decorative.** Green = profit. Red = loss. Amber = caution. Blue = AI/system. No gradient backgrounds, no colored cards for visual variety. A colored element means something.

5. **Motion is signal.** No bouncing, no parallax, no decorative animation. The only motion is: state transitions (live/stale), value changes (price ticks), and navigation. Every animation tells the user something changed.

6. **The Kill Switch is sacred.** It is the most visible, most accessible, most reliable control in the app. It should feel like a physical emergency stop button: impossible to miss, satisfying to press, unambiguous in effect.

7. **Hierarchy through type, not cards.** The current design wraps everything in cards. The redesign uses typographic hierarchy, hairline dividers, and surface color shifts to organize information. Cards are used only when a discrete boundary genuinely helps comprehension.

## Accessibility

- Minimum 44dp tap targets, 48dp for primary actions.
- All text contrast exceeds WCAG AA (4.5:1 for body, 3:1 for large text).
- Color is never the sole carrier of meaning: sign-prefixed values, text labels on status indicators, icon + text on mode chips.
- Respect system text scaling; all text uses semantic type styles.
- The Kill Switch is operable with one hand from any screen, within thumb reach.
- Screen reader labels on all interactive elements, especially numeric values (read as "plus forty-two dollars and eighteen cents", not "+42.18").

## Tone of Voice

- **Concise and technical.** No marketing copy in the UI. Labels are nouns, not sentences. "Net profit", not "Your estimated net profit". "Execute", not "Place your trade now!".
- **Precise about risk.** "AI analysis, not financial advice" is always present on LLM output. Losses are shown with the same prominence as gains.
- **No exclamation marks.** Ever. The app communicates urgency through color and placement, not punctuation.
- **No anthropomorphism of the AI.** It's "AI analysis", not "Your AI buddy thinks...". The LLM is a tool, not a character.