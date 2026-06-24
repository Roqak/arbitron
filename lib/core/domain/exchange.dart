import 'package:equatable/equatable.dart';

/// A supported CEX or DEX. See PRD §4. For MVP, [connected] reflects the
/// user's configured state; API credentials live in secure storage, not here.
class Exchange extends Equatable {
  final String id;
  final String name;
  final ExchangeKind kind;
  final String region;
  final double makerFee;
  final double takerFee;
  final bool enabled;

  const Exchange({
    required this.id,
    required this.name,
    required this.kind,
    required this.region,
    required this.makerFee,
    required this.takerFee,
    this.enabled = false,
  });

  Exchange copyWith({bool? enabled}) => Exchange(
        id: id,
        name: name,
        kind: kind,
        region: region,
        makerFee: makerFee,
        takerFee: takerFee,
        enabled: enabled ?? this.enabled,
      );

  @override
  List<Object?> get props => [id, name, kind, region, makerFee, takerFee, enabled];
}

enum ExchangeKind { cex, dex }

extension ExchangeKindX on ExchangeKind {
  String get label => this == ExchangeKind.cex ? 'CEX' : 'DEX';
}

/// Static catalog of exchanges. The user toggles [enabled] in settings; the
/// configured set is persisted in HydratedBloc state.
class ExchangeCatalog {
  ExchangeCatalog._();

  static const List<Exchange> all = [
    // ── CEX ───────────────────────────────────────────────────────────────
    Exchange(id: 'binance', name: 'Binance', kind: ExchangeKind.cex, region: 'Global', makerFee: 0.0010, takerFee: 0.0010),
    Exchange(id: 'coinbase', name: 'Coinbase Advanced', kind: ExchangeKind.cex, region: 'US/EU', makerFee: 0.0000, takerFee: 0.0040),
    Exchange(id: 'kraken', name: 'Kraken', kind: ExchangeKind.cex, region: 'EU/US', makerFee: 0.0016, takerFee: 0.0026),
    Exchange(id: 'okx', name: 'OKX', kind: ExchangeKind.cex, region: 'Global', makerFee: 0.0008, takerFee: 0.0010),
    Exchange(id: 'bybit', name: 'Bybit', kind: ExchangeKind.cex, region: 'Global', makerFee: 0.0001, takerFee: 0.0010),
    Exchange(id: 'kucoin', name: 'KuCoin', kind: ExchangeKind.cex, region: 'Global', makerFee: 0.0010, takerFee: 0.0010),
    Exchange(id: 'gate', name: 'Gate.io', kind: ExchangeKind.cex, region: 'Global', makerFee: 0.0020, takerFee: 0.0020),
    Exchange(id: 'bitfinex', name: 'Bitfinex', kind: ExchangeKind.cex, region: 'Global', makerFee: 0.0010, takerFee: 0.0020),
    Exchange(id: 'huobi', name: 'Huobi / HTX', kind: ExchangeKind.cex, region: 'Asia', makerFee: 0.0020, takerFee: 0.0020),
    Exchange(id: 'mexc', name: 'MEXC', kind: ExchangeKind.cex, region: 'Global', makerFee: 0.0000, takerFee: 0.0005),
    // ── DEX ───────────────────────────────────────────────────────────────
    Exchange(id: 'uniswap', name: 'Uniswap v3/v4', kind: ExchangeKind.dex, region: 'Ethereum/L2s', makerFee: 0.0050, takerFee: 0.0050),
    Exchange(id: 'pancakeswap', name: 'PancakeSwap', kind: ExchangeKind.dex, region: 'BNB Chain', makerFee: 0.0025, takerFee: 0.0025),
    Exchange(id: 'curve', name: 'Curve Finance', kind: ExchangeKind.dex, region: 'Multi', makerFee: 0.0004, takerFee: 0.0004),
    Exchange(id: 'dydx', name: 'dYdX v4', kind: ExchangeKind.dex, region: 'Cosmos', makerFee: 0.0005, takerFee: 0.0020),
    Exchange(id: 'raydium', name: 'Raydium', kind: ExchangeKind.dex, region: 'Solana', makerFee: 0.0025, takerFee: 0.0025),
    Exchange(id: 'jupiter', name: 'Jupiter Aggregator', kind: ExchangeKind.dex, region: 'Solana', makerFee: 0.0010, takerFee: 0.0010),
    Exchange(id: 'velodrome', name: 'Velodrome', kind: ExchangeKind.dex, region: 'Optimism', makerFee: 0.0005, takerFee: 0.0005),
    Exchange(id: 'aerodrome', name: 'Aerodrome', kind: ExchangeKind.dex, region: 'Base', makerFee: 0.0005, takerFee: 0.0005),
    Exchange(id: 'orca', name: 'Orca', kind: ExchangeKind.dex, region: 'Solana', makerFee: 0.0030, takerFee: 0.0030),
    Exchange(id: 'sushiswap', name: 'SushiSwap', kind: ExchangeKind.dex, region: 'Multi', makerFee: 0.0030, takerFee: 0.0030),
  ];

  static Exchange byId(String id) => all.firstWhere((e) => e.id == id);
}