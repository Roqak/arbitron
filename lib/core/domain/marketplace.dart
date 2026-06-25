import 'package:equatable/equatable.dart';
import '../domain/enums.dart';

/// A strategy listed on the marketplace. See PRD §12 (v3.0 — Strategy
/// marketplace). Without a backend, the marketplace is empty — strategies
/// would be fetched from a community server in a full implementation.
class MarketplaceStrategy extends Equatable {
  final String id;
  final String name;
  final String author;
  final String description;
  final StrategyType type;
  final ExecutionMode defaultMode;
  final double avgRating;
  final int installCount;
  final double backtestWinRate;
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

/// Marketplace catalog. Empty until a backend provides community strategies.
class MarketplaceCatalog {
  MarketplaceCatalog._();

  static const List<MarketplaceStrategy> all = [];
}