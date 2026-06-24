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

/// KuCoin WebSocket ticker channel.
class KuCoinFeed extends PriceFeed {
  KuCoinFeed({required super.pairs}) : super(exchangeId: 'kucoin');

  @override
  String get url => 'wss://push.kucoin.com/endpoint';

  @override
  void subscribe(dynamic channel) {
    final symbols = pairs.map((p) => p.replaceAll('/', '-')).toList();
    final payload = jsonEncode({
      'id': 1,
      'type': 'subscribe',
      'topic': '/market/ticker:${symbols.join(",")}',
      'response': true,
    });
    if (channel is WebSocketChannel) channel.sink.add(payload);
  }

  @override
  List<Ticker> parseFrame(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final type = json['type'] as String?;
      if (type != 'message') return [];
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return [];
      final rawSymbol = (data['symbol'] as String?) ?? '';
      final pair = PriceFeed.normalizePair(rawSymbol);
      final bid = double.tryParse(data['bestBid'] as String? ?? '') ?? 0;
      final ask = double.tryParse(data['bestAsk'] as String? ?? '') ?? 0;
      final last = double.tryParse(data['price'] as String? ?? '') ?? 0;
      if (bid <= 0 || ask <= 0) return [];
      return [Ticker(exchangeId: exchangeId, pair: pair, bid: bid, ask: ask, last: last, updatedAt: DateTime.now())];
    } catch (_) {
      return [];
    }
  }
}

/// Gate.io WebSocket ticker channel.
class GateFeed extends PriceFeed {
  GateFeed({required super.pairs}) : super(exchangeId: 'gate');

  @override
  String get url => 'wss://api.gate.com/ws/v4/';

  @override
  void subscribe(dynamic channel) {
    for (final p in pairs) {
      final currencyPair = p.replaceAll('/', '_').toLowerCase();
      final payload = jsonEncode({'time': DateTime.now().millisecondsSinceEpoch, 'channel': 'spot.tickers', 'event': 'subscribe', 'payload': [currencyPair]});
      if (channel is WebSocketChannel) channel.sink.add(payload);
    }
  }

  @override
  List<Ticker> parseFrame(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      if (json['channel'] != 'spot.tickers') return [];
      final result = json['result'] as Map<String, dynamic>?;
      if (result == null) return [];
      final rawPair = (result['currency_pair'] as String?) ?? '';
      final pair = PriceFeed.normalizePair(rawPair);
      final last = double.tryParse(result['last'] as String? ?? '') ?? 0;
      final bid = double.tryParse(result['highest_bid'] as String? ?? '') ?? 0;
      final ask = double.tryParse(result['lowest_ask'] as String? ?? '') ?? 0;
      if (bid <= 0 || ask <= 0) return [];
      return [Ticker(exchangeId: exchangeId, pair: pair, bid: bid, ask: ask, last: last, updatedAt: DateTime.now())];
    } catch (_) {
      return [];
    }
  }
}

/// Bitfinex WebSocket ticker channel.
class BitfinexFeed extends PriceFeed {
  BitfinexFeed({required super.pairs}) : super(exchangeId: 'bitfinex');

  @override
  String get url => 'wss://api-pub.bitfinex.com/ws/2';

  @override
  void subscribe(dynamic channel) {
    for (final p in pairs) {
      final symbol = 't${p.replaceAll('/', '')}';
      final payload = jsonEncode({'event': 'subscribe', 'channel': 'ticker', 'symbol': symbol});
      if (channel is WebSocketChannel) channel.sink.add(payload);
    }
  }

  @override
  List<Ticker> parseFrame(dynamic message) {
    try {
      final decoded = jsonDecode(message as String);
      if (decoded is Map) return [];
      if (decoded is! List || decoded.length < 2) return [];
      final data = decoded[1];
      if (data is! List || data.length < 4) return [];
      final bid = (data[0] as num).toDouble();
      final ask = (data[2] as num).toDouble();
      final last = data.length > 8 ? (data[8] as num).toDouble() : (bid + ask) / 2;
      if (bid <= 0 || ask <= 0) return [];
      final pair = pairs.first;
      return [Ticker(exchangeId: exchangeId, pair: pair, bid: bid, ask: ask, last: last, updatedAt: DateTime.now())];
    } catch (_) {
      return [];
    }
  }
}

/// Huobi / HTX WebSocket ticker channel.
class HuobiFeed extends PriceFeed {
  HuobiFeed({required super.pairs}) : super(exchangeId: 'huobi');

  @override
  String get url => 'wss://api-aws.huobi.pro/ws';

  @override
  void subscribe(dynamic channel) {
    for (final p in pairs) {
      final symbol = p.replaceAll('/', '').toLowerCase();
      final payload = jsonEncode({'sub': 'market.$symbol.detail'});
      if (channel is WebSocketChannel) channel.sink.add(payload);
    }
  }

  @override
  List<Ticker> parseFrame(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final tick = json['tick'] as Map<String, dynamic>?;
      if (tick == null) return [];
      final ch = json['ch'] as String? ?? '';
      final rawSymbol = ch.split('.')[1];
      final pair = PriceFeed.normalizePair(rawSymbol);
      final bid = (tick['bid'] as num?)?.toDouble() ?? 0;
      final ask = (tick['ask'] as num?)?.toDouble() ?? 0;
      final close = (tick['close'] as num?)?.toDouble() ?? 0;
      if (bid <= 0 || ask <= 0) return [];
      return [Ticker(exchangeId: exchangeId, pair: pair, bid: bid, ask: ask, last: close, updatedAt: DateTime.now())];
    } catch (_) {
      return [];
    }
  }
}

/// MEXC WebSocket ticker channel.
class MexcFeed extends PriceFeed {
  MexcFeed({required super.pairs}) : super(exchangeId: 'mexc');

  @override
  String get url => 'wss://contract.mexc.com/edge';

  @override
  void subscribe(dynamic channel) {
    for (final p in pairs) {
      final symbol = p.replaceAll('/', '').toLowerCase();
      final payload = jsonEncode({'method': 'sub.ticker', 'param': {'symbol': symbol}});
      if (channel is WebSocketChannel) channel.sink.add(payload);
    }
  }

  @override
  List<Ticker> parseFrame(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return [];
      final rawSymbol = (data['symbol'] as String?) ?? '';
      final pair = PriceFeed.normalizePair(rawSymbol);
      final bid = double.tryParse(data['bid1'] as String? ?? '') ?? 0;
      final ask = double.tryParse(data['ask1'] as String? ?? '') ?? 0;
      final last = double.tryParse(data['lastPrice'] as String? ?? '') ?? 0;
      if (bid <= 0 || ask <= 0) return [];
      return [Ticker(exchangeId: exchangeId, pair: pair, bid: bid, ask: ask, last: last, updatedAt: DateTime.now())];
    } catch (_) {
      return [];
    }
  }
}