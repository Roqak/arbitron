import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Generic circular avatar with the exchange's first letter. Used until proper
/// exchange logos are available. See DESIGN.md §6.
class ExchangeAvatar extends StatelessWidget {
  final String name;
  final double size;
  const ExchangeAvatar({super.key, required this.name, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: theme.surfaceRaised, shape: BoxShape.circle, border: Border.all(color: theme.borderSubtle, width: 1)),
      child: Center(child: Text(letter, style: TextStyle(color: theme.textSecondary, fontSize: size * 0.45, fontWeight: FontWeight.w600))),
    );
  }
}