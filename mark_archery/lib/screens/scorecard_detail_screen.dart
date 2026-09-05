import 'package:flutter/material.dart';

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
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: ends.length,
              itemBuilder: (context, endIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: _ReadOnlyEndRow(
                    endNumber: endIndex + 1,
                    arrowScores: ends[endIndex],
                    endTotal: _endTotal(endIndex),
                  ),
                );
              },
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text('$endNumber', style: theme.textTheme.bodyLarge),
            ),
            Expanded(
              child: Wrap(
                spacing: 6,
                children: arrowScores.map((score) {
                  return Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    ),
                    child: Text('$score', style: theme.textTheme.bodySmall),
                  );
                }).toList(),
              ),
            ),
            Text('$endTotal', style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}