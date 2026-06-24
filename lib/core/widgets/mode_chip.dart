import 'package:flutter/material.dart';
import '../domain/enums.dart';
import 'status_chip.dart';

/// Mode chip showing the execution mode icon + label. See DESIGN.md §5.3.
class ModeChip extends StatelessWidget {
  final ExecutionMode mode;
  final bool compact;

  const ModeChip({super.key, required this.mode, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = switch (mode) {
      ExecutionMode.manual => (ChipTone.info, Icons.pan_tool_outlined),
      ExecutionMode.semiAuto => (ChipTone.warning, Icons.timer_outlined),
      ExecutionMode.autonomous => (ChipTone.accent, Icons.auto_mode),
    };
    return StatusChip(
      label: compact ? mode.label.split('-').first : mode.label,
      tone: tone,
      icon: icon,
    );
  }
}