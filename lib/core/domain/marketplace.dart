import 'package:equatable/equatable.dart';
import '../domain/enums.dart';

/// A strategy listed on the marketplace. See PRD §12 (v3.0 — Strategy
/// marketplace). Users can browse, preview (backtest), and install strategies
/// created by the community.
class MarketplaceStrategy extends Equatable {
  final String id;
  final String name;
  final String author;
  final String description;
  final StrategyType type;
  final ExecutionMode defaultMode;
  final double avgRating; // 0..5
  final int installCount;
  final double backtestWinRate; // 0..1
  final double backtestPnl;
  final int backtestTrades;
  final List<String> tags;

  const MarketplaceStrategy({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
    required this.type,
    this.defaultMode = ExecutionMode.manual,
    required this.avgRating,
    required this.installCount,
    required this.backtestWinRate,
    required this.backtestPnl,
    required this.backtestTrades,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [id];
}

/// Static catalog of marketplace strategies. In a full implementation this
/// would be fetched from a backend; for v3.0 we ship a curated set.
class MarketplaceCatalog {
  MarketplaceCatalog._();

  static const List<MarketplaceStrategy> all = [
    MarketplaceStrategy(
      id: 'mkt_btc_grid',
      name: 'BTC Grid Scout',
      author: 'ArbMaster',
      description: 'Scans BTC/USDT across 5 exchanges for tight spreads. Conservative thresholds, high win rate.',
      type: StrategyType.simpleCrossExchange,
      defaultMode: ExecutionMode.semiAuto,
      avgRating: 4.6,
      installCount: 1240,
      backtestWinRate: 0.72,
      backtestPnl: 480.50,
      backtestTrades: 156,
      tags: ['BTC', 'conservative', 'high-frequency'],
    ),
    MarketplaceStrategy(
      id: 'mkt_tri_eth',
      name: 'ETH Triangular Pro',
      author: 'TriangularPro',
      description: 'Triangular arbitrage on ETH/BTC/USDT within Binance. Optimized for 0.1%+ inefficiencies.',
      type: StrategyType.triangular,
      defaultMode: ExecutionMode.autonomous,
      avgRating: 4.2,
      installCount: 890,
      backtestWinRate: 0.64,
      backtestPnl: 310.20,
      backtestTrades: 240,
      tags: ['ETH', 'triangular', 'binance'],
    ),
    MarketplaceStrategy(
      id: 'mkt_sol_dexcex',
      name: 'Solana DEX-CEX Bridge',
      author: 'CrossChainChad',
      description: 'Buys SOL on Jupiter DEX, sells on Binance. Factors in Wormhole bridge cost and latency.',
      type: StrategyType.dexCex,
      defaultMode: ExecutionMode.semiAuto,
      avgRating: 4.0,
      installCount: 560,
      backtestWinRate: 0.58,
      backtestPnl: 220.80,
      backtestTrades: 78,
      tags: ['SOL', 'DEX-CEX', 'bridge'],
    ),
    MarketplaceStrategy(
      id: 'mkt_stat_pairs',
      name: 'Statistical Pairs ETH/BTC',
      author: 'QuantKid',
      description: 'Mean-reversion on ETH/BTC ratio. Enters when deviation exceeds 2-sigma, exits at mean.',
      type: StrategyType.statistical,
      defaultMode: ExecutionMode.manual,
      avgRating: 4.4,
      installCount: 420,
      backtestWinRate: 0.68,
      backtestPnl: 195.40,
      backtestTrades: 42,
      tags: ['statistical', 'mean-reversion', 'pairs'],
    ),
    MarketplaceStrategy(
      id: 'mkt_flash_eth',
      name: 'Flash Loan Atomic',
      author: 'FlashLoaner',
      description: 'On-chain atomic arbitrage using Aave flash loans on Ethereum. No capital required.',
      type: StrategyType.flashLoan,
      defaultMode: ExecutionMode.autonomous,
      avgRating: 3.8,
      installCount: 310,
      backtestWinRate: 0.52,
      backtestPnl: 540.00,
      backtestTrades: 28,
      tags: ['flash-loan', 'ethereum', 'atomic', 'high-risk'],
    ),
    MarketplaceStrategy(
      id: 'mkt_alt_sweep',
      name: 'Altcoin Sweep',
      author: 'SpreadHunter',
      description: 'Sweeps 10+ altcoin pairs across all enabled CEXs. Wider spreads, higher slippage risk.',
      type: StrategyType.simpleCrossExchange,
      defaultMode: ExecutionMode.semiAuto,
      avgRating: 3.9,
      installCount: 680,
      backtestWinRate: 0.61,
      backtestPnl: 285.30,
      backtestTrades: 320,
      tags: ['altcoins', 'aggressive', 'multi-pair'],
    ),
  ];
}