import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/scorecard.dart';
import '../widgets/grouped_card.dart';
import 'home_shell.dart';

class ScoringScreen extends StatefulWidget {
  final String scorecardName;
  final int ends;
  final int arrowsPerEnd;
  final int maxScore;
  final Scorecard? existingScorecard;

  const ScoringScreen({
    super.key,
    required this.scorecardName,
    required this.ends,
    required this.arrowsPerEnd,
    this.maxScore = 10,
    this.existingScorecard,
  });

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  late Scorecard _scorecard;
  bool _isSaving = false;
  bool _hasSaveError = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingScorecard != null) {
      // Resuming an in-progress round — use its saved data directly, nothing to create.
      _scorecard = widget.existingScorecard!;
    } else {
      // Starting fresh.
      _scorecard = Scorecard(
        id: '',
        archerId: supabase.auth.currentUser!.id,
        name: widget.scorecardName,
        arrowsPerEnd: widget.arrowsPerEnd,
        maxScore: widget.maxScore,
        status: ScorecardStatus.active,
        startedAt: DateTime.now(),
        ends: List.generate(
          widget.ends,
          (_) => List.filled(widget.arrowsPerEnd, null),
        ),
      );
      _createScorecard();
    }
  }

  Future<void> _createScorecard() async {
    final json = _scorecard.toJson()..remove('id');
    final response = await supabase
        .from('scorecards')
        .insert(json)
        .select()
        .single();

    setState(() {
      _scorecard = Scorecard.fromJson(response);
    });
  }

  Future<void> _persistEnds() async {
    if (_scorecard.id.isEmpty) return; // hasn't finished creating yet

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await supabase
            .from('scorecards')
            .update({'ends': _scorecard.ends})
            .eq('id', _scorecard.id);

        if (_hasSaveError && mounted) {
          setState(() => _hasSaveError = false);
        }
        return;
      } catch (e) {
        if (attempt == maxAttempts) {
          if (mounted) {
            setState(() => _hasSaveError = true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  "Couldn't save your last score — check your connection.",
                ),
                action: SnackBarAction(label: 'Retry', onPressed: _persistEnds),
              ),
            );
          }
        } else {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
  }

  void _enterScore(int score) {
    final slot = _scorecard.nextEmptySlot;
    if (slot == null) return;

    setState(() {
      _scorecard.ends[slot.end][slot.arrow] = score;
    });
    _persistEnds();
  }

  void _undoLast() {
    for (int e = _scorecard.ends.length - 1; e >= 0; e--) {
      for (int a = _scorecard.ends[e].length - 1; a >= 0; a--) {
        if (_scorecard.ends[e][a] != null) {
          setState(() {
            _scorecard.ends[e][a] = null;
          });
          _persistEnds();
          return;
        }
      }
    }
  }

  /// Returns to the Scores tab (Active view), regardless of how deep the
  /// navigation stack is (Home, Scores/Active, or the New/Custom Scorecard
  /// chain can all lead here).
  void _goToScoresTab() {
    HomeShell.shellKey.currentState?.showTab(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _handleFinish() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await supabase
          .from('scorecards')
          .update({'status': 'completed'})
          .eq('id', _scorecard.id);

      if (mounted) {
        _goToScoresTab();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = _scorecard.nextEmptySlot == null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goToScoresTab();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_scorecard.name),
          actions: [
            if (_hasSaveError)
              IconButton(
                icon: Icon(
                  CupertinoIcons.cloud_bolt,
                  color: theme.colorScheme.error,
                ),
                onPressed: _persistEnds,
                tooltip: 'Not saved — tap to retry',
              ),
            IconButton(
              icon: const Icon(CupertinoIcons.arrow_uturn_left),
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
            Container(
              width: double.infinity,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                children: [
                  Text(
                    '${_scorecard.runningTotal}',
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  GroupedCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < _scorecard.totalEnds; i++) ...[
                          if (i > 0) const GroupedCardDivider(),
                          _EndRow(
                            endNumber: i + 1,
                            arrowScores: _scorecard.ends[i],
                            endTotal: _scorecard.endTotal(i),
                            isCurrentEnd: _scorecard.nextEmptySlot?.end == i,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isComplete)
              _ScoreInputPad(
                maxScore: _scorecard.maxScore,
                onScoreSelected: _enterScore,
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleFinish,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Finish & Save'),
                  ),
                ),
              ),
          ],
        ),
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

    return Container(
      color: isCurrentEnd
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : null,
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
                children: arrowScores
                    .map((score) => _ArrowChip(score: score))
                    .toList(),
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
        color: isEmpty
            ? null
            : theme.colorScheme.primary.withValues(alpha: 0.12),
      ),
      child: Text(isEmpty ? '' : '$score', style: theme.textTheme.bodySmall),
    );
  }
}

class _ScoreInputPad extends StatelessWidget {
  final int maxScore;
  final ValueChanged<int> onScoreSelected;

  const _ScoreInputPad({required this.maxScore, required this.onScoreSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = List.generate(maxScore + 1, (i) => maxScore - i);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
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
