import 'package:equatable/equatable.dart';

/// A single entry on the social leaderboard. See PRD §12 (v3.0 — Social
/// leaderboard, opt-in). Users who opt in are ranked by risk-adjusted P&L.
class LeaderboardEntry extends Equatable {
  final String userId;
  final String displayName;
  final String? avatarSeed; // for generated avatar
  final double totalPnl;
  final double winRate; // 0..1
  final int totalTrades;
  final double sharpeRatio;
  final int rank;
  final bool isYou;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarSeed,
    required this.totalPnl,
    required this.winRate,
    required this.totalTrades,
    required this.sharpeRatio,
    required this.rank,
    this.isYou = false,
  });

  /// Risk-adjusted score used for ranking: P&L * win_rate * sharpe (simplified).
  double get score => totalPnl * winRate * (sharpeRatio.abs() + 0.5);

  @override
  List<Object?> get props => [userId, rank];
}

/// Social leaderboard service. In a full implementation this would sync with a
/// backend; for v3.0 we generate a deterministic peer set and insert the user's
/// actual stats when opted in. No personal data leaves the device unless the
/// user explicitly opts in.
class LeaderboardService {
  LeaderboardService._();

  /// Generates the leaderboard with the user's entry inserted at their rank.
  /// [userPnl], [userWinRate], [userTrades], [userSharpe] come from app state.
  static List<LeaderboardEntry> generate({
    required double userPnl,
    required double userWinRate,
    required int userTrades,
    required double userSharpe,
    required bool optedIn,
  }) {
    final peers = _generatePeers();
    final entries = <LeaderboardEntry>[];

    if (optedIn) {
      entries.add(LeaderboardEntry(
        userId: 'you',
        displayName: 'You',
        totalPnl: userPnl,
        winRate: userWinRate,
        totalTrades: userTrades,
        sharpeRatio: userSharpe,
        rank: 0,
        isYou: true,
      ));
    }

    entries.addAll(peers);
    // Sort by score descending.
    entries.sort((a, b) => b.score.compareTo(a.score));
    // Assign ranks.
    final ranked = entries.asMap().entries.map((e) => LeaderboardEntry(
      userId: e.value.userId,
      displayName: e.value.displayName,
      avatarSeed: e.value.avatarSeed,
      totalPnl: e.value.totalPnl,
      winRate: e.value.winRate,
      totalTrades: e.value.totalTrades,
      sharpeRatio: e.value.sharpeRatio,
      rank: e.key + 1,
      isYou: e.value.isYou,
    )).toList();
    return ranked;
  }

  static List<LeaderboardEntry> _generatePeers() {
    final names = [
      'ArbMaster', 'SpreadHunter', 'FlashLoaner', 'TriangularPro',
      'DeltaNeutral', 'MEVSearcher', 'CrossChainChad', 'YieldFarmer',
      'StatArbDev', 'QuantKid', 'BridgeBuilder', 'VolTrader',
    ];
    final entries = <LeaderboardEntry>[];
    for (int i = 0; i < names.length; i++) {
      final seed = names[i].hashCode;
      entries.add(LeaderboardEntry(
        userId: 'peer_$i',
        displayName: names[i],
        avatarSeed: names[i],
        totalPnl: 50 + (seed % 800).toDouble() + (seed % 100) * 0.1,
        winRate: 0.45 + (seed % 30) / 100,
        totalTrades: 20 + (seed % 200),
        sharpeRatio: 0.5 + (seed % 25) / 10,
        rank: 0,
      ));
    }
    return entries;
  }
}