import 'dart:async';
import 'exchange_trading_client.dart';
import 'secure_key_store.dart';
import '../domain/opportunity.dart';
import '../domain/trade.dart';
import '../domain/enums.dart';
import '../domain/exchange.dart';
import '../domain/credentials.dart';

/// Orchestrates real trading operations across exchanges. Handles balance
/// fetching, two-leg arbitrage execution (buy + sell), and fill tracking.
/// See PRD §6 (Execution Modes) and §10.
class TradingService {
  TradingService({required this.keyStore});

  final SecureKeyStore keyStore;
  final Map<String, ExchangeTradingClient> _clients = {};

  ExchangeTradingClient? _client(String exchangeId) {
    return _clients.putIfAbsent(exchangeId, () => TradingClientFactory.forExchange(exchangeId) as ExchangeTradingClient);
  }

  /// Fetches balances for all exchanges that have stored credentials.
  /// Returns a map of exchangeId -> list of balances.
  Future<Map<String, List<Balance>>> fetchAllBalances() async {
    final connected = await keyStore.connectedExchangeIds();
    final result = <String, List<Balance>>{};
    for (final exchangeId in connected) {
      final creds = await keyStore.readExchangeCredentials(exchangeId);
      if (creds == null || !creds.isComplete) continue;
      final client = _client(exchangeId);
      if (client == null) continue;
      try {
        final balances = await client.fetchBalances(creds);
        result[exchangeId] = balances;
      } catch (_) {
        // Skip failed exchanges — partial results are fine
      }
    }
    return result;
  }

  /// Computes total portfolio value in USD across all connected exchanges.
  /// Uses rough price estimates for non-USD assets. For a full implementation
  /// this would use live price feeds for conversion.
  Future<double> fetchPortfolioValueUsd() async {
    final allBalances = await fetchAllBalances();
    var total = 0.0;
    for (final balances in allBalances.values) {
      for (final b in balances) {
        // Stablecoins are ~$1. For others, we'd convert via live price.
        if (b.asset == 'USD' || b.asset == 'USDT' || b.asset == 'USDC' || b.asset == 'BUSD') {
          total += b.total;
        } else {
          // For non-stablecoin assets, estimate via the ticker if available.
          // For now, use 0 as placeholder — real conversion requires price data.
          // This will be improved when we wire in live price feeds.
          total += 0.0;
        }
      }
    }
    return total;
  }

  /// Executes a two-leg arbitrage: market buy on one exchange, market sell on
  /// the other. Returns the resulting [TradeRecord] if successful, or null
  /// if either leg fails.
  ///
  /// See PRD §6 — in Manual mode the user taps Execute; in Semi-Auto the
  /// countdown expires; in Autonomous the LLM decides.
  Future<TradeRecord?> executeArbitrage({
    required Opportunity opportunity,
    required double sizeUsd,
    required ExecutionMode mode,
    required String strategyId,
    required String strategyName,
  }) async {
    final o = opportunity;
    final buyCreds = await keyStore.readExchangeCredentials(o.buyExchangeId);
    final sellCreds = await keyStore.readExchangeCredentials(o.sellExchangeId);

    if (buyCreds == null || !buyCreds.isComplete) {
      return _failedTrade(o, sizeUsd, mode, strategyId, strategyName, 'No API credentials for ${ExchangeCatalog.byId(o.buyExchangeId).name}');
    }
    if (sellCreds == null || !sellCreds.isComplete) {
      return _failedTrade(o, sizeUsd, mode, strategyId, strategyName, 'No API credentials for ${ExchangeCatalog.byId(o.sellExchangeId).name}');
    }

    final buyClient = _client(o.buyExchangeId);
    final sellClient = _client(o.sellExchangeId);
    if (buyClient == null || sellClient == null) {
      return _failedTrade(o, sizeUsd, mode, strategyId, strategyName, 'Trading not supported on this exchange');
    }

    // Calculate quantity from size and buy price.
    final qty = o.buyPrice > 0 ? sizeUsd / o.buyPrice : 0.0;
    if (qty <= 0) {
      return _failedTrade(o, sizeUsd, mode, strategyId, strategyName, 'Invalid quantity calculation');
    }

    // Convert pair to exchange-specific symbol.
    final symbol = o.pair.replaceAll('/', '');

    // Leg 1: Market BUY on the buy exchange.
    final buyResult = await buyClient.placeMarketOrder(creds: buyCreds, symbol: symbol, side: 'BUY', quantity: qty);
    if (buyResult.hasError || buyResult.orderId.isEmpty) {
      return _failedTrade(o, sizeUsd, mode, strategyId, strategyName, 'Buy leg failed: ${buyResult.error ?? "unknown"}');
    }

    // Leg 2: Market SELL on the sell exchange.
    final sellResult = await sellClient.placeMarketOrder(creds: sellCreds, symbol: symbol, side: 'SELL', quantity: qty);
    if (sellResult.hasError || sellResult.orderId.isEmpty) {
      return _failedTrade(o, sizeUsd, mode, strategyId, strategyName, 'Sell leg failed: ${sellResult.error ?? "unknown"}');
    }

    // Compute actual P&L from filled prices (if available, else use estimates).
    final actualBuyPrice = buyResult.avgPrice > 0 ? buyResult.avgPrice : o.buyPrice;
    final actualSellPrice = sellResult.avgPrice > 0 ? sellResult.avgPrice : o.sellPrice;
    final grossPnl = (actualSellPrice - actualBuyPrice) * qty;
    final fees = o.estFeesUsd; // estimated; real fees would come from exchange
    final slippage = o.estSlippageUsd; // estimated
    final netPnl = grossPnl - fees - slippage;

    return TradeRecord(
      id: 'trade_${DateTime.now().millisecondsSinceEpoch}',
      executedAt: DateTime.now(),
      strategyId: strategyId,
      strategyName: strategyName,
      strategyType: o.strategy,
      pair: o.pair,
      buyExchangeId: o.buyExchangeId,
      sellExchangeId: o.sellExchangeId,
      sizeUsd: sizeUsd,
      entryPrice: actualBuyPrice,
      exitPrice: actualSellPrice,
      grossPnl: grossPnl,
      netPnl: netPnl,
      feesUsd: fees,
      slippageUsd: slippage,
      mode: mode,
      profit: netPnl >= 0,
      llmDecisionJson: o.analysisText,
      debrief: netPnl >= 0
          ? 'Real execution: buy filled at \$$actualBuyPrice, sell filled at \$$actualSellPrice. Net: \$${netPnl.toStringAsFixed(2)}.'
          : 'Real execution: slippage exceeded estimate. Net: \$${netPnl.toStringAsFixed(2)}.',
    );
  }

  TradeRecord _failedTrade(Opportunity o, double sizeUsd, ExecutionMode mode, String strategyId, String strategyName, String reason) {
    return TradeRecord(
      id: 'trade_failed_${DateTime.now().millisecondsSinceEpoch}',
      executedAt: DateTime.now(),
      strategyId: strategyId,
      strategyName: strategyName,
      strategyType: o.strategy,
      pair: o.pair,
      buyExchangeId: o.buyExchangeId,
      sellExchangeId: o.sellExchangeId,
      sizeUsd: sizeUsd,
      entryPrice: o.buyPrice,
      exitPrice: o.sellPrice,
      grossPnl: 0,
      netPnl: 0,
      feesUsd: 0,
      slippageUsd: 0,
      mode: mode,
      profit: false,
      llmDecisionJson: '',
      debrief: 'Execution failed: $reason',
    );
  }

  /// Checks whether credentials are stored for a given exchange.
  Future<bool> hasCredentials(String exchangeId) async {
    final creds = await keyStore.readExchangeCredentials(exchangeId);
    return creds != null && creds.isComplete;
  }

  /// Saves exchange credentials to secure storage.
  Future<void> saveCredentials(ExchangeCredentials creds) async {
    await keyStore.writeExchangeCredentials(creds);
  }

  /// Deletes exchange credentials from secure storage.
  Future<void> deleteCredentials(String exchangeId) async {
    await keyStore.deleteExchangeCredentials(exchangeId);
  }

  /// Returns the set of exchange IDs that have valid trading credentials.
  Future<Set<String>> connectedTradingExchanges() async {
    final all = await keyStore.connectedExchangeIds();
    final valid = <String>{};
    for (final id in all) {
      final creds = await keyStore.readExchangeCredentials(id);
      if (creds != null && creds.isComplete && _client(id) != null) {
        valid.add(id);
      }
    }
    return valid;
  }
}