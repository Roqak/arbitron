import 'dart:async';
import '../domain/ticker.dart';
import '../domain/opportunity.dart';
import '../domain/exchange.dart';
import '../domain/enums.dart';
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
    final netProfit = grossProfit - feesUsd - slippageUsd;
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
      analysisText: _generateAnalysis(pair, buyEx.name, sellEx.name, grossSpreadPct, netProfit, score),
      isLive: true,
    );
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

  String _generateAnalysis(String pair, String buyName, String sellName, double spread, double netProfit, int score) {
    final verdict = score >= 75 ? 'a strong candidate' : score >= 50 ? 'worth monitoring' : 'marginal after costs';
    return 'Live spread on $pair: buy on $buyName (lowest ask), sell on $sellName (highest bid). '
        'Gross spread ${spread.toStringAsFixed(2)}%. Net of fees and slippage the opportunity is $verdict for execution.';
  }

  void dispose() {
    stop();
    _controller.close();
  }
}