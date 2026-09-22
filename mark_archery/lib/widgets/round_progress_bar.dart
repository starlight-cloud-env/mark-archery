import 'package:flutter/material.dart';

/// The thin rounded progress bar showing how far through a round's ends an
/// archer is, used on both the Home dashboard's Continue Scoring card and
/// the Scores tab's active round cards.
class RoundProgressBar extends StatelessWidget {
  final double progress;

  const RoundProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        backgroundColor: theme.colorScheme.outlineVariant,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
