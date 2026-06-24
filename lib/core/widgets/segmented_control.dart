import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Segmented control for 2–4 options. `surfaceRaised` container, pill
/// segments, selected gets `accent` background. See DESIGN.md §5.6.
class SegmentedControl<T> extends StatelessWidget {
  final List<Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool expanded;

  const SegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              flex: expanded ? 1 : 0,
              child: GestureDetector(
                onTap: () => onChanged(s.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: s.value == selected ? theme.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (s.icon != null) ...[
                        Icon(s.icon, size: 16, color: s.value == selected ? theme.background : theme.textSecondary),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          s.label,
                          style: theme.textTheme.labelMedium!.copyWith(
                            color: s.value == selected ? theme.background : theme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Segment<T> {
  final T value;
  final String label;
  final IconData? icon;
  const Segment(this.value, this.label, {this.icon});
}