import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../domain/credentials.dart';

/// Real balance and order result from an exchange REST API.
class Balance {
  final String asset;
  final double free;
  final double locked;
  const Balance({required this.asset, required this.free, required this.locked});
  double get total => free + locked;
}

class OrderResult {
  final String orderId;
  final String status; // e.g. 'FILLED', 'NEW', 'REJECTED'
  final double executedQty;
  final double avgPrice;
  final String? error;

  const OrderResult({
    required this.orderId,
    required this.status,
    this.executedQty = 0,
    this.avgPrice = 0,
    this.error,
  });

  bool get isFilled => status == 'FILLED' || status == 'CLOSED';
  bool get hasError => error != null;
}

/// Abstract interface for exchange REST API operations. Each implementation
/// handles the specific auth signing and endpoints for its exchange.
/// See PRD §8.4 (Exchange & DEX Configuration) and §10.1.
abstract class ExchangeTradingClient {
  String get exchangeId;
  Future<List<Balance>> fetchBalances(ExchangeCredentials creds);
  Future<OrderResult> placeMarketOrder({
    required ExchangeCredentials creds,
    required String symbol,
    required String side, // 'BUY' or 'SELL'
    required double quantity,
  });
  Future<OrderResult> getOrderStatus({
    required ExchangeCredentials creds,
    required String orderId,
    required String symbol,
  });
}

/// Factory for getting the right trading client per exchange.
class TradingClientFactory {
  TradingClientFactory._();

  static ExchangeTradingClient? forExchange(String exchangeId) {
    switch (exchangeId) {
      case 'binance':
        return BinanceTradingClient();
      case 'kraken':
        return KrakenTradingClient();
      case 'okx':
        return OkxTradingClient();
      case 'bybit':
        return BybitTradingClient();
      case 'coinbase':
        return CoinbaseTradingClient();
      default:
        return null; // Not yet implemented for this exchange
    }
  }
}

// ── Binance ───────────────────────────────────────────────────────────────────
class BinanceTradingClient implements ExchangeTradingClient {
  @override
  String get exchangeId => 'binance';

  final _dio = Dio(BaseOptions(baseUrl: 'https://api.binance.com', connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));

  String _timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  String _sign(String secret, Map<String, String> params) {
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final key = utf8.encode(secret);
    final bytes = utf8.encode(query);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  @override
  Future<List<Balance>> fetchBalances(ExchangeCredentials creds) async {
    try {
      final params = <String, String>{'timestamp': _timestamp(), 'recvWindow': '10000'};
      final signature = _sign(creds.apiSecret, params);
      final response = await _dio.get('/api/v3/account', queryParameters: {
        ...params, 'signature': signature,
      }, options: Options(headers: {'X-MBX-APIKEY': creds.apiKey}));
      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      final balances = data['balances'] as List? ?? [];
      return balances.map((b) {
        final m = b as Map<String, dynamic>;
        final free = double.tryParse(m['free']?.toString() ?? '0') ?? 0;
        final locked = double.tryParse(m['locked']?.toString() ?? '0') ?? 0;
        return Balance(asset: m['asset'] as String, free: free, locked: locked);
      }).where((b) => b.total > 0).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<OrderResult> placeMarketOrder({required ExchangeCredentials creds, required String symbol, required String side, required double quantity}) async {
    final params = <String, String>{
      'symbol': symbol, 'side': side, 'type': 'MARKET', 'quantity': quantity.toString(),
      'timestamp': _timestamp(), 'recvWindow': '10000',
    };
    final signature = _sign(creds.apiSecret, params);
    try {
      final response = await _dio.post('/api/v3/order', queryParameters: {...params, 'signature': signature}, options: Options(headers: {'X-MBX-APIKEY': creds.apiKey}));
      if (response.statusCode != 200) return OrderResult(orderId: '', status: 'REJECTED', error: 'HTTP ${response.statusCode}');
      final data = response.data as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'NEW';
      final executedQty = double.tryParse(data['executedQty']?.toString() ?? '0') ?? 0;
      final avgPrice = double.tryParse(data['cummulativeQuoteQty']?.toString() ?? '0') ?? 0;
      return OrderResult(orderId: data['orderId']?.toString() ?? '', status: status, executedQty: executedQty, avgPrice: executedQty > 0 ? avgPrice / executedQty : 0);
    } catch (e) {
      return OrderResult(orderId: '', status: 'REJECTED', error: e.toString());
    }
  }

  @override
  Future<OrderResult> getOrderStatus({required ExchangeCredentials creds, required String orderId, required String symbol}) async {
    final params = <String, String>{'symbol': symbol, 'orderId': orderId, 'timestamp': _timestamp()};
    final signature = _sign(creds.apiSecret, params);
    final response = await _dio.get('/api/v3/order', queryParameters: {...params, 'signature': signature}, options: Options(headers: {'X-MBX-APIKEY': creds.apiKey}));
    final data = response.data as Map<String, dynamic>;
    return OrderResult(orderId: orderId, status: data['status'] as String? ?? 'UNKNOWN', executedQty: double.tryParse(data['executedQty']?.toString() ?? '0') ?? 0, avgPrice: double.tryParse(data['price']?.toString() ?? '0') ?? 0);
  }
}

// ── Kraken ────────────────────────────────────────────────────────────────────
class KrakenTradingClient implements ExchangeTradingClient {
  @override
  String get exchangeId => 'kraken';

  final _dio = Dio(BaseOptions(baseUrl: 'https://api.kraken.com', connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));

  String _nonce() => (DateTime.now().millisecondsSinceEpoch * 1000).toString();

  String _sign(String secret, String urlPath, String nonce, String postData) {
    final key = base64Decode(secret);
    final sha256Hash = sha256.convert(utf8.encode(nonce + postData));
    final hmacKey = Hmac(sha512, key);
    final hmac = hmacKey.convert(utf8.encode(urlPath + sha256Hash.toString()));
    return base64Encode(hmac.bytes);
  }

  @override
  Future<List<Balance>> fetchBalances(ExchangeCredentials creds) async {
    try {
      final nonce = _nonce();
      final postData = 'nonce=$nonce';
      final signature = _sign(creds.apiSecret, '/0/private/Balance', nonce, postData);
      final response = await _dio.post('/0/private/Balance', data: postData, options: Options(headers: {'API-Key': creds.apiKey, 'API-Sign': signature, 'Content-Type': 'application/x-www-form-urlencoded'}));
      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>? ?? {};
      return result.entries.map((e) {
        final asset = e.key.replaceAll('X', '').replaceAll('Z', '');
        final balance = double.tryParse(e.value.toString()) ?? 0;
        return Balance(asset: asset, free: balance, locked: 0);
      }).where((b) => b.total > 0).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<OrderResult> placeMarketOrder({required ExchangeCredentials creds, required String symbol, required String side, required double quantity}) async {
    final nonce = _nonce();
    final pair = symbol.replaceAll('/', '');
    final postData = 'nonce=$nonce&pair=$pair&type=$side&ordertype=market&volume=$quantity';
    final signature = _sign(creds.apiSecret, '/0/private/AddOrder', nonce, postData);
    try {
      final response = await _dio.post('/0/private/AddOrder', data: postData, options: Options(headers: {'API-Key': creds.apiKey, 'API-Sign': signature, 'Content-Type': 'application/x-www-form-urlencoded'}));
      final data = response.data as Map<String, dynamic>;
      final txid = (data['result']?['txid'] as List?)?.first?.toString() ?? '';
      return OrderResult(orderId: txid, status: 'NEW');
    } catch (e) {
      return OrderResult(orderId: '', status: 'REJECTED', error: e.toString());
    }
  }

  @override
  Future<OrderResult> getOrderStatus({required ExchangeCredentials creds, required String orderId, required String symbol}) async {
    final nonce = _nonce();
    final postData = 'nonce=$nonce&txid=$orderId';
    final signature = _sign(creds.apiSecret, '/0/private/QueryOrders', nonce, postData);
    final response = await _dio.post('/0/private/QueryOrders', data: postData, options: Options(headers: {'API-Key': creds.apiKey, 'API-Sign': signature, 'Content-Type': 'application/x-www-form-urlencoded'}));
    final data = response.data as Map<String, dynamic>;
    final order = (data['result'] as Map<String, dynamic>?)?.values.first as Map<String, dynamic>?;
    return OrderResult(orderId: orderId, status: order?['status'] as String? ?? 'UNKNOWN');
  }
}

// ── OKX ────────────────────────────────────────────────────────────────────────
class OkxTradingClient implements ExchangeTradingClient {
  @override
  String get exchangeId => 'okx';

  final _dio = Dio(BaseOptions(baseUrl: 'https://www.okx.com', connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));

  String _timestamp() {
    final now = DateTime.now().toUtc();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}T${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}Z';
  }

  String _sign(String secret, String timestamp, String method, String path, String body) {
    final key = utf8.encode(secret);
    final message = timestamp + method + path + (body.isEmpty ? '' : body);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(utf8.encode(message));
    return base64Encode(digest.bytes);
  }

  @override
  Future<List<Balance>> fetchBalances(ExchangeCredentials creds) async {
    try {
      final ts = _timestamp();
      final path = '/api/v5/account/balance';
      final signature = _sign(creds.apiSecret, ts, 'GET', path, '');
      final response = await _dio.get(path, options: Options(headers: {'OK-ACCESS-KEY': creds.apiKey, 'OK-ACCESS-SIGN': signature, 'OK-ACCESS-TIMESTAMP': ts, 'OK-ACCESS-PASSPHRASE': creds.passphrase ?? ''}));
      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      final balanceData = (data['data'] as List?)?.first as Map<String, dynamic>?;
      final details = balanceData?['details'] as List? ?? [];
      return details.map((d) {
        final m = d as Map<String, dynamic>;
        final free = double.tryParse(m['availBal']?.toString() ?? '0') ?? 0;
        final locked = double.tryParse(m['frozenBal']?.toString() ?? '0') ?? 0;
        return Balance(asset: m['ccy'] as String, free: free, locked: locked);
      }).where((b) => b.total > 0).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<OrderResult> placeMarketOrder({required ExchangeCredentials creds, required String symbol, required String side, required double quantity}) async {
    final instId = symbol.replaceAll('/', '-');
    final ts = _timestamp();
    final path = '/api/v5/trade/order';
    final body = jsonEncode({'instId': instId, 'tdMode': 'cash', 'side': side.toLowerCase(), 'ordType': 'market', 'sz': quantity.toString()});
    final signature = _sign(creds.apiSecret, ts, 'POST', path, body);
    try {
      final response = await _dio.post(path, data: body, options: Options(headers: {'OK-ACCESS-KEY': creds.apiKey, 'OK-ACCESS-SIGN': signature, 'OK-ACCESS-TIMESTAMP': ts, 'OK-ACCESS-PASSPHRASE': creds.passphrase ?? '', 'Content-Type': 'application/json'}));
      final data = response.data as Map<String, dynamic>;
      final orderData = (data['data'] as List?)?.first as Map<String, dynamic>?;
      return OrderResult(orderId: orderData?['ordId']?.toString() ?? '', status: orderData?['sCode'] == '0' ? 'NEW' : 'REJECTED', error: orderData?['sMsg']?.toString());
    } catch (e) {
      return OrderResult(orderId: '', status: 'REJECTED', error: e.toString());
    }
  }

  @override
  Future<OrderResult> getOrderStatus({required ExchangeCredentials creds, required String orderId, required String symbol}) async {
    final instId = symbol.replaceAll('/', '-');
    final ts = _timestamp();
    final path = '/api/v5/trade/order?instId=$instId&ordId=$orderId';
    final signature = _sign(creds.apiSecret, ts, 'GET', path, '');
    final response = await _dio.get(path, options: Options(headers: {'OK-ACCESS-KEY': creds.apiKey, 'OK-ACCESS-SIGN': signature, 'OK-ACCESS-TIMESTAMP': ts, 'OK-ACCESS-PASSPHRASE': creds.passphrase ?? ''}));
    final data = response.data as Map<String, dynamic>;
    final orderData = (data['data'] as List?)?.first as Map<String, dynamic>?;
    return OrderResult(orderId: orderId, status: orderData?['state']?.toString() ?? 'UNKNOWN');
  }
}

// ── Bybit ─────────────────────────────────────────────────────────────────────
class BybitTradingClient implements ExchangeTradingClient {
  @override
  String get exchangeId => 'bybit';

  final _dio = Dio(BaseOptions(baseUrl: 'https://api.bybit.com', connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));

  String _timestamp() => (DateTime.now().millisecondsSinceEpoch).toString();

  String _sign(String secret, String timestamp, String apiKey, String recvWindow, String payload) {
    final paramStr = '$timestamp$apiKey$recvWindow$payload';
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(paramStr));
    return digest.toString();
  }

  @override
  Future<List<Balance>> fetchBalances(ExchangeCredentials creds) async {
    try {
      final ts = _timestamp();
      final recvWindow = '10000';
      final signature = _sign(creds.apiSecret, ts, creds.apiKey, recvWindow, '');
      final response = await _dio.get('/v5/account/wallet/balance', queryParameters: {'accountType': 'UNIFIED'}, options: Options(headers: {'X-BAPI-API-KEY': creds.apiKey, 'X-BAPI-SIGN': signature, 'X-BAPI-SIGN-TYPE': '2', 'X-BAPI-TIMESTAMP': ts, 'X-BAPI-RECV-WINDOW': recvWindow}));
      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      final accounts = (data['result']?['list'] as List?)?.first as Map<String, dynamic>?;
      final coins = accounts?['coin'] as List? ?? [];
      return coins.map((c) {
        final m = c as Map<String, dynamic>;
        final free = double.tryParse(m['walletBalance']?.toString() ?? '0') ?? 0;
        final locked = double.tryParse(m['locked']?.toString() ?? '0') ?? 0;
        return Balance(asset: m['coin'] as String, free: free, locked: locked);
      }).where((b) => b.total > 0).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<OrderResult> placeMarketOrder({required ExchangeCredentials creds, required String symbol, required String side, required double quantity}) async {
    final category = 'spot';
    final ts = _timestamp();
    final recvWindow = '10000';
    final symbolNorm = symbol.replaceAll('/', '');
    final payload = jsonEncode({'category': category, 'symbol': symbolNorm, 'side': side, 'orderType': 'Market', 'qty': quantity.toString()});
    final signature = _sign(creds.apiSecret, ts, creds.apiKey, recvWindow, payload);
    try {
      final response = await _dio.post('/v5/order/create', data: payload, options: Options(headers: {'X-BAPI-API-KEY': creds.apiKey, 'X-BAPI-SIGN': signature, 'X-BAPI-SIGN-TYPE': '2', 'X-BAPI-TIMESTAMP': ts, 'X-BAPI-RECV-WINDOW': recvWindow, 'Content-Type': 'application/json'}));
      final data = response.data as Map<String, dynamic>;
      final orderId = data['result']?['orderId']?.toString() ?? '';
      return OrderResult(orderId: orderId, status: data['retCode'] == 0 ? 'NEW' : 'REJECTED', error: data['retMsg']?.toString());
    } catch (e) {
      return OrderResult(orderId: '', status: 'REJECTED', error: e.toString());
    }
  }

  @override
  Future<OrderResult> getOrderStatus({required ExchangeCredentials creds, required String orderId, required String symbol}) async {
    // Simplified — return the order as-is for now.
    return OrderResult(orderId: orderId, status: 'NEW');
  }
}

// ── Coinbase Advanced ─────────────────────────────────────────────────────────
class CoinbaseTradingClient implements ExchangeTradingClient {
  @override
  String get exchangeId => 'coinbase';

  final _dio = Dio(BaseOptions(baseUrl: 'https://api.coinbase.com', connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));

  String _timestamp() => (DateTime.now().millisecondsSinceEpoch / 1000).toString();

  String _sign(String secret, String timestamp, String method, String path, String body) {
    final key = base64Decode(secret);
    final message = timestamp + method + path + body;
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(utf8.encode(message));
    return base64Encode(digest.bytes);
  }

  @override
  Future<List<Balance>> fetchBalances(ExchangeCredentials creds) async {
    try {
      final ts = _timestamp();
      final path = '/api/v3/brokerage/accounts';
      final signature = _sign(creds.apiSecret, ts, 'GET', path, '');
      final response = await _dio.get(path, options: Options(headers: {'CB-ACCESS-KEY': creds.apiKey, 'CB-ACCESS-SIGN': signature, 'CB-ACCESS-TIMESTAMP': ts}));
      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      final accounts = data['accounts'] as List? ?? [];
      return accounts.map((a) {
        final m = a as Map<String, dynamic>;
        final available = double.tryParse(m['available_balance']?['value']?.toString() ?? '0') ?? 0;
        final hold = double.tryParse(m['hold']?['value']?.toString() ?? '0') ?? 0;
        return Balance(asset: m['currency'] as String, free: available, locked: hold);
      }).where((b) => b.total > 0).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<OrderResult> placeMarketOrder({required ExchangeCredentials creds, required String symbol, required String side, required double quantity}) async {
    final productId = symbol.replaceAll('/', '-');
    final ts = _timestamp();
    final path = '/api/v3/brokerage/orders';
    final body = jsonEncode({
      'client_order_id': 'arbitron_${DateTime.now().millisecondsSinceEpoch}',
      'product_id': productId,
      'side': side.toLowerCase(),
      'order_configuration': {'market_market_ioc': {'base_size': quantity.toString()}},
    });
    final signature = _sign(creds.apiSecret, ts, 'POST', path, body);
    try {
      final response = await _dio.post(path, data: body, options: Options(headers: {'CB-ACCESS-KEY': creds.apiKey, 'CB-ACCESS-SIGN': signature, 'CB-ACCESS-TIMESTAMP': ts, 'Content-Type': 'application/json'}));
      final data = response.data as Map<String, dynamic>;
      final orderId = data['order_id']?.toString() ?? '';
      final status = data['success'] == true ? 'NEW' : 'REJECTED';
      return OrderResult(orderId: orderId, status: status, error: data['error_response']?['error']?.toString());
    } catch (e) {
      return OrderResult(orderId: '', status: 'REJECTED', error: e.toString());
    }
  }

  @override
  Future<OrderResult> getOrderStatus({required ExchangeCredentials creds, required String orderId, required String symbol}) async {
    final ts = _timestamp();
    final path = '/api/v3/brokerage/orders/historical/$orderId';
    final signature = _sign(creds.apiSecret, ts, 'GET', path, '');
    final response = await _dio.get(path, options: Options(headers: {'CB-ACCESS-KEY': creds.apiKey, 'CB-ACCESS-SIGN': signature, 'CB-ACCESS-TIMESTAMP': ts}));
    final data = response.data as Map<String, dynamic>;
    final order = data['order'] as Map<String, dynamic>?;
    return OrderResult(orderId: orderId, status: order?['status']?.toString() ?? 'UNKNOWN');
  }
}