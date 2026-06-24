import 'package:equatable/equatable.dart';

/// A live ticker quote for a trading pair on a specific exchange.
/// See PRD §10.2 — price aggregation via WebSocket.
class Ticker extends Equatable {
  final String exchangeId;
  final String pair; // normalized "BTC/USDT"
  final double bid;
  final double ask;
  final double last;
  final DateTime updatedAt;

  const Ticker({
    required this.exchangeId,
    required this.pair,
    required this.bid,
    required this.ask,
    required this.last,
    required this.updatedAt,
  });

  /// Mid price for spread calculations.
  double get mid => (bid + ask) / 2;

  /// Effective spread on this exchange (ask - bid) as a percentage of mid.
  double get spreadPct => mid == 0 ? 0 : ((ask - bid) / mid) * 100;

  /// Whether the quote is fresh (< 10s old). Stale quotes are excluded from
  /// autonomous execution per PRD §11.1.
  bool get isFresh {
    return DateTime.now().difference(updatedAt).inSeconds < 10;
  }

  Ticker copyWith({double? bid, double? ask, double? last, DateTime? updatedAt}) {
    return Ticker(
      exchangeId: exchangeId,
      pair: pair,
      bid: bid ?? this.bid,
      ask: ask ?? this.ask,
      last: last ?? this.last,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [exchangeId, pair, bid, ask, last, updatedAt];
}

/// Aggregated view of a single pair across all exchanges — the input to the
/// opportunity scanner.
class PairQuotes extends Equatable {
  final String pair;
  final List<Ticker> tickers;

  const PairQuotes({required this.pair, required this.tickers});

  /// Best (lowest) ask across all fresh quotes — the cheapest buy price.
  Ticker? get bestAsk {
    final fresh = tickers.where((t) => t.isFresh).toList();
    fresh.sort((a, b) => a.ask.compareTo(b.ask));
    return fresh.isEmpty ? null : fresh.first;
  }

  /// Best (highest) bid across all fresh quotes — the best sell price.
  Ticker? get bestBid {
    final fresh = tickers.where((t) => t.isFresh).toList();
    fresh.sort((a, b) => b.bid.compareTo(a.bid));
    return fresh.isEmpty ? null : fresh.first;
  }

  @override
  List<Object?> get props => [pair, tickers];
}