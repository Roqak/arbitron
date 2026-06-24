import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../domain/ticker.dart';
import 'price_feed.dart';

/// Binance WebSocket ticker stream.
/// Uses combined bookTicker stream for bid/ask + last trade price.
/// Docs: https://developers.binance.com/docs/binance-spot-api-docs/web-socket-streams
class BinanceFeed extends PriceFeed {
  BinanceFeed({required super.pairs}) : super(exchangeId: 'binance');

  @override
  String get url {
    // Streams: <symbol>@bookTicker gives bidPrice/askPrice/qty.
    final streams = pairs.map((p) {
      final sym = p.replaceAll('/', '').toLowerCase();
      return '$sym@bookTicker';
    }).join('/');
    return 'wss://stream.binance.com:9443/stream?streams=$streams';
  }

  @override
  void subscribe(dynamic channel) {
    // Binance's combined stream auto-subscribes via the URL; no payload needed.
  }

  @override
  List<Ticker> parseFrame(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return [];
      final rawSymbol = data['s'] as String? ?? '';
      final pair = PriceFeed.normalizePair(rawSymbol);
      final bid = double.tryParse(data['b'] as String? ?? '') ?? 0;
      final ask = double.tryParse(data['a'] as String? ?? '') ?? 0;
      if (bid <= 0 || ask <= 0) return [];
      return [Ticker(exchangeId: exchangeId, pair: pair, bid: bid, ask: ask, last: (bid + ask) / 2, updatedAt: DateTime.now())];
    } catch (_) {
      return [];
    }
  }
}

/// Coinbase Advanced WebSocket ticker channel.
/// Docs: https://docs.cdp.coinbase.com/exchange/docs/websocket-channels
class CoinbaseFeed extends PriceFeed {
  CoinbaseFeed({required super.pairs}) : super(exchangeId: 'coinbase');

  @override
  String get url => 'wss://ws-feed.exchange.coinbase.com';

  @override
  Object? buildSubscribePayload() {
    final productIds = pairs.map((p) => p.replaceAll('/', '-')).toList();
    return jsonEncode({
      'type': 'subscribe',
      'product_ids': productIds,
      'channels': ['ticker'],
    });
  }

  @override
  void subscribe(dynamic channel) {
    final payload = buildSubscribePayload();
    if (payload != null && channel is WebSocketChannel) {
      channel.sink.add(payload as String);
    }
  }

  @override
  List<Ticker> parseFrame(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      if (json['type'] != 'ticker') return [];
      final rawSymbol = json['product_id'] as String? ?? '';
      final pair = PriceFeed.normalizePair(rawSymbol);
      final bid = double.tryParse(json['best_bid'] as String? ?? '') ?? 0;
      final ask = double.tryParse(json['best_ask'] as String? ?? '') ?? 0;
      final last = double.tryParse(json['price'] as String? ?? '') ?? 0;
      if (bid <= 0 || ask <= 0) return [];
      return [Ticker(exchangeId: exchangeId, pair: pair, bid: bid, ask: ask, last: last, updatedAt: DateTime.now())];
    } catch (_) {
      return [];
    }
  }
}

/// Kraken WebSocket ticker channel.
/// Docs: https://docs.kraken.com/api/docs/websocket/
class KrakenFeed extends PriceFeed {
  KrakenFeed({required super.pairs}) : super(exchangeId: 'kraken');

  @override
  String get url => 'wss://ws.kraken.com';

  @override
  Object? buildSubscribePayload() {
    // Kraken uses XBT for BTC.
    final symbols = pairs.map((p) {
      final base = p.split('/').first;
      final quote = p.split('/').last;
      final b = base == 'BTC' ? 'XBT' : base;
      return '$b/$quote';
    }).toList();
    return jsonEncode({
      'event': 'subscribe',
      'pair': symbols,
      'subscription': {'name': 'ticker'},
    });
  }

  @override
  void subscribe(dynamic channel) {
    final payload = buildSubscribePayload();
    if (payload != null && channel is WebSocketChannel) {
      channel.sink.add(payload as String);
    }
  }

  @override
  List<Ticker> parseFrame(dynamic message) {
    try {
      final decoded = jsonDecode(message as String);
      // Kraken ticker updates are arrays: [channelID, {data}, pairName, "ticker"]
      if (decoded is! List || decoded.length < 4) return [];
      if (decoded[3] != 'ticker') return [];
      final data = decoded[1] as Map<String, dynamic>;
      final rawPair = decoded[2] as String? ?? '';
      final pair = _normalizeKrakenPair(rawPair);
      // a = ask array [price, ...], b = bid array [price, ...]
      final askArr = data['a'] as List?;
      final bidArr = data['b'] as List?;
      if (askArr == null || bidArr == null || askArr.isEmpty || bidArr.isEmpty) return [];
      final ask = double.tryParse(askArr[0] as String) ?? 0;
      final bid = double.tryParse(bidArr[0] as String) ?? 0;
      if (bid <= 0 || ask <= 0) return [];
      return [Ticker(exchangeId: exchangeId, pair: pair, bid: bid, ask: ask, last: (bid + ask) / 2, updatedAt: DateTime.now())];
    } catch (_) {
      return [];
    }
  }

  static String _normalizeKrakenPair(String raw) {
    // Kraken returns "XBT/USDT" etc.
    var p = raw.toUpperCase().replaceAll('XBT', 'BTC');
    return PriceFeed.normalizePair(p);
  }
}

/// OKX WebSocket ticker channel.
/// Docs: https://www.okx.com/docs-v5/en/#order-book-trading-websocket-ticker-channel
class OkxFeed extends PriceFeed {
  OkxFeed({required super.pairs}) : super(exchangeId: 'okx');

  @override
  String get url => 'wss://ws.okx.com:8443/ws/v5/public';

  @override
  Object? buildSubscribePayload() {
    final args = pairs.map((p) {
      final instId = p.replaceAll('/', '-');
      return {'channel': 'tickers', 'instId': instId};
    }).toList();
    return jsonEncode({'op': 'subscribe', 'args': args});
  }

  @override
  void subscribe(dynamic channel) {
    final payload = buildSubscribePayload();
    if (payload != null && channel is WebSocketChannel) {
      channel.sink.add(payload as String);
    }
  }

  @override
  List<Ticker> parseFrame(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final event = json['event'] as String?;
      if (event == 'subscribe' || event == 'error') return [];
      final data = json['data'] as List?;
      if (data == null || data.isEmpty) return [];
      final ticker = data[0] as Map<String, dynamic>;
      final instId = ticker['instId'] as String? ?? '';
      final pair = PriceFeed.normalizePair(instId);
      final bid = double.tryParse(ticker['bidPx'] as String? ?? '') ?? 0;
      final ask = double.tryParse(ticker['askPx'] as String? ?? '') ?? 0;
      final last = double.tryParse(ticker['last'] as String? ?? '') ?? 0;
      if (bid <= 0 || ask <= 0) return [];
      return [Ticker(exchangeId: exchangeId, pair: pair, bid: bid, ask: ask, last: last, updatedAt: DateTime.now())];
    } catch (_) {
      return [];
    }
  }
}

/// Bybit WebSocket v5 ticker channel.
/// Docs: https://bybit-exchange.github.io/docs/v5/websocket/public/ticker
class BybitFeed extends PriceFeed {
  BybitFeed({required super.pairs}) : super(exchangeId: 'bybit');

  @override
  String get url => 'wss://stream.bybit.com/v5/public/spot';

  @override
  Object? buildSubscribePayload() {
    final args = pairs.map((p) => 'tickers.${p.replaceAll('/', '')}').toList();
    return jsonEncode({'op': 'subscribe', 'args': args});
  }

  @override
  void subscribe(dynamic channel) {
    final payload = buildSubscribePayload();
    if (payload != null && channel is WebSocketChannel) {
      channel.sink.add(payload as String);
    }
  }

  @override
  List<Ticker> parseFrame(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final op = json['op'] as String?;
      if (op == 'subscribe' || op == 'pong') return [];
      final topic = json['topic'] as String? ?? '';
      if (!topic.startsWith('tickers.')) return [];
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return [];
      final rawSymbol = topic.substring(8); // after "tickers."
      final pair = PriceFeed.normalizePair(rawSymbol);
      final bid = double.tryParse(data['bid1Price'] as String? ?? '') ?? 0;
      final ask = double.tryParse(data['ask1Price'] as String? ?? '') ?? 0;
      final last = double.tryParse(data['lastPrice'] as String? ?? '') ?? 0;
      if (bid <= 0 || ask <= 0) return [];
      return [Ticker(exchangeId: exchangeId, pair: pair, bid: bid, ask: ask, last: last, updatedAt: DateTime.now())];
    } catch (_) {
      return [];
    }
  }
}