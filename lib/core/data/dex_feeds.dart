import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../domain/ticker.dart';
import 'price_feed.dart';

/// A REST-polling price feed for DEXs that don't offer WebSocket ticker streams.
/// Polls public price APIs at a fixed interval (2s per PRD §10.3) and emits
/// [Ticker] updates. See PRD §4.2 and §10.1.
class DexPollFeed extends PriceFeed {
  DexPollFeed({
    required super.exchangeId,
    required super.pairs,
    required this.priceUrlTemplate,
    this.pollInterval = const Duration(seconds: 2),
  });

  /// URL template with {pair} placeholder, e.g.
  /// 'https://price.jup.ag/v6/price?ids={pair}'
  final String priceUrlTemplate;
  final Duration pollInterval;
  Timer? _timer;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  @override
  String get url => priceUrlTemplate;

  @override
  void subscribe(dynamic channel) {
    // REST polling — no WebSocket channel; start timer instead.
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => _poll());
    // Immediately poll once.
    _poll();
  }

  Future<void> _poll() async {
    for (final pair in pairs) {
      try {
        final url = priceUrlTemplate.replaceAll('{pair}', pair);
        final response = await _dio.get<dynamic>(url);
        if (response.statusCode != 200) continue;
        final data = response.data;
        final ticker = parseRestResponse(data, pair);
        if (ticker != null) emit(ticker);
      } catch (_) {
        // ignore — transient network errors
      }
    }
  }

  /// Parses a REST response into a [Ticker]. Override per-DEX.
  Ticker? parseRestResponse(dynamic data, String pair) {
    // Default: expects { "price": "123.45", "bid": "123.40", "ask": "123.50" }
    try {
      final json = data is String ? jsonDecode(data) as Map<String, dynamic> : data as Map<String, dynamic>;
      final price = double.tryParse(json['price']?.toString() ?? '') ?? 0;
      if (price <= 0) return null;
      final bid = double.tryParse(json['bid']?.toString() ?? '') ?? price * 0.999;
      final ask = double.tryParse(json['ask']?.toString() ?? '') ?? price * 1.001;
      return Ticker(exchangeId: exchangeId, pair: pair, bid: bid, ask: ask, last: price, updatedAt: DateTime.now());
    } catch (_) {
      return null;
    }
  }

  @override
  List<Ticker> parseFrame(dynamic message) => const []; // not used for REST feeds

  @override
  void dispose() {
    _timer?.cancel();
    _dio.close();
    super.dispose();
  }
}

/// Jupiter Aggregator price feed (Solana). Uses the public price API.
class JupiterFeed extends DexPollFeed {
  JupiterFeed({required super.pairs})
      : super(
          exchangeId: 'jupiter',
          priceUrlTemplate: 'https://price.jup.ag/v6/price?ids={pair}',
        );

  @override
  Ticker? parseRestResponse(dynamic data, String pair) {
    try {
      final json = data is String ? jsonDecode(data) as Map<String, dynamic> : data as Map<String, dynamic>;
      final prices = json['data'] as Map<String, dynamic>?;
      if (prices == null) return null;
      final pairData = prices.entries.firstWhere(
        (e) => e.key.toUpperCase().contains(pair.split('/').first.toUpperCase()),
        orElse: () => prices.entries.first,
      );
      final price = (pairData.value as Map<String, dynamic>)['price'] as num?;
      if (price == null || price <= 0) return null;
      final bid = price.toDouble() * 0.999;
      final ask = price.toDouble() * 1.001;
      return Ticker(exchangeId: exchangeId, pair: pair, bid: bid, ask: ask, last: price.toDouble(), updatedAt: DateTime.now());
    } catch (_) {
      return null;
    }
  }
}