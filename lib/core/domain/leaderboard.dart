import 'package:equatable/equatable.dart';

/// A single entry on the social leaderboard. See PRD §12 (v3.0 — Social
/// leaderboard, opt-in). Users who opt in are ranked by risk-adjusted P&L.
class LeaderboardEntry extends Equatable {
  final String userId;
  final String displayName;
  final String? avatarSeed;
  final double totalPnl;
  final double winRate;
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

  double get score => totalPnl * winRate * (sharpeRatio.abs() + 0.5);

  @override
  List<Object?> get props => [userId, rank];
}

/// Social leaderboard service. Without a backend, the leaderboard shows only
/// the user's own entry when opted in. A future backend would sync opted-in
/// stats across users.
class LeaderboardService {
  LeaderboardService._();

  /// Generates the leaderboard. Without a backend, only the user's entry
  /// appears when opted in. No fake peers are generated.
  static List<LeaderboardEntry> generate({
    required double userPnl,
    required double userWinRate,
    required int userTrades,
    required double userSharpe,
    required bool optedIn,
  }) {
    if (!optedIn) return const [];
    return [
      LeaderboardEntry(
        userId: 'you',
        displayName: 'You',
        totalPnl: userPnl,
        winRate: userWinRate,
        totalTrades: userTrades,
        sharpeRatio: userSharpe,
        rank: 1,
        isYou: true,
      ),
    ];
  }
}