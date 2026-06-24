import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

class KillSwitchBar extends StatefulWidget {
  final bool autonomousActive;
  final VoidCallback onPause;
  const KillSwitchBar({super.key, required this.autonomousActive, required this.onPause});

  @override
  State<KillSwitchBar> createState() => _KillSwitchBarState();
}

class _KillSwitchBarState extends State<KillSwitchBar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  @override
  void initState() { super.initState(); _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true); }
  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.autonomousActive) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        return GestureDetector(
          onTap: widget.onPause,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.danger,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: theme.danger.withOpacity(0.2 + 0.25 * t), blurRadius: 8 + 6 * t)],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.stop_circle, color: theme.bg, size: 20),
              const SizedBox(width: 8),
              MonoText('EMERGENCY STOP', size: 13, weight: FontWeight.w700, color: theme.bg),
            ]),
          ),
        );
      },
    );
  }
}