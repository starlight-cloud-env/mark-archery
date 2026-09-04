import 'package:flutter/material.dart';
import 'new_scorecard_screen.dart';

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
              ButtonSegment(
                value: ScoresView.active,
                label: Text('Active'),
                icon: Icon(Icons.gps_fixed),
              ),
              ButtonSegment(
                value: ScoresView.history,
                label: Text('History'),
                icon: Icon(Icons.history),
              ),
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

class _ActiveScoresView extends StatelessWidget {
  const _ActiveScoresView();

  // Placeholder data — shape mirrors what a real Scorecard model will look like.
  final List<Map<String, dynamic>> _activeRounds = const [
    {
      'type': 'Outdoor',
      'currentEnd': 4,
      'totalEnds': 10,
      'startedLabel': 'Started today, 2:15 PM',
    },
    {
      'type': 'Indoor',
      'currentEnd': 2,
      'totalEnds': 6,
      'startedLabel': 'Started yesterday',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_activeRounds.isEmpty) {
      return const _EmptyActiveState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _activeRounds.length,
      itemBuilder: (context, index) {
        final round = _activeRounds[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _ActiveRoundCard(
            type: round['type'],
            currentEnd: round['currentEnd'],
            totalEnds: round['totalEnds'],
            startedLabel: round['startedLabel'],
            onTap: () {
              // Placeholder — navigate to the scoring entry screen later
            },
          ),
        );
      },
    );
  }
}

class _ActiveRoundCard extends StatelessWidget {
  final String type;
  final int currentEnd;
  final int totalEnds;
  final String startedLabel;
  final VoidCallback onTap;

  const _ActiveRoundCard({
    required this.type,
    required this.currentEnd,
    required this.totalEnds,
    required this.startedLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = currentEnd / totalEnds;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gps_fixed, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('$type Round', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'End $currentEnd of $totalEnds',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                startedLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
            Icon(
              Icons.gps_fixed,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No active rounds',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new scorecard to begin tracking your round.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewScorecardScreen()),
                );
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

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  // Placeholder data — shape mirrors what a real completed Scorecard will look like.
  final List<Map<String, dynamic>> _pastRounds = const [
    {'type': 'Indoor', 'date': 'Sept 1', 'score': 275, 'maxPossible': 300},
    {'type': 'Outdoor', 'date': 'Aug 28', 'score': 281, 'maxPossible': 300},
    {'type': 'Indoor', 'date': 'Aug 24', 'score': 268, 'maxPossible': 300},
    {'type': 'Outdoor', 'date': 'Aug 19', 'score': 287, 'maxPossible': 300},
  ];

  int get _bestScore =>
      _pastRounds.map((r) => r['score'] as int).reduce((a, b) => a > b ? a : b);

  double get _averageScore {
    final total = _pastRounds.fold<int>(0, (sum, r) => sum + (r['score'] as int));
    return total / _pastRounds.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_pastRounds.isEmpty) {
      return const _EmptyHistoryState();
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryStat(label: 'Best Score', value: '$_bestScore'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryStat(
                label: 'Average',
                value: _averageScore.toStringAsFixed(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'All Rounds',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._pastRounds.map(
          (round) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _PastRoundTile(
              type: round['type'],
              date: round['date'],
              score: round['score'],
              maxPossible: round['maxPossible'],
              onTap: () {
                // Placeholder — navigate to a read-only scorecard detail view
              },
            ),
          ),
        ),
      ],
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
            Text(value, style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            )),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PastRoundTile extends StatelessWidget {
  final String type;
  final String date;
  final int score;
  final int maxPossible;
  final VoidCallback onTap;

  const _PastRoundTile({
    required this.type,
    required this.date,
    required this.score,
    required this.maxPossible,
    required this.onTap,
  });

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
            child: Icon(
              type == 'Indoor' ? Icons.home_outlined : Icons.park_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text('$type Round'),
          subtitle: Text(date),
          trailing: Text(
            '$score / $maxPossible',
            style: theme.textTheme.titleMedium,
          ),
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
            Icon(
              Icons.history,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No rounds yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Completed scorecards will show up here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
