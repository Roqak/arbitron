import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';

/// The global Kill Switch FAB. Persistent when any strategy is in Autonomous
/// mode. Tapping pauses autonomous execution. See DESIGN.md §5.7 and PRD §6.1.
class KillSwitchFab extends StatefulWidget {
  final bool autonomousActive;
  final VoidCallback onPause;

  const KillSwitchFab({super.key, required this.autonomousActive, required this.onPause});

  @override
  State<KillSwitchFab> createState() => _KillSwitchFabState();
}

class _KillSwitchFabState extends State<KillSwitchFab> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _pulseTimer;
  bool _pulseDim = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (mounted) setState(() => _pulseDim = !_pulseDim);
    });
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.autonomousActive) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, AppSpacing.lg, AppSpacing.lg),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = _pulse.value;
          return GestureDetector(
            onTap: widget.onPause,
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: theme.danger,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: theme.danger.withOpacity(0.25 + 0.2 * t), blurRadius: 12 + 8 * t, spreadRadius: 1),
                ],
              ),
              child: Icon(Icons.pause_rounded, color: theme.background, size: 28),
            ),
          );
        },
      ),
    );
  }
}