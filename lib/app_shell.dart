import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_typography.dart';
import 'core/app_cubit.dart';
import 'core/widgets/kill_switch_bar.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/opportunities/opportunities_screen.dart';
import 'features/strategies/strategies_screen.dart';
import 'features/history/history_screen.dart';
import 'features/settings/settings_screen.dart';

/// Terminal-native app shell. Bottom nav with mono labels, kill switch bar
/// above it when autonomous is active.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    OpportunitiesScreen(),
    StrategiesScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final autonomous = context.select((AppCubit c) => c.state.anyAutonomousActive);

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KillSwitchBar(autonomousActive: autonomous, onPause: () => _confirmPause(context)),
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.borderSubtle, width: 1))),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              indicatorColor: Colors.transparent,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                NavigationDestination(icon: Icon(Icons.show_chart_outlined), selectedIcon: Icon(Icons.show_chart), label: 'DASH'),
                NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'OPPS'),
                NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'STRAT'),
                NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'HIST'),
                NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'SETUP'),
              ],
              height: 56 + MediaQuery.paddingOf(context).bottom,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPause(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.borderStrong, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: AppSpacing.lg),
                Row(children: [
                  Icon(Icons.stop_circle, color: theme.danger, size: 24),
                  const SizedBox(width: AppSpacing.md),
                  Text('PAUSE ALL AUTONOMOUS', style: AppTypography.mono(size: 14, weight: FontWeight.w700, color: theme.textPrimary)),
                ]),
                const SizedBox(height: AppSpacing.md),
                Text('Halts all autonomous execution immediately and cancels pending LLM decisions. Resume per strategy from Strategies.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.textSecondary, height: 1.5)),
                const SizedBox(height: AppSpacing.xl),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: theme.danger, foregroundColor: theme.bg), onPressed: () { ctx.read<AppCubit>().pauseAllAutonomous(); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Autonomous execution halted'), duration: Duration(seconds: 2))); }, child: const Text('Pause all'))),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}