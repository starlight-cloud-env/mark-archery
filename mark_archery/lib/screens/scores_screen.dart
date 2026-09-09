import 'package:flutter/material.dart';
import '../main.dart';
import '../models/scorecard.dart';
import 'new_scorecard_screen.dart';
import 'scorecard_detail_screen.dart';
import 'scoring_screen.dart';

enum ScoresView { active, history }

class ScoresScreen extends StatefulWidget {
  const ScoresScreen({super.key});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen> {
  ScoresView _selectedView = ScoresView.active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SegmentedButton<ScoresView>(
            segments: const [
              ButtonSegment(value: ScoresView.active, label: Text('Active'), icon: Icon(Icons.gps_fixed)),
              ButtonSegment(value: ScoresView.history, label: Text('History'), icon: Icon(Icons.history)),
            ],
            selected: {_selectedView},
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedView = newSelection.first;
              });
            },
          ),
        ),
        Expanded(
          child: _selectedView == ScoresView.active
              ? const _ActiveScoresView()
              : const _HistoryView(),
        ),
      ],
    );
  }
}

class _ActiveScoresView extends StatefulWidget {
  const _ActiveScoresView();

  @override
  State<_ActiveScoresView> createState() => _ActiveScoresViewState();
}

class _ActiveScoresViewState extends State<_ActiveScoresView> {
  late Future<List<Scorecard>> _scorecardsFuture;

  @override
  void initState() {
    super.initState();
    _scorecardsFuture = _fetchActive();
  }

  Future<List<Scorecard>> _fetchActive() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('scorecards')
        .select()
        .eq('archer_id', userId)
        .eq('status', 'active')
        .order('started_at', ascending: false);

    return response.map((json) => Scorecard.fromJson(json)).toList();
  }

  void _refresh() {
    setState(() {
      _scorecardsFuture = _fetchActive();
    });
  }

  Future<void> _deleteRound(String id) async {
    await supabase.from('scorecards').delete().eq('id', id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Scorecard>>(
      future: _scorecardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final rounds = snapshot.data!;
        if (rounds.isEmpty) {
          return const _EmptyActiveState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: rounds.length,
          itemBuilder: (context, index) {
            final round = rounds[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Dismissible(
                key: ValueKey(round.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Abandon this round?'),
                      content: Text('This will permanently delete "${round.name}" and its progress.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  await _deleteRound(round.id);
                },
                child: _ActiveRoundCard(
                  scorecard: round,
                  onReturned: _refresh,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ActiveRoundCard extends StatelessWidget {
  final Scorecard scorecard;
  final VoidCallback onReturned;

  const _ActiveRoundCard({required this.scorecard, required this.onReturned});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final endsDone = scorecard.nextEmptySlot?.end ?? scorecard.totalEnds;
    final currentEnd = endsDone + 1;
    final progress = endsDone / scorecard.totalEnds;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScoringScreen(
                scorecardName: scorecard.name,
                ends: scorecard.totalEnds,
                arrowsPerEnd: scorecard.arrowsPerEnd,
                maxScore: scorecard.maxScore,
                existingScorecard: scorecard,
              ),
            ),
          );
          onReturned();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gps_fixed, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(scorecard.name, style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'End $currentEnd of ${scorecard.totalEnds}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyActiveState extends StatelessWidget {
  const _EmptyActiveState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gps_fixed, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No active rounds', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Start a new scorecard to begin tracking your round.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NewScorecardScreen()));
              },
              icon: const Icon(Icons.add),
              label: const Text('Start New Scorecard'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView();

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  late Future<List<Scorecard>> _scorecardsFuture;

  @override
  void initState() {
    super.initState();
    _scorecardsFuture = _fetchHistory();
  }

  Future<List<Scorecard>> _fetchHistory() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('scorecards')
        .select()
        .eq('archer_id', userId)
        .eq('status', 'completed')
        .order('started_at', ascending: false);

    return response.map((json) => Scorecard.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Scorecard>>(
      future: _scorecardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final rounds = snapshot.data!;
        if (rounds.isEmpty) {
          return const _EmptyHistoryState();
        }

        final bestScore = rounds.map((r) => r.runningTotal).reduce((a, b) => a > b ? a : b);
        final averageScore = rounds.map((r) => r.runningTotal).reduce((a, b) => a + b) / rounds.length;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Row(
              children: [
                Expanded(child: _SummaryStat(label: 'Best Score', value: '$bestScore')),
                const SizedBox(width: 12),
                Expanded(child: _SummaryStat(label: 'Average', value: averageScore.toStringAsFixed(1))),
              ],
            ),
            const SizedBox(height: 20),
            Text('All Rounds', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...rounds.map(
              (round) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _PastRoundTile(
                  scorecard: round,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScorecardDetailScreen(
                          scorecardName: round.name,
                          date: round.startedAt.toLocal().toString().split(' ')[0],
                          totalScore: round.runningTotal,
                          maxPossible: round.maxPossible,
                          maxScore: round.maxScore,
                          ends: round.ends.map((e) => e.map((s) => s ?? 0).toList()).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PastRoundTile extends StatelessWidget {
  final Scorecard scorecard;
  final VoidCallback onTap;

  const _PastRoundTile({required this.scorecard, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Icon(Icons.gps_fixed, color: theme.colorScheme.primary, size: 20),
          ),
          title: Text(scorecard.name),
          subtitle: Text(scorecard.startedAt.toLocal().toString().split(' ')[0]),
          trailing: Text('${scorecard.runningTotal} / ${scorecard.maxPossible}', style: theme.textTheme.titleMedium),
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No rounds yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Completed scorecards will show up here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}