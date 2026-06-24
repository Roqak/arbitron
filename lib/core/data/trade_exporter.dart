import '../domain/trade.dart';
import '../domain/exchange.dart';
import '../utils/fmt.dart';

/// Exports trade history to CSV or JSON. See PRD §8.5.
class TradeExporter {
  TradeExporter._();

  /// Generates a CSV string of all trades.
  static String toCsv(List<TradeRecord> trades) {
    final header = [
      'id', 'executed_at', 'strategy', 'strategy_type', 'pair',
      'buy_exchange', 'sell_exchange', 'size_usd', 'entry_price', 'exit_price',
      'gross_pnl', 'net_pnl', 'fees_usd', 'slippage_usd', 'mode', 'outcome',
    ];
    final rows = trades.map((t) {
      return [
        t.id,
        t.executedAt.toIso8601String(),
        t.strategyName,
        t.strategyType.name,
        t.pair,
        ExchangeCatalog.byId(t.buyExchangeId).name,
        ExchangeCatalog.byId(t.sellExchangeId).name,
        t.sizeUsd.toStringAsFixed(2),
        t.entryPrice.toStringAsFixed(6),
        t.exitPrice.toStringAsFixed(6),
        t.grossPnl.toStringAsFixed(2),
        t.netPnl.toStringAsFixed(2),
        t.feesUsd.toStringAsFixed(2),
        t.slippageUsd.toStringAsFixed(2),
        t.mode.name,
        t.profit ? 'profit' : 'loss',
      ].map((f) => '"${f.replaceAll('"', '""')}"').join(',');
    }).join('\n');
    return '${header.join(',')}\n$rows';
  }

  /// Generates a JSON string of all trades.
  static String toJson(List<TradeRecord> trades) {
    final list = trades.map((t) => {
      'id': t.id,
      'executed_at': t.executedAt.toIso8601String(),
      'strategy': {'id': t.strategyId, 'name': t.strategyName, 'type': t.strategyType.name},
      'pair': t.pair,
      'buy_exchange': ExchangeCatalog.byId(t.buyExchangeId).name,
      'sell_exchange': ExchangeCatalog.byId(t.sellExchangeId).name,
      'size_usd': t.sizeUsd,
      'entry_price': t.entryPrice,
      'exit_price': t.exitPrice,
      'gross_pnl': t.grossPnl,
      'net_pnl': t.netPnl,
      'fees_usd': t.feesUsd,
      'slippage_usd': t.slippageUsd,
      'mode': t.mode.name,
      'outcome': t.profit ? 'profit' : 'loss',
      'debrief': t.debrief,
    }).toList();
    return _prettyJson(list);
  }

  static String _prettyJson(List<Map<String, dynamic>> data) {
    // Manual pretty-print to avoid extra dependencies.
    final buffer = StringBuffer();
    buffer.write('[\n');
    for (int i = 0; i < data.length; i++) {
      buffer.write('  ');
      buffer.write(_mapToString(data[i], indent: '  '));
      if (i < data.length - 1) buffer.write(',');
      buffer.write('\n');
    }
    buffer.write(']');
    return buffer.toString();
  }

  static String _mapToString(Map<String, dynamic> m, {required String indent}) {
    final entries = m.entries.toList();
    final buffer = StringBuffer('{');
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      buffer.write('"${e.key}": ');
      buffer.write(_valueToString(e.value, indent: '$indent  '));
      if (i < entries.length - 1) buffer.write(', ');
    }
    buffer.write('}');
    return buffer.toString();
  }

  static String _valueToString(dynamic v, {required String indent}) {
    if (v is String) return '"${v.replaceAll('"', '\\"')}"';
    if (v is num) return v.toString();
    if (v is bool) return v.toString();
    if (v is Map) return _mapToString(v.cast<String, dynamic>(), indent: indent);
    if (v is List) return '[${v.map((e) => _valueToString(e, indent: indent)).join(', ')}]';
    return '"$v"';
  }

  /// Suggested filename for an export.
  static String filename(ExportFormat fmt) {
    final date = Fmt.date(DateTime.now()).replaceAll(' ', '_');
    return 'arbitron_trades_$date.${fmt.extension}';
  }
}

enum ExportFormat { csv, json }

extension ExportFormatX on ExportFormat {
  String get extension => this == ExportFormat.csv ? 'csv' : 'json';
  String get label => this == ExportFormat.csv ? 'CSV' : 'JSON';
  String get mimeType => this == ExportFormat.csv ? 'text/csv' : 'application/json';
}