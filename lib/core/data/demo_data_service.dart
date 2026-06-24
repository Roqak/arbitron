import '../domain/opportunity.dart';
import '../domain/strategy.dart';
import '../domain/trade.dart';
import '../domain/exchange.dart';
import '../domain/enums.dart';
import '../utils/rng.dart';

/// Generates deterministic demo data for the MVP. In v1.5+ this is replaced by
/// live exchange feeds + the LLM analysis pipeline. All data is seeded so the
/// app looks consistent across launches.
class DemoDataService {
  DemoDataService._();

  static final List<String> _pairs = [
    'BTC/USDT', 'ETH/USDT', 'SOL/USDT', 'BNB/USDT', 'XRP/USDT',
    'ADA/USDT', 'DOGE/USDT', 'AVAX/USDT', 'LINK/USDT', 'MATIC/USDT',
  ];

  static final List<String> _cexIds = ['binance', 'coinbase', 'kraken', 'okx', 'bybit'];

  static Opportunity _makeOpportunity({
    required int i,
    required StrategyType strategy,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final pair = Rng.pick(_pairs);
    final buyEx = Rng.pick(_cexIds);
    var sellEx = Rng.pick(_cexIds);
    while (sellEx == buyEx) sellEx = Rng.pick(_cexIds);

    final basePrice = switch (pair.split('/').first) {
      'BTC' => 64000.0,
      'ETH' => 3200.0,
      'SOL' => 145.0,
      'BNB' => 580.0,
      'XRP' => 0.52,
      'ADA' => 0.45,
      'DOGE' => 0.13,
      'AVAX' => 35.0,
      'LINK' => 14.0,
      _ => 1.0,
    };
    final spreadPct = Rng.nextDouble(min: 0.08, max: 1.4);
    final buyPrice = basePrice * (1 - spreadPct / 200);
    final sellPrice = basePrice * (1 + spreadPct / 200);
    final sizeUsd = Rng.nextDouble(min: 200, max: 4000);
    final feesUsd = sizeUsd * 0.0015;
    final slippageUsd = sizeUsd * Rng.nextDouble(min: 0.0005, max: 0.003);
    final grossProfit = (sellPrice - buyPrice) * (sizeUsd / basePrice);
    final netProfit = grossProfit - feesUsd - slippageUsd;
    final score = Rng.nextInt(min: 35, max: 98);

    final analysis = _analysisFor(pair, buyEx, sellEx, netProfit, score, strategy);

    return Opportunity(
      id: 'opp_${i}_${t.millisecondsSinceEpoch}',
      pair: pair,
      buyExchangeId: buyEx,
      sellExchangeId: sellEx,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      grossSpreadPct: spreadPct,
      estFeesUsd: feesUsd,
      estSlippageUsd: slippageUsd,
      netProfitUsd: netProfit,
      netProfitPct: (netProfit / sizeUsd) * 100,
      confidenceScore: score,
      strategy: strategy,
      detectedAt: t.subtract(Duration(seconds: Rng.nextInt(min: 1, max: 600))),
      analysisText: analysis,
      isLive: true,
    );
  }

  static String _analysisFor(String pair, String buy, String sell, double profit, int score, StrategyType s) {
    final profitable = profit >= 0;
    final tone = profitable ? 'healthy' : 'thin';
    final verdict = score >= 75 ? 'a strong candidate' : score >= 50 ? 'worth monitoring' : 'marginal';
    return 'Spread on $pair between ${ExchangeCatalog.byId(buy).name} and ${ExchangeCatalog.byId(sell).name} is within the 30-day median range. '
        '${ExchangeCatalog.byId(sell).name} liquidity is $tone at this size. Net of fees and slippage the opportunity is $verdict for execution.';
  }

  /// Generates a batch of `count` live opportunities.
  static List<Opportunity> opportunities({int count = 12, DateTime? now}) {
    return List.generate(count, (i) => _makeOpportunity(i: i, strategy: Rng.pick(StrategyType.values), now: now))
      ..sort((a, b) => b.netProfitUsd.compareTo(a.netProfitUsd));
  }

  /// Generates the default set of strategies shipped with the app.
  static List<Strategy> defaultStrategies() {
    return [
      Strategy(
        id: 'strat_simple_1',
        name: 'Simple Cross-Exchange',
        type: StrategyType.simpleCrossExchange,
        enabled: true,
        mode: ExecutionMode.manual,
        minProfitUsd: 15,
        maxTradeUsd: 2000,
        allowedExchangeIds: _cexIds,
        totalTrades: 14,
        winRate: 0.71,
        totalPnl: 210.40,
      ),
      Strategy(
        id: 'strat_tri_1',
        name: 'Triangular — BTC/ETH/USDT',
        type: StrategyType.triangular,
        enabled: true,
        mode: ExecutionMode.semiAuto,
        minProfitUsd: 8,
        maxTradeUsd: 1500,
        allowedExchangeIds: ['binance'],
        totalTrades: 32,
        winRate: 0.66,
        totalPnl: 184.10,
      ),
      Strategy(
        id: 'strat_dexcex_1',
        name: 'DEX-CEX ETH',
        type: StrategyType.dexCex,
        enabled: false,
        mode: ExecutionMode.autonomous,
        minProfitUsd: 25,
        maxTradeUsd: 3000,
        allowedExchangeIds: ['uniswap', 'binance'],
        totalTrades: 0,
        winRate: 0,
        totalPnl: 0,
      ),
    ];
  }

  /// Generates a realistic trade history.
  static List<TradeRecord> tradeHistory({int count = 18}) {
    final strategies = defaultStrategies();
    final out = <TradeRecord>[];
    for (int i = 0; i < count; i++) {
      final strat = Rng.pick(strategies);
      final pair = Rng.pick(_pairs);
      final buyEx = Rng.pick(_cexIds);
      var sellEx = Rng.pick(_cexIds);
      while (sellEx == buyEx) sellEx = Rng.pick(_cexIds);
      final sizeUsd = Rng.nextDouble(min: 200, max: 3000);
      final win = Rng.nextBool(trueChance: 0.68);
      final grossPnl = win ? Rng.nextDouble(min: 5, max: 80) : -Rng.nextDouble(min: 5, max: 40);
      final fees = sizeUsd * 0.0015;
      final slippage = sizeUsd * 0.001;
      final netPnl = grossPnl - fees - slippage;
      final basePrice = switch (pair.split('/').first) {
        'BTC' => 64000.0, 'ETH' => 3200.0, 'SOL' => 145.0, 'BNB' => 580.0,
        'XRP' => 0.52, 'ADA' => 0.45, 'DOGE' => 0.13, 'AVAX' => 35.0,
        'LINK' => 14.0, _ => 1.0,
      };
      out.add(TradeRecord(
        id: 'trade_$i',
        executedAt: DateTime.now().subtract(Duration(hours: i * 5 + Rng.nextInt(min: 0, max: 4))),
        strategyId: strat.id,
        strategyName: strat.name,
        strategyType: strat.type,
        pair: pair,
        buyExchangeId: buyEx,
        sellExchangeId: sellEx,
        sizeUsd: sizeUsd,
        entryPrice: basePrice,
        exitPrice: basePrice + grossPnl / (sizeUsd / basePrice),
        grossPnl: grossPnl,
        netPnl: netPnl,
        feesUsd: fees,
        slippageUsd: slippage,
        mode: strat.mode,
        profit: netPnl >= 0,
        debrief: win
            ? 'Trade captured the full spread with slippage within expectations. Liquidity held through execution.'
            : 'Slippage exceeded estimate by ${(slippage / sizeUsd * 100).toStringAsFixed(2)}% and eroded the edge.',
      ));
    }
    return out..sort((a, b) => b.executedAt.compareTo(a.executedAt));
  }

  /// Top ticker entries for the dashboard strip.
  static List<({String pair, double netPct})> ticker() {
    final opps = opportunities(count: 5);
    return opps.map((o) => (pair: o.pair, netPct: o.netProfitPct)).toList();
  }
}