import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/scorecard.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/ios_tab_bar.dart';
import '../widgets/ledger_stamp_badge.dart';
import '../widgets/ledger_tabs.dart';
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
          SliverAppBar.large(
            title: const Text('Scores'),
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.add),
                tooltip: 'New Scorecard',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewScorecardScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: LedgerTabs<ScoresView>(
                  groupValue: _selectedView,
                  values: const [ScoresView.active, ScoresView.history],
                  labels: const ['ACTIVE', 'HISTORY'],
                  onChanged: (value) => setState(() => _selectedView = value),
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
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                MediaQuery.of(context).padding.bottom + iosTabBarHeight + 16,
              ),
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
                    confirmDismiss: (direction) => showConfirmDialog(
                      context,
                      title: 'Abandon this round?',
                      message:
                          'This will permanently delete "${round.name}" and its progress.',
                      confirmLabel: 'Delete',
                    ),
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

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LedgerStampBadge(
                current: endsDone + 1,
                total: scorecard.totalEnds,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(scorecard.name, style: theme.textTheme.titleMedium),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
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

enum _TimeFilter { all, week, month, year }

class HistoryViewState extends State<_HistoryView> {
  late Future<List<Scorecard>> _scorecardsFuture;
  final _searchController = TextEditingController();
  _TimeFilter _timeFilter = _TimeFilter.all;

  @override
  void initState() {
    super.initState();
    _scorecardsFuture = _fetchHistory();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Scorecard> _applyFilters(List<Scorecard> rounds) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    return rounds.where((round) {
      if (query.isNotEmpty && !round.name.toLowerCase().contains(query)) {
        return false;
      }
      switch (_timeFilter) {
        case _TimeFilter.all:
          return true;
        case _TimeFilter.week:
          return !round.startedAt.isBefore(startOfWeek);
        case _TimeFilter.month:
          return round.startedAt.year == now.year &&
              round.startedAt.month == now.month;
        case _TimeFilter.year:
          return round.startedAt.year == now.year;
      }
    }).toList();
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

        final filteredRounds = _applyFilters(rounds);
        final bestScore = filteredRounds.isEmpty
            ? 0
            : filteredRounds
                  .map((r) => r.runningTotal)
                  .reduce((a, b) => a > b ? a : b);
        final averageScore = filteredRounds.isEmpty
            ? 0.0
            : filteredRounds
                      .map((r) => r.runningTotal)
                      .reduce((a, b) => a + b) /
                  filteredRounds.length;

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                refresh();
                await _scorecardsFuture;
              },
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                MediaQuery.of(context).padding.bottom + iosTabBarHeight + 16,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search by name',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: LedgerTabs<_TimeFilter>(
                        groupValue: _timeFilter,
                        values: const [
                          _TimeFilter.all,
                          _TimeFilter.week,
                          _TimeFilter.month,
                          _TimeFilter.year,
                        ],
                        labels: const [
                          'ALL TIME',
                          'THIS WEEK',
                          'THIS MONTH',
                          'THIS YEAR',
                        ],
                        onChanged: (value) =>
                            setState(() => _timeFilter = value),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (filteredRounds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'No rounds match your filters.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else ...[
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
                      ...filteredRounds.map(
                        (round) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Dismissible(
                            key: ValueKey(round.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                CupertinoIcons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) => showConfirmDialog(
                              context,
                              title: 'Delete this round?',
                              message:
                                  'This will permanently delete "${round.name}" from your history.',
                              confirmLabel: 'Delete',
                            ),
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
                                            (e) =>
                                                e.map((s) => s ?? 0).toList(),
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
              style: mono(theme.textTheme.titleLarge)
                  ?.copyWith(color: theme.colorScheme.primary),
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
            style: mono(theme.textTheme.titleMedium),
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
