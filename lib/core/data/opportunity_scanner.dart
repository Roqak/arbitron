import 'dart:async';
import '../domain/ticker.dart';
import '../domain/opportunity.dart';
import '../domain/exchange.dart';
import '../domain/enums.dart';
import '../domain/bridge.dart';
import 'price_feed_service.dart';

/// Scans live price snapshots for cross-exchange arbitrage opportunities.
/// For each pair, finds the exchange with the lowest ask (best buy) and the
/// exchange with the highest bid (best sell) and computes the net profit after
/// fees and estimated slippage. See PRD §5.1 (Simple Cross-Exchange) and §11.1.
class OpportunityScanner {
  OpportunityScanner({required this.priceFeedService, this.defaultTradeSizeUsd = 1000});

  final PriceFeedService priceFeedService;
  final double defaultTradeSizeUsd;

  StreamSubscription<PriceSnapshot>? _sub;
  final _controller = StreamController<List<Opportunity>>.broadcast();

  /// Emits a fresh batch of opportunities whenever prices update.
  Stream<List<Opportunity>> get opportunities => _controller.stream;

  void start() {
    _sub ??= priceFeedService.snapshots.listen(_scan);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void _scan(PriceSnapshot snapshot) {
    final out = <Opportunity>[];
    for (final pair in snapshot.pairs) {
      final opp = _scanPair(pair, snapshot.forPair(pair));
      if (opp != null) out.add(opp);
    }
    out.sort((a, b) => b.netProfitUsd.compareTo(a.netProfitUsd));
    if (!_controller.isClosed) _controller.add(out);
  }

  /// Compute the best cross-exchange opportunity for a single pair.
  Opportunity? _scanPair(String pair, List<Ticker> tickers) {
    if (tickers.length < 2) return null;

    // Only consider fresh quotes.
    final fresh = tickers.where((t) => t.isFresh).toList();
    if (fresh.length < 2) return null;

    // Best buy = lowest ask. Best sell = highest bid. Must be different exchanges.
    final sortedByAsk = List<Ticker>.from(fresh)..sort((a, b) => a.ask.compareTo(b.ask));
    final sortedByBid = List<Ticker>.from(fresh)..sort((a, b) => b.bid.compareTo(a.bid));

    Ticker? buy;
    Ticker? sell;
    // Find the best non-overlapping pair.
    for (final b in sortedByAsk) {
      for (final s in sortedByBid) {
        if (b.exchangeId != s.exchangeId && s.bid > b.ask) {
          buy = b;
          sell = s;
          break;
        }
      }
      if (buy != null) break;
    }
    if (buy == null || sell == null) return null;

    final buyEx = ExchangeCatalog.byId(buy.exchangeId);
    final sellEx = ExchangeCatalog.byId(sell.exchangeId);

    final buyPrice = buy.ask;
    final sellPrice = sell.bid;
    final grossSpreadPct = buyPrice > 0 ? ((sellPrice - buyPrice) / buyPrice) * 100 : 0.0;

    // Size the trade.
    final sizeUsd = defaultTradeSizeUsd;
    final qty = buyPrice > 0 ? sizeUsd / buyPrice : 0;

    // Fees: taker fee on both legs (we're taking liquidity).
    final feesUsd = sizeUsd * buyEx.takerFee + (qty * sellPrice) * sellEx.takerFee;

    // Estimated slippage: assume 0.1% of each leg as conservative estimate.
    final slippageUsd = sizeUsd * 0.001 + (qty * sellPrice) * 0.001;

    final grossProfit = (sellPrice - buyPrice) * qty;
    // Cross-chain bridge cost (v2.5): if buy and sell exchanges are on
    // different chains, factor in the cheapest bridge route.
    String? bridgeName;
    double? bridgeCostUsd;
    Duration? bridgeTime;
    var netProfit = grossProfit - feesUsd - slippageUsd;
    final bridge = _maybeBridge(buyEx, sellEx, sizeUsd);
    if (bridge != null) {
      bridgeName = bridge.name;
      bridgeCostUsd = bridge.costFor(sizeUsd);
      bridgeTime = bridge.estimatedTime;
      netProfit -= bridgeCostUsd;
    }
    final netProfitPct = sizeUsd > 0 ? (netProfit / sizeUsd) * 100 : 0.0;

    // Confidence score: higher spread and more exchanges quoting = higher score.
    final score = _scoreOpportunity(grossSpreadPct, fresh.length, netProfit);

    return Opportunity(
      id: 'live_${pair.replaceAll('/', '_')}_${buy.exchangeId}_${sell.exchangeId}',
      pair: pair,
      buyExchangeId: buy.exchangeId,
      sellExchangeId: sell.exchangeId,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      grossSpreadPct: grossSpreadPct,
      estFeesUsd: feesUsd,
      estSlippageUsd: slippageUsd,
      netProfitUsd: netProfit,
      netProfitPct: netProfitPct,
      confidenceScore: score,
      strategy: StrategyType.simpleCrossExchange,
      detectedAt: DateTime.now(),
      analysisText: _generateAnalysis(pair, buyEx.name, sellEx.name, grossSpreadPct, netProfit, score, bridgeName, bridgeTime),
      isLive: true,
      bridgeName: bridgeName,
      bridgeCostUsd: bridgeCostUsd,
      bridgeTime: bridgeTime,
    );
  }

  /// Returns the cheapest bridge route if the two exchanges are on different
  /// chains, else null. Uses the exchange's region field as a chain proxy.
  BridgeRoute? _maybeBridge(Exchange buyEx, Exchange sellEx, double sizeUsd) {
    if (buyEx.kind != ExchangeKind.dex && sellEx.kind != ExchangeKind.dex) return null;
    final fromChain = _chainOf(buyEx);
    final toChain = _chainOf(sellEx);
    if (fromChain == toChain) return null;
    return BridgeCatalog.cheapest(fromChain, toChain, amountUsd: sizeUsd);
  }

  /// Maps an exchange to its native chain (for DEX) or "Ethereum" (for CEX,
  /// since CEX deposits are assumed on the main chain).
  String _chainOf(Exchange e) {
    if (e.kind == ExchangeKind.cex) return 'Ethereum';
    return e.region.split('/').first.split(' ').first;
  }

  int _scoreOpportunity(double grossSpreadPct, int exchangeCount, double netProfit) {
    // Base score from spread magnitude.
    var score = 40 + (grossSpreadPct * 30).round();
    // Bonus for more exchanges confirming the price.
    if (exchangeCount >= 3) score += 10;
    if (exchangeCount >= 5) score += 10;
    // Penalty if net profit is negative.
    if (netProfit < 0) score -= 30;
    return score.clamp(0, 100);
  }

  String _generateAnalysis(String pair, String buyName, String sellName, double spread, double netProfit, int score, [String? bridgeName, Duration? bridgeTime]) {
    final verdict = score >= 75 ? 'a strong candidate' : score >= 50 ? 'worth monitoring' : 'marginal after costs';
    final bridgeNote = bridgeName != null && bridgeTime != null
        ? ' Requires $bridgeName bridge (~${bridgeTime.inMinutes}min).'
        : '';
    return 'Live spread on $pair: buy on $buyName (lowest ask), sell on $sellName (highest bid). '
        'Gross spread ${spread.toStringAsFixed(2)}%. Net of fees, slippage, and bridge costs the opportunity is $verdict for execution.$bridgeNote';
  }

  void dispose() {
    stop();
    _controller.close();
  }
}