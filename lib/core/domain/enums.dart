/// Execution modes for a strategy. See PRD §6.
enum ExecutionMode {
  manual,
  semiAuto,
  autonomous;

  String get label {
    switch (this) {
      case ExecutionMode.manual:
        return 'Manual';
      case ExecutionMode.semiAuto:
        return 'Semi-Auto';
      case ExecutionMode.autonomous:
        return 'Autonomous';
    }
  }

  String get description {
    switch (this) {
      case ExecutionMode.manual:
        return 'You approve every trade.';
      case ExecutionMode.semiAuto:
        return 'AI proposes, you confirm within a countdown.';
      case ExecutionMode.autonomous:
        return 'AI executes within your risk limits.';
    }
  }
}

/// Strategy lifecycle state.
enum StrategyStatus { active, paused, disabled }

extension StrategyStatusX on StrategyStatus {
  String get label {
    switch (this) {
      case StrategyStatus.active:
        return 'Active';
      case StrategyStatus.paused:
        return 'Paused';
      case StrategyStatus.disabled:
        return 'Disabled';
    }
  }
}

/// The five arbitrage strategies supported by the platform. See PRD §5.1.
enum StrategyType {
  simpleCrossExchange,
  triangular,
  dexCex,
  statistical,
  flashLoan;

  String get label {
    switch (this) {
      case StrategyType.simpleCrossExchange:
        return 'Simple Cross-Exchange';
      case StrategyType.triangular:
        return 'Triangular';
      case StrategyType.dexCex:
        return 'DEX-CEX';
      case StrategyType.statistical:
        return 'Statistical / Pairs';
      case StrategyType.flashLoan:
        return 'Flash Loan';
    }
  }

  String get description {
    switch (this) {
      case StrategyType.simpleCrossExchange:
        return 'Buy on one exchange, sell on another for the same asset.';
      case StrategyType.triangular:
        return 'Exploit rate inefficiencies across three pairs on one exchange.';
      case StrategyType.dexCex:
        return 'Price gap between a DEX pool and a centralized order book.';
      case StrategyType.statistical:
        return 'Mean-reversion on historically correlated asset pairs.';
      case StrategyType.flashLoan:
        return 'DeFi on-chain atomic arbitrage using flash loans.';
    }
  }
}

/// Aggressiveness tuning for the LLM risk scoring. See PRD §5.2.
enum Aggressiveness { conservative, balanced, aggressive }

extension AggressivenessX on Aggressiveness {
  String get label => name[0].toUpperCase() + name.substring(1);
}