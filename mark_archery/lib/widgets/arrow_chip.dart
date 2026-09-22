import 'package:flutter/material.dart';

/// A small circular chip showing one arrow's score, used in both the live
/// scoring screen (where [score] may be null for an unfilled slot) and the
/// read-only scorecard detail view (where every score is already filled).
class ArrowChip extends StatelessWidget {
  final int? score;

  const ArrowChip({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = score == null;

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isEmpty
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.primary,
        ),
        color: isEmpty
            ? null
            : theme.colorScheme.primary.withValues(alpha: 0.12),
      ),
      child: Text(isEmpty ? '' : '$score', style: theme.textTheme.bodySmall),
    );
  }
}
