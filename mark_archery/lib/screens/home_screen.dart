import 'package:flutter/material.dart';
import '../main.dart';
import '../models/scorecard.dart';
import 'new_scorecard_screen.dart';
import 'scoring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
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

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboard();
  }

  void _refresh() {
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

    final activeRound = activeRows.isNotEmpty ? Scorecard.fromJson(activeRows.first) : null;

    // All completed rounds — used for best score, monthly count, and recent activity.
    final completedRows = await supabase
        .from('scorecards')
        .select()
        .eq('archer_id', userId)
        .eq('status', 'completed')
        .order('started_at', ascending: false);

    final completed = completedRows.map((json) => Scorecard.fromJson(json)).toList();

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

    return FutureBuilder<_HomeDashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Could not load dashboard: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          );
        }

        final data = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('Welcome back', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),

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
                  _refresh();
                },
              )
            else
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NewScorecardScreen()),
                  );
                  _refresh();
                },
                icon: const Icon(Icons.add),
                label: const Text('Start New Scorecard'),
              ),
            const SizedBox(height: 28),

            Text('Your Stats', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Best Score',
                    value: '${data.bestScore}',
                    icon: Icons.emoji_events,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'This Month',
                    value: '${data.roundsThisMonth} rounds',
                    icon: Icons.calendar_today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            Text('Recent Activity', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (data.recentCompleted.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'No completed rounds yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else
              ...data.recentCompleted.map(
                (round) => _RecentScoreTile(
                  date: round.startedAt.toLocal().toString().split(' ')[0],
                  type: round.name,
                  score: '${round.runningTotal}',
                ),
              ),
          ],
        );
      },
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

    return Card(
      color: theme.colorScheme.primary,
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
                  Icon(Icons.gps_fixed, color: theme.colorScheme.onPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Continue Scoring',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onPrimary),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${scorecard.name} · End ${endsDone + 1} of ${scorecard.totalEnds}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.2),
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.titleLarge),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RecentScoreTile extends StatelessWidget {
  final String date;
  final String type;
  final String score;

  const _RecentScoreTile({required this.date, required this.type, required this.score});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.circle_outlined),
      title: Text(type),
      subtitle: Text(date),
      trailing: Text(score, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}