import 'package:flutter/cupertino.dart';
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
  State<ScoresScreen> createState() => ScoresScreenState();
}

class ScoresScreenState extends State<ScoresScreen> {
  ScoresView _selectedView = ScoresView.active;

  final GlobalKey<ActiveScoresViewState> _activeKey =
      GlobalKey<ActiveScoresViewState>();
  final GlobalKey<HistoryViewState> _historyKey = GlobalKey<HistoryViewState>();

  /// Refetches whichever of Active/History is currently showing. Public so
  /// the tab shell can call it when the user switches back to this tab,
  /// since this screen stays mounted (via IndexedStack) rather than being
  /// recreated on tab switch.
  void refreshCurrent() {
    if (_selectedView == ScoresView.active) {
      _activeKey.currentState?.refresh();
    } else {
      _historyKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Scores')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CupertinoSlidingSegmentedControl<ScoresView>(
                  groupValue: _selectedView,
                  children: const {
                    ScoresView.active: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Active'),
                    ),
                    ScoresView.history: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('History'),
                    ),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedView = value);
                    }
                  },
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: _selectedView == ScoresView.active
                ? _ActiveScoresView(key: _activeKey)
                : _HistoryView(key: _historyKey),
          ),
        ],
      ),
    );
  }
}

class _ActiveScoresView extends StatefulWidget {
  const _ActiveScoresView({super.key});

  @override
  State<_ActiveScoresView> createState() => ActiveScoresViewState();
}

class ActiveScoresViewState extends State<_ActiveScoresView> {
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

  /// Public so ScoresScreenState can force a refetch when this tab becomes
  /// visible again.
  void refresh() {
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

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                refresh();
                await _scorecardsFuture;
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverList.separated(
                itemCount: rounds.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final round = rounds[index];
                  return Dismissible(
                    key: ValueKey(round.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Abandon this round?'),
                          content: Text(
                            'This will permanently delete "${round.name}" and its progress.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
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
                      onReturned: refresh,
                    ),
                  );
                },
              ),
            ),
          ],
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
                  Icon(CupertinoIcons.scope, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(scorecard.name, style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'End $currentEnd of ${scorecard.totalEnds}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
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
              CupertinoIcons.scope,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No active rounds', style: theme.textTheme.titleMedium),
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
                  MaterialPageRoute(
                    builder: (context) => const NewScorecardScreen(),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.add),
              label: const Text('Start New Scorecard'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView({super.key});

  @override
  State<_HistoryView> createState() => HistoryViewState();
}

class HistoryViewState extends State<_HistoryView> {
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

  /// Public so ScoresScreenState can force a refetch when this tab becomes
  /// visible again.
  void refresh() {
    setState(() {
      _scorecardsFuture = _fetchHistory();
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
          return const _EmptyHistoryState();
        }

        final bestScore = rounds
            .map((r) => r.runningTotal)
            .reduce((a, b) => a > b ? a : b);
        final averageScore =
            rounds.map((r) => r.runningTotal).reduce((a, b) => a + b) /
            rounds.length;

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                refresh();
                await _scorecardsFuture;
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryStat(
                            label: 'Best Score',
                            value: '$bestScore',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryStat(
                            label: 'Average',
                            value: averageScore.toStringAsFixed(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('All Rounds', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...rounds.map(
                      (round) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
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
                            child: const Icon(
                              CupertinoIcons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete this round?'),
                                content: Text(
                                  'This will permanently delete "${round.name}" from your history.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            await _deleteRound(round.id);
                          },
                          child: _PastRoundTile(
                            scorecard: round,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ScorecardDetailScreen(
                                    scorecardName: round.name,
                                    date: round.startedAt
                                        .toLocal()
                                        .toString()
                                        .split(' ')[0],
                                    totalScore: round.runningTotal,
                                    maxPossible: round.maxPossible,
                                    maxScore: round.maxScore,
                                    ends: round.ends
                                        .map(
                                          (e) => e.map((s) => s ?? 0).toList(),
                                        )
                                        .toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
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
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
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
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Icon(
              CupertinoIcons.scope,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(scorecard.name),
          subtitle: Text(
            scorecard.startedAt.toLocal().toString().split(' ')[0],
          ),
          trailing: Text(
            '${scorecard.runningTotal} / ${scorecard.maxPossible}',
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
              CupertinoIcons.time,
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
