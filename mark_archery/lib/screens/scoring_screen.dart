import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScoringScreen extends StatefulWidget {
  final String scorecardName;
  final int ends;
  final int arrowsPerEnd;
  final int maxScore;

  const ScoringScreen({
    super.key,
    required this.scorecardName,
    required this.ends,
    required this.arrowsPerEnd,
    this.maxScore = 10,
  });

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  // scores[endIndex][arrowIndex] — null means "not scored yet"
  late List<List<int?>> _scores;

  @override
  void initState() {
    super.initState();
    _scores = List.generate(
      widget.ends,
      (_) => List.filled(widget.arrowsPerEnd, null),
    );
  }

  // Finds the first empty arrow slot, scanning end by end, arrow by arrow.
  ({int end, int arrow})? get _nextEmptySlot {
    for (int e = 0; e < _scores.length; e++) {
      for (int a = 0; a < _scores[e].length; a++) {
        if (_scores[e][a] == null) {
          return (end: e, arrow: a);
        }
      }
    }
    return null; // scorecard is complete
  }

  void _enterScore(int score) {
    final slot = _nextEmptySlot;
    if (slot == null) return; // already full

    setState(() {
      _scores[slot.end][slot.arrow] = score;
    });
  }

  void _undoLast() {
    for (int e = _scores.length - 1; e >= 0; e--) {
      for (int a = _scores[e].length - 1; a >= 0; a--) {
        if (_scores[e][a] != null) {
          setState(() {
            _scores[e][a] = null;
          });
          return;
        }
      }
    }
  }

  int _endTotal(int endIndex) {
    return _scores[endIndex].fold(0, (sum, score) => sum + (score ?? 0));
  }

  int get _runningTotal {
    return _scores
        .expand((end) => end)
        .fold(0, (sum, score) => sum + (score ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = _nextEmptySlot == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scorecardName),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _undoLast();
            },
            tooltip: 'Undo last arrow',
          ),
        ],
      ),
      body: Column(
        children: [
          // Running total banner
          Container(
            width: double.infinity,
            color: theme.colorScheme.primary.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              children: [
                Text(
                  '$_runningTotal',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Ends list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.ends,
              itemBuilder: (context, endIndex) {
                final isCurrentEnd = _nextEmptySlot?.end == endIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: _EndRow(
                    endNumber: endIndex + 1,
                    arrowScores: _scores[endIndex],
                    endTotal: _endTotal(endIndex),
                    isCurrentEnd: isCurrentEnd,
                  ),
                );
              },
            ),
          ),

          // Number pad, or completion state
          if (!isComplete) _ScoreInputPad(
            maxScore: widget.maxScore,
            onScoreSelected: _enterScore,
          ) else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Placeholder — save the completed scorecard
                    Navigator.pop(context);
                  },
                  child: const Text('Finish & Save'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EndRow extends StatelessWidget {
  final int endNumber;
  final List<int?> arrowScores;
  final int endTotal;
  final bool isCurrentEnd;

  const _EndRow({
    required this.endNumber,
    required this.arrowScores,
    required this.endTotal,
    required this.isCurrentEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isCurrentEnd ? theme.colorScheme.primary.withOpacity(0.08) : null,
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
                  return _ArrowChip(score: score);
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

class _ArrowChip extends StatelessWidget {
  final int? score;

  const _ArrowChip({required this.score});

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
        color: isEmpty ? null : theme.colorScheme.primary.withOpacity(0.12),
      ),
      child: Text(
        isEmpty ? '' : '$score',
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}

class _ScoreInputPad extends StatelessWidget {
  final int maxScore;
  final ValueChanged<int> onScoreSelected;

  const _ScoreInputPad({
    required this.maxScore,
    required this.onScoreSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = List.generate(maxScore + 1, (i) => maxScore - i); // e.g. 10..0

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: values.map((value) {
          return SizedBox(
            width: 52,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                onScoreSelected(value);
              },
              child: Text('$value'),
            ),
          );
        }).toList(),
      ),
    );
  }
}
