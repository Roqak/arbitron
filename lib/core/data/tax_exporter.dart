import '../domain/trade.dart';
import '../domain/exchange.dart';

/// Generates tax-ready exports of trade history. See PRD §12 (v3.0 — Tax
/// export integrations) and §2.2 (tax reporting was a non-goal for v1 but
/// is in the v3.0+ scope).
///
/// Produces:
/// - A Form 8949-style CSV (US capital gains format) for Schedule D attachment
/// - A generic taxable-events CSV for non-US jurisdictions
/// - A summary of realized gains/losses by tax year
class TaxExporter {
  TaxExporter._();

  /// Generates a Form 8949 (US) style CSV.
  /// Columns: Description, Date Acquired, Date Sold, Proceeds, Cost Basis,
  /// Gain/Loss, Term (short/long).
  static String form8949Csv(List<TradeRecord> trades, {int? taxYear}) {
    final filtered = _filterByYear(trades, taxYear);
    final header = [
      'Description', 'Date Acquired', 'Date Sold', 'Proceeds', 'Cost Basis',
      'Gain or Loss', 'Term',
    ];
    final rows = filtered.map((t) {
      final proceeds = t.sizeUsd + t.netPnl; // selling price
      final costBasis = t.sizeUsd; // buying price
      final gainLoss = t.netPnl;
      final holdingPeriod = DateTime.now().difference(t.executedAt);
      final term = holdingPeriod.inDays > 365 ? 'Long-term' : 'Short-term';
      final desc = '${t.pair} (${t.strategyName})';
      return [
        desc,
        t.executedAt.toIso8601String().split('T').first,
        t.executedAt.toIso8601String().split('T').first, // same-day for arb
        proceeds.toStringAsFixed(2),
        costBasis.toStringAsFixed(2),
        gainLoss.toStringAsFixed(2),
        term,
      ].map((f) => '"${f.replaceAll('"', '""')}"').join(',');
    }).join('\n');
    return '${header.join(',')}\n$rows';
  }

  /// Generates a generic taxable events CSV (jurisdiction-agnostic).
  static String taxableEventsCsv(List<TradeRecord> trades, {int? taxYear}) {
    final filtered = _filterByYear(trades, taxYear);
    final header = [
      'date', 'type', 'pair', 'strategy', 'buy_exchange', 'sell_exchange',
      'size_usd', 'proceeds_usd', 'cost_basis_usd', 'realized_gain_usd',
      'fees_usd', 'slippage_usd', 'outcome',
    ];
    final rows = filtered.map((t) {
      final proceeds = t.sizeUsd + t.netPnl;
      final costBasis = t.sizeUsd;
      return [
        t.executedAt.toIso8601String(),
        'arbitrage',
        t.pair,
        t.strategyName,
        ExchangeCatalog.byId(t.buyExchangeId).name,
        ExchangeCatalog.byId(t.sellExchangeId).name,
        t.sizeUsd.toStringAsFixed(2),
        proceeds.toStringAsFixed(2),
        costBasis.toStringAsFixed(2),
        t.netPnl.toStringAsFixed(2),
        t.feesUsd.toStringAsFixed(2),
        t.slippageUsd.toStringAsFixed(2),
        t.profit ? 'gain' : 'loss',
      ].map((f) => '"${f.replaceAll('"', '""')}"').join(',');
    }).join('\n');
    return '${header.join(',')}\n$rows';
  }

  /// Generates a tax summary: realized gains/losses grouped by year and term.
  static TaxSummary summary(List<TradeRecord> trades, {int? taxYear}) {
    final filtered = _filterByYear(trades, taxYear);
    final gains = filtered.where((t) => t.profit).fold(0.0, (s, t) => s + t.netPnl);
    final losses = filtered.where((t) => !t.profit).fold(0.0, (s, t) => s + t.netPnl);
    final net = gains + losses;
    final shortTerm = filtered.where((t) => DateTime.now().difference(t.executedAt).inDays <= 365).fold(0.0, (s, t) => s + t.netPnl);
    final longTerm = filtered.where((t) => DateTime.now().difference(t.executedAt).inDays > 365).fold(0.0, (s, t) => s + t.netPnl);
    final totalFees = filtered.fold(0.0, (s, t) => s + t.feesUsd);

    return TaxSummary(
      taxYear: taxYear ?? DateTime.now().year,
      totalTrades: filtered.length,
      totalGains: gains,
      totalLosses: losses,
      netRealized: net,
      shortTermGains: shortTerm,
      longTermGains: longTerm,
      totalFees: totalFees,
    );
  }

  static List<TradeRecord> _filterByYear(List<TradeRecord> trades, int? taxYear) {
    if (taxYear == null) return trades;
    return trades.where((t) => t.executedAt.year == taxYear).toList();
  }

  static String filename(TaxFormat fmt, {int? year}) {
    final y = year ?? DateTime.now().year;
    return 'arbitron_tax_$y.${fmt.extension}';
  }
}

enum TaxFormat { form8949, taxableEvents }

extension TaxFormatX on TaxFormat {
  String get extension => 'csv';
  String get label => this == TaxFormat.form8949 ? 'Form 8949 (US)' : 'Taxable Events (Generic)';
  String get description => this == TaxFormat.form8949
      ? 'US Schedule D attachment format'
      : 'Jurisdiction-agnostic taxable events log';
}

/// Summary of realized gains/losses for a tax year.
class TaxSummary {
  final int taxYear;
  final int totalTrades;
  final double totalGains;
  final double totalLosses;
  final double netRealized;
  final double shortTermGains;
  final double longTermGains;
  final double totalFees;

  const TaxSummary({
    required this.taxYear,
    required this.totalTrades,
    required this.totalGains,
    required this.totalLosses,
    required this.netRealized,
    required this.shortTermGains,
    required this.longTermGains,
    required this.totalFees,
  });

  bool get isNetGain => netRealized >= 0;
}