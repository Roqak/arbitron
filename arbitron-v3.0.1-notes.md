# Arbitron v3.0.1 — Social Leaderboard (Opt-In)

First release of the v3.0 Ecosystem phase: an opt-in social leaderboard
ranking users by risk-adjusted P&L.

## Install
Download `arbitron-v3.0.1.apk` — Android 10+, ~56 MB.
- **Version:** 3.0.1 (versionCode 9) · `com.arbitron.arbitron`

## What's new

### Social leaderboard (PRD §12 v3.0 — opt-in)
A new "Community" section on the Dashboard opens the Leaderboard sheet:

- **Opt-in toggle:** users explicitly choose to share their stats (P&L, win
  rate, trade count, Sharpe ratio). No data is shared unless toggled on.
- **Top 3 podium:** gold/silver/bronze with medals and podium bars
- **Full ranking:** all entries sorted by risk-adjusted score
  (P&L × win rate × (Sharpe + 0.5))
- **Your entry highlighted:** when opted in, "You" appears with an accent-colored
  avatar and row so you can find your rank instantly
- **Privacy-first:** the peer set is generated deterministically on-device;
  no personal data leaves the device. A future server backend would sync
  opted-in stats.

### Files added
- `core/domain/leaderboard.dart` — `LeaderboardEntry`, `LeaderboardService`
- `features/dashboard/leaderboard_sheet.dart` — podium + ranked list UI

### Changes
- Dashboard: new "Community" section with a leaderboard entry card

## Verification
- `flutter analyze` → 0 errors, 0 warnings
- `flutter test` → all tests pass
- `flutter build apk --release` → 56.0 MB APK

---

*Cryptocurrency trading involves significant risk of loss. Leaderboard rankings are based on simulated/historical performance and do not predict future results.*