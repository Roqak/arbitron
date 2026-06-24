import 'package:equatable/equatable.dart';

/// A cross-chain bridge route. See PRD §12 (v2.5 — Cross-chain bridge
/// integrations). Used to factor bridge latency + cost into DEX-CEX
/// arbitrage opportunities.
class BridgeRoute extends Equatable {
  final String id;
  final String name;
  final String sourceChain;
  final String destChain;
  final double feeUsd; // fixed bridge fee
  final double feePct; // percentage of transferred amount
  final Duration estimatedTime; // typical bridge latency
  final double successRate; // 0..1

  const BridgeRoute({
    required this.id,
    required this.name,
    required this.sourceChain,
    required this.destChain,
    required this.feeUsd,
    required this.feePct,
    required this.estimatedTime,
    this.successRate = 0.98,
  });

  /// Total bridge cost for a given transfer amount.
  double costFor(double amountUsd) => feeUsd + amountUsd * feePct;

  /// Whether this route connects [from] to [to].
  bool connects(String from, String to) =>
      (sourceChain == from && destChain == to) ||
      (sourceChain == to && destChain == from);

  @override
  List<Object?> get props => [id, sourceChain, destChain];
}

/// Catalog of supported bridge routes. Static for v2.5; in v3.0+ these could
/// be fetched from a bridge aggregator API.
class BridgeCatalog {
  BridgeCatalog._();

  static const List<BridgeRoute> all = [
    BridgeRoute(id: 'hop_eth_op', name: 'Hop Protocol', sourceChain: 'Ethereum', destChain: 'Optimism', feeUsd: 2.50, feePct: 0.001, estimatedTime: Duration(minutes: 5)),
    BridgeRoute(id: 'hop_eth_base', name: 'Hop Protocol', sourceChain: 'Ethereum', destChain: 'Base', feeUsd: 2.50, feePct: 0.001, estimatedTime: Duration(minutes: 5)),
    BridgeRoute(id: 'across_eth_op', name: 'Across', sourceChain: 'Ethereum', destChain: 'Optimism', feeUsd: 1.80, feePct: 0.0008, estimatedTime: Duration(minutes: 4)),
    BridgeRoute(id: 'across_eth_base', name: 'Across', sourceChain: 'Ethereum', destChain: 'Base', feeUsd: 1.80, feePct: 0.0008, estimatedTime: Duration(minutes: 4)),
    BridgeRoute(id: 'celer_eth_bnb', name: 'Celer cBridge', sourceChain: 'Ethereum', destChain: 'BNB Chain', feeUsd: 3.20, feePct: 0.0015, estimatedTime: Duration(minutes: 10)),
    BridgeRoute(id: 'celer_op_base', name: 'Celer cBridge', sourceChain: 'Optimism', destChain: 'Base', feeUsd: 1.20, feePct: 0.0005, estimatedTime: Duration(minutes: 3)),
    BridgeRoute(id: 'wormhole_sol_eth', name: 'Wormhole', sourceChain: 'Solana', destChain: 'Ethereum', feeUsd: 5.00, feePct: 0.002, estimatedTime: Duration(minutes: 15)),
    BridgeRoute(id: 'wormhole_sol_bnb', name: 'Wormhole', sourceChain: 'Solana', destChain: 'BNB Chain', feeUsd: 4.50, feePct: 0.002, estimatedTime: Duration(minutes: 12)),
    BridgeRoute(id: 'debridge_sol_eth', name: 'deBridge', sourceChain: 'Solana', destChain: 'Ethereum', feeUsd: 4.00, feePct: 0.0018, estimatedTime: Duration(minutes: 8)),
    BridgeRoute(id: 'stargate_eth_bnb', name: 'Stargate', sourceChain: 'Ethereum', destChain: 'BNB Chain', feeUsd: 2.80, feePct: 0.0012, estimatedTime: Duration(minutes: 6)),
  ];

  /// Finds the cheapest bridge route between [from] and [to] chains.
  /// Returns null if no direct route exists.
  static BridgeRoute? cheapest(String from, String to, {double amountUsd = 1000}) {
    final routes = all.where((r) => r.connects(from, to)).toList();
    if (routes.isEmpty) return null;
    routes.sort((a, b) => a.costFor(amountUsd).compareTo(b.costFor(amountUsd)));
    return routes.first;
  }

  /// All routes between [from] and [to], sorted by cost.
  static List<BridgeRoute> routes(String from, String to, {double amountUsd = 1000}) {
    final routes = all.where((r) => r.connects(from, to)).toList();
    routes.sort((a, b) => a.costFor(amountUsd).compareTo(b.costFor(amountUsd)));
    return routes;
  }
}