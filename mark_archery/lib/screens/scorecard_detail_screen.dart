import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/arrow_chip.dart';
import '../widgets/grouped_card.dart';

class ScorecardDetailScreen extends StatelessWidget {
  final String scorecardName;
  final String date;
  final int totalScore;
  final int maxPossible;
  final int maxScore;
  final List<List<int>> ends;

  const ScorecardDetailScreen({
    super.key,
    required this.scorecardName,
    required this.date,
    required this.totalScore,
    required this.maxPossible,
    required this.maxScore,
    required this.ends,
  });

  int _endTotal(int endIndex) {
    return ends[endIndex].fold(0, (sum, score) => sum + score);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(scorecardName)),
      body: Column(
        children: [
          // Summary banner
          Container(
            width: double.infinity,
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                Text(
                  '$totalScore / $maxPossible',
                  style: mono(theme.textTheme.headlineMedium)?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Read-only ends list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                GroupedCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < ends.length; i++) ...[
                        if (i > 0) const GroupedCardDivider(),
                        _ReadOnlyEndRow(
                          endNumber: i + 1,
                          arrowScores: ends[i],
                          endTotal: _endTotal(i),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyEndRow extends StatelessWidget {
  final int endNumber;
  final List<int> arrowScores;
  final int endTotal;

  const _ReadOnlyEndRow({
    required this.endNumber,
    required this.arrowScores,
    required this.endTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$endNumber', style: mono(theme.textTheme.bodyLarge)),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              children: arrowScores
                  .map((score) => ArrowChip(score: score))
                  .toList(),
            ),
          ),
          Text('$endTotal', style: mono(theme.textTheme.titleMedium)),
        ],
      ),
    );
  }
}
