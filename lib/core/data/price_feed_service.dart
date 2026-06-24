import 'dart:async';
import 'dart:collection';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../domain/ticker.dart';
import '../domain/exchange.dart';
import 'price_feed.dart';
import 'exchange_feeds.dart';

/// Aggregates live ticker feeds across all enabled CEXs. Maintains the latest
/// quote per (exchange, pair) and emits snapshots when prices update.
/// See PRD §10.2 — edge worker pattern adapted to on-device WebSocket fan-in.
class PriceFeedService {
  PriceFeedService();

  final Map<String, PriceFeed> _feeds = {};
  final Map<String, WebSocketChannel> _channels = {};
  // _quotes keyed by "$exchangeId|$pair" -> Ticker
  final Map<String, Ticker> _quotes = {};
  final Map<String, FeedStatus> _feedStatus = {};

  final _snapshotController = StreamController<PriceSnapshot>.broadcast();
  final _statusController = StreamController<Map<String, FeedStatus>>.broadcast();

  /// Emits a snapshot of all current quotes whenever any feed updates.
  Stream<PriceSnapshot> get snapshots => _snapshotController.stream;

  /// Emits the per-exchange connection status map on change.
  Stream<Map<String, FeedStatus>> get statusChanges => _statusController.stream;

  /// Current per-exchange status map (exchangeId -> status).
  Map<String, FeedStatus> get currentStatus => Map.unmodifiable(_feedStatus);

  /// Current snapshot of all quotes.
  PriceSnapshot get currentSnapshot => PriceSnapshot(Map.unmodifiable(_quotes));

  Timer? _snapshotTimer;
  bool _started = false;

  /// Starts feeds for the given enabled exchanges and pairs. Reconnecting with
  /// a different set tears down the old connections first.
  void start({
    required List<String> enabledExchangeIds,
    required List<String> pairs,
  }) {
    stop();
    _started = true;
    _feedStatus.clear();

    for (final id in enabledExchangeIds) {
      final feed = _buildFeed(id, pairs.toSet());
      if (feed == null) continue;
      _feeds[id] = feed;
      _feedStatus[id] = FeedStatus.connecting;
      _connect(feed);
    }

    // Throttle snapshot emission to avoid flooding on high-frequency updates.
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_quotes.isNotEmpty) {
        _snapshotController.add(currentSnapshot);
      }
    });

    _statusController.add(Map.unmodifiable(_feedStatus));
  }

  /// Stops all feeds and clears quotes.
  void stop() {
    _started = false;
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
    for (final entry in _channels.entries) {
      try {
        entry.value.sink.close();
      } catch (_) {}
    }
    _channels.clear();
    for (final feed in _feeds.values) {
      feed.dispose();
    }
    _feeds.clear();
    _quotes.clear();
    _feedStatus.clear();
  }

  void _connect(PriceFeed feed) {
    try {
      final channel = WebSocketChannel.connect(Uri.parse(feed.url));
      _channels[feed.exchangeId] = channel;

      feed.setStatus(FeedStatus.connecting);
      _feedStatus[feed.exchangeId] = FeedStatus.connecting;
      _statusController.add(Map.unmodifiable(_feedStatus));

      // Send subscription payload after connect (some exchanges require it).
      feed.subscribe(channel);

      channel.stream.listen(
        (message) {
          if (!_started) return;
          if (feed.currentStatus != FeedStatus.connected) {
            feed.setStatus(FeedStatus.connected);
            _feedStatus[feed.exchangeId] = FeedStatus.connected;
            _statusController.add(Map.unmodifiable(_feedStatus));
          }
          final tickers = feed.parseFrame(message);
          for (final t in tickers) {
            final key = '${t.exchangeId}|${t.pair}';
            _quotes[key] = t;
            feed.emit(t);
          }
        },
        onError: (Object e) {
          feed.setStatus(FeedStatus.error);
          _feedStatus[feed.exchangeId] = FeedStatus.error;
          _statusController.add(Map.unmodifiable(_feedStatus));
        },
        onDone: () {
          if (_started && feed.currentStatus != FeedStatus.error) {
            feed.setStatus(FeedStatus.disconnected);
            _feedStatus[feed.exchangeId] = FeedStatus.disconnected;
            _statusController.add(Map.unmodifiable(_feedStatus));
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      feed.setStatus(FeedStatus.error);
      _feedStatus[feed.exchangeId] = FeedStatus.error;
      _statusController.add(Map.unmodifiable(_feedStatus));
    }
  }

  PriceFeed? _buildFeed(String exchangeId, Set<String> pairs) {
    final ex = ExchangeCatalog.byId(exchangeId);
    if (ex.kind != ExchangeKind.cex) return null; // DEX feeds come in v1.5+
    switch (exchangeId) {
      case 'binance':
        return BinanceFeed(pairs: pairs);
      case 'coinbase':
        return CoinbaseFeed(pairs: pairs);
      case 'kraken':
        return KrakenFeed(pairs: pairs);
      case 'okx':
        return OkxFeed(pairs: pairs);
      case 'bybit':
        return BybitFeed(pairs: pairs);
      default:
        return null; // other CEXs not yet implemented
    }
  }

  void dispose() {
    stop();
    _snapshotController.close();
    _statusController.close();
  }
}

/// Immutable snapshot of all current ticker quotes.
class PriceSnapshot {
  final Map<String, Ticker> quotes; // key: "$exchangeId|$pair"
  final DateTime timestamp;

  PriceSnapshot(Map<String, Ticker> quotes)
      : quotes = UnmodifiableMapView(quotes),
        timestamp = DateTime.now();

  /// All quotes for a specific pair, across exchanges.
  List<Ticker> forPair(String pair) {
    return quotes.entries
        .where((e) => e.value.pair == pair)
        .map((e) => e.value)
        .toList();
  }

  /// All quotes from a specific exchange.
  List<Ticker> forExchange(String exchangeId) {
    return quotes.entries
        .where((e) => e.value.exchangeId == exchangeId)
        .map((e) => e.value)
        .toList();
  }

  /// All distinct pairs currently being quoted.
  Set<String> get pairs => quotes.values.map((t) => t.pair).toSet();
}