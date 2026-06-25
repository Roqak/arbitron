import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import '../app_cubit.dart';
import '../domain/strategy.dart';
import '../domain/trade.dart';
import '../domain/opportunity.dart';

/// Embedded read-only REST API server for power users. See PRD §12 (v3.0 —
/// API access for power users). Exposes live opportunities, trades, and
/// strategies as JSON on a local port. Authentication via a user-generated
/// API token stored in secure storage.
class ApiServer {
  ApiServer({required this.cubit});

  final AppCubit cubit;
  HttpServer? _server;
  String? _token;
  int? _port;

  bool get isRunning => _server != null;
  int? get port => _port;
  String? get token => _token;

  /// Starts the API server on [port] with the given auth [token].
  Future<void> start({required int port, required String token}) async {
    try {
      if (_server != null) await stop();
      _token = token;
      _port = port;
      final handler = const shelf.Pipeline()
          .addMiddleware(shelf.logRequests(logger: (msg, isError) => _log(msg)))
          .addMiddleware(_authMiddleware(token))
          .addHandler(_router);
      _server = await io.serve(handler, '0.0.0.0', port);
    } catch (e) {
      _server = null;
      _token = null;
      _port = null;
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
  }

  void _log(String msg) {
    // Suppress in production; could route to analytics.
  }

  shelf.Middleware _authMiddleware(String token) {
    return (shelf.Handler innerHandler) {
      return (shelf.Request request) async {
        final auth = request.headers['authorization'];
        if (auth == null || auth != 'Bearer $token') {
          return shelf.Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: {'Content-Type': 'application/json'});
        }
        return await innerHandler(request);
      };
    };
  }

  Future<shelf.Response> _router(shelf.Request request) async {
    final path = request.url.path;
    final state = cubit.state;

    switch (path) {
      case 'api/v1/status':
        return _json({
          'feeds_connected': state.feedsConnected,
          'llm_configured': state.llmConfigured,
          'last_updated': state.lastUpdated.toIso8601String(),
          'opportunities_count': state.opportunities.length,
          'trades_count': state.trades.length,
        });

      case 'api/v1/opportunities':
        return _json({
          'opportunities': state.opportunities.map(_opportunityJson).toList(),
        });

      case 'api/v1/trades':
        return _json({
          'trades': state.trades.map(_tradeJson).toList(),
        });

      case 'api/v1/strategies':
        return _json({
          'strategies': state.strategies.map(_strategyJson).toList(),
        });

      case 'api/v1/portfolio':
        return _json({
          'portfolio_value': state.portfolioValue,
          'today_pnl': state.todayPnl,
          'total_pnl': state.totalPnl,
        });

      case '':
      case 'api':
        return _json({
          'name': 'Arbitron API',
          'version': 'v1',
          'endpoints': [
            'GET /api/v1/status',
            'GET /api/v1/opportunities',
            'GET /api/v1/trades',
            'GET /api/v1/strategies',
            'GET /api/v1/portfolio',
          ],
          'auth': 'Bearer token required',
        });

      default:
        return _json({'error': 'Not found', 'path': path}, status: 404);
    }
  }

  shelf.Response _json(Map<String, dynamic> body, {int status = 200}) {
    return shelf.Response(status, body: jsonEncode(body), headers: {'Content-Type': 'application/json'});
  }

  Map<String, dynamic> _opportunityJson(Opportunity o) => {
    'id': o.id, 'pair': o.pair, 'buy_exchange': o.buyExchangeId, 'sell_exchange': o.sellExchangeId,
    'buy_price': o.buyPrice, 'sell_price': o.sellPrice, 'gross_spread_pct': o.grossSpreadPct,
    'est_fees_usd': o.estFeesUsd, 'est_slippage_usd': o.estSlippageUsd,
    'net_profit_usd': o.netProfitUsd, 'net_profit_pct': o.netProfitPct,
    'confidence_score': o.confidenceScore, 'strategy': o.strategy.name,
    'detected_at': o.detectedAt.toIso8601String(), 'is_live': o.isLive,
    if (o.bridgeName != null) 'bridge': o.bridgeName,
    if (o.bridgeCostUsd != null) 'bridge_cost_usd': o.bridgeCostUsd,
  };

  Map<String, dynamic> _tradeJson(TradeRecord t) => {
    'id': t.id, 'executed_at': t.executedAt.toIso8601String(),
    'strategy': t.strategyName, 'pair': t.pair,
    'buy_exchange': t.buyExchangeId, 'sell_exchange': t.sellExchangeId,
    'size_usd': t.sizeUsd, 'net_pnl': t.netPnl, 'mode': t.mode.name, 'profit': t.profit,
  };

  Map<String, dynamic> _strategyJson(Strategy s) => {
    'id': s.id, 'name': s.name, 'type': s.type.name, 'enabled': s.enabled,
    'mode': s.mode.name, 'total_trades': s.totalTrades, 'total_pnl': s.totalPnl,
  };
}