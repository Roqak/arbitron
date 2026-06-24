# Arbitron v3.0.4 — Tax Export Integrations

Tax-ready exports of realized gains/losses, including a US Form 8949 format
and a generic taxable-events CSV, plus a tax-year summary.

## Install
Download `arbitron-v3.0.4.apk` — Android 10+, ~57 MB.
- **Version:** 3.0.4 (versionCode 12) · `com.arbitron.arbitron`

## What's new

### Tax export (PRD §12 v3.0 — Tax export integrations)
A new "Tax Export" section in Settings shows:

- **Tax-year summary:** total trades, total gains, total losses, net realized,
  short-term vs long-term breakdown, total fees
- **Form 8949 (US):** CSV in the US Schedule D attachment format —
  Description, Date Acquired, Date Sold, Proceeds, Cost Basis, Gain/Loss, Term
- **Taxable Events (Generic):** jurisdiction-agnostic CSV with full trade
  details (pair, strategy, exchanges, size, proceeds, cost basis, realized
  gain, fees, slippage, outcome)

Both formats can be filtered by tax year and exported for use with tax
software or accountant preparation.

### Files added
- `core/data/tax_exporter.dart` — `TaxExporter` (Form 8949 + generic CSV),
  `TaxSummary`, `TaxFormat`

### Changes
- Settings: new "Tax Export" section with summary breakdown and two export buttons

## Verification
- `flutter analyze` → 0 errors, 0 warnings
- `flutter test` → all tests pass
- `flutter build apk --release` → 56.6 MB APK

---

*Arbitron does not provide tax advice. Export formats are provided for convenience; consult a tax professional for reporting requirements in your jurisdiction.*