import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/scorecard.dart';
import '../widgets/grouped_card.dart';
import '../widgets/ios_tab_bar.dart';
import '../widgets/round_progress_bar.dart';
import 'new_scorecard_screen.dart';
import 'scoring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class _HomeDashboardData {
  final Scorecard? activeRound;
  final List<Scorecard> recentCompleted;
  final int bestScore;
  final int roundsThisMonth;

  const _HomeDashboardData({
    required this.activeRound,
    required this.recentCompleted,
    required this.bestScore,
    required this.roundsThisMonth,
  });
}

class HomeScreenState extends State<HomeScreen> {
  late Future<_HomeDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboard();
  }

  /// Refetches the dashboard. Public so the tab shell can force a refresh
  /// when the user switches back to this tab, since this screen stays
  /// mounted (via IndexedStack) rather than being recreated on tab switch.
  void refresh() {
    setState(() {
      _dashboardFuture = _fetchDashboard();
    });
  }

  Future<_HomeDashboardData> _fetchDashboard() async {
    final userId = supabase.auth.currentUser!.id;

    // Most recent active round, if any.
    final activeRows = await supabase
        .from('scorecards')
        .select()
        .eq('archer_id', userId)
        .eq('status', 'active')
        .order('started_at', ascending: false)
        .limit(1);

    final activeRound = activeRows.isNotEmpty
        ? Scorecard.fromJson(activeRows.first)
        : null;

    // All completed rounds — used for best score, monthly count, and recent activity.
    final completedRows = await supabase
        .from('scorecards')
        .select()
        .eq('archer_id', userId)
        .eq('status', 'completed')
        .order('started_at', ascending: false);

    final completed = completedRows
        .map((json) => Scorecard.fromJson(json))
        .toList();

    final now = DateTime.now();
    final roundsThisMonth = completed.where((r) {
      return r.startedAt.year == now.year && r.startedAt.month == now.month;
    }).length;

    final bestScore = completed.isEmpty
        ? 0
        : completed.map((r) => r.runningTotal).reduce((a, b) => a > b ? a : b);

    return _HomeDashboardData(
      activeRound: activeRound,
      recentCompleted: completed.take(3).toList(),
      bestScore: bestScore,
      roundsThisMonth: roundsThisMonth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder<_HomeDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Text(
                  'Could not load dashboard: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            );
          }

          final data = snapshot.data!;

          return CustomScrollView(
            slivers: [
              const SliverAppBar.large(title: Text('Home')),
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  refresh();
                  await _dashboardFuture;
                },
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.of(context).padding.bottom + iosTabBarHeight + 16,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (data.activeRound != null)
                        _ContinueRoundCard(
                          scorecard: data.activeRound!,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScoringScreen(
                                  scorecardName: data.activeRound!.name,
                                  ends: data.activeRound!.totalEnds,
                                  arrowsPerEnd: data.activeRound!.arrowsPerEnd,
                                  maxScore: data.activeRound!.maxScore,
                                  existingScorecard: data.activeRound!,
                                ),
                              ),
                            );
                            refresh();
                          },
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NewScorecardScreen(),
                              ),
                            );
                            refresh();
                          },
                          icon: const Icon(CupertinoIcons.add),
                          label: const Text('Start New Scorecard'),
                        ),
                      const SizedBox(height: 28),

                      Text('Your Stats', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 10),
                      GroupedCard(
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatCell(
                                  label: 'Best Score',
                                  value: '${data.bestScore}',
                                  icon: CupertinoIcons.star_fill,
                                ),
                              ),
                              VerticalDivider(
                                width: 1,
                                color: theme.colorScheme.outlineVariant,
                              ),
                              Expanded(
                                child: _StatCell(
                                  label: 'This Month',
                                  value: '${data.roundsThisMonth} rounds',
                                  icon: CupertinoIcons.calendar,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      Text(
                        'Recent Activity',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      if (data.recentCompleted.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'No completed rounds yet.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        GroupedCard(
                          child: Column(
                            children: [
                              for (
                                var i = 0;
                                i < data.recentCompleted.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                _RecentScoreTile(
                                  date: data.recentCompleted[i].startedAt
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0],
                                  type: data.recentCompleted[i].name,
                                  score:
                                      '${data.recentCompleted[i].runningTotal}',
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContinueRoundCard extends StatelessWidget {
  final Scorecard scorecard;
  final VoidCallback onTap;

  const _ContinueRoundCard({required this.scorecard, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final endsDone = scorecard.nextEmptySlot?.end ?? scorecard.totalEnds;
    final progress = endsDone / scorecard.totalEnds;

    return GroupedCard(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.scope, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Continue Scoring', style: theme.textTheme.titleMedium),
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
                '${scorecard.name} · End ${endsDone + 1} of ${scorecard.totalEnds}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              RoundProgressBar(progress: progress),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleLarge),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RecentScoreTile extends StatelessWidget {
  final String date;
  final String type;
  final String score;

  const _RecentScoreTile({
    required this.date,
    required this.type,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(score, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
