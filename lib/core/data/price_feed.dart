import 'dart:async';
import '../domain/ticker.dart';

/// Status of a single exchange feed connection.
enum FeedStatus { connecting, connected, disconnected, error }

/// Base class for an exchange WebSocket price feed. Each implementation
/// subscribes to ticker streams for a set of pairs and emits [Ticker] updates.
/// See PRD §10.1 — WebSocket via web_socket_channel; 500ms polling fallback.
abstract class PriceFeed {
  final String exchangeId;
  final Set<String> pairs;

  PriceFeed({required this.exchangeId, required this.pairs});

  final _controller = StreamController<Ticker>.broadcast();
  final _statusController = StreamController<FeedStatus>.broadcast();

  /// Stream of ticker updates from this exchange.
  Stream<Ticker> get tickers => _controller.stream;

  /// Stream of connection-status changes.
  Stream<FeedStatus> get status => _statusController.stream;

  FeedStatus _status = FeedStatus.disconnected;
  FeedStatus get currentStatus => _status;

  /// The WebSocket URL to connect to.
  String get url;

  /// Subscribes on the given channel. Implementations parse frames and emit
  /// [Ticker]s via [emit].
  void subscribe(dynamic channel);

  /// Parses a single message frame into 0..n [Ticker]s.
  List<Ticker> parseFrame(dynamic message);

  /// Builds the subscription payload to send after connect (optional).
  Object? buildSubscribePayload() => null;

  void emit(Ticker t) {
    if (!_controller.isClosed) _controller.add(t);
  }

  void setStatus(FeedStatus s) {
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }

  void dispose() {
    _controller.close();
    _statusController.close();
  }

  /// Normalizes an exchange-specific pair symbol (e.g. "btcusdt", "BTC-USDT",
  /// "XBT/USD") to the canonical "BTC/USDT" form used across the app.
  static String normalizePair(String raw) {
    var p = raw.toUpperCase();
    // Strip common separators.
    p = p.replaceAll('-', '/').replaceAll('_', '/');
    // Handle Binance-style no-separator (BTCUSDT) for known quotes.
    for (final quote in const ['USDT', 'USDC', 'USD', 'BTC', 'ETH', 'BNB']) {
      if (p.endsWith(quote) && p != quote) {
        final base = p.substring(0, p.length - quote.length);
        if (base.isNotEmpty) return '$base/$quote';
      }
    }
    if (!p.contains('/')) return p;
    return p;
  }
}