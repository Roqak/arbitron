import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_spacing.dart';
import 'core/app_cubit.dart';
import 'core/widgets/kill_switch_fab.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/opportunities/opportunities_screen.dart';
import 'features/strategies/strategies_screen.dart';
import 'features/history/history_screen.dart';
import 'features/settings/settings_screen.dart';

/// Top-level scaffold with the bottom navigation and the floating Kill Switch.
/// See PRD §9 (screen map).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.show_chart_outlined), selectedIcon: Icon(Icons.show_chart), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Opportunities'),
    NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'Strategies'),
    NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
  ];

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
      floatingActionButton: KillSwitchFab(
        autonomousActive: autonomous,
        onPause: () => _confirmPauseAutonomous(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.borderSubtle, width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: _destinations,
          height: 64 + MediaQuery.paddingOf(context).bottom,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
    );
  }

  void _confirmPauseAutonomous(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.borderStrong, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Icon(Icons.pause_circle, color: theme.danger, size: 28),
                    const SizedBox(width: AppSpacing.md),
                    Text('Pause all autonomous strategies?',
                        style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'This immediately halts all autonomous execution and cancels any pending LLM decisions. '
                  'You can resume autonomous mode per strategy from the Strategies screen.',
                  style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(sheetCtx), child: const Text('Cancel'))),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: theme.danger, foregroundColor: theme.background),
                        onPressed: () {
                          sheetCtx.read<AppCubit>().pauseAllAutonomous();
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Autonomous execution paused'), duration: const Duration(seconds: 2)),
                          );
                        },
                        child: const Text('Pause all'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}