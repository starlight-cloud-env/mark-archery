import 'package:flutter/material.dart';
import 'new_scorecard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Placeholder — will come from real data later.
  final bool hasActiveRound = true;
  final double activeRoundProgress = 0.4; // 4 of 10 ends
  final String activeRoundLabel = 'Outdoor round · End 4 of 10';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Welcome back, Brendan',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),

        // Primary action — the one thing that should stand out (Von Restorff Effect)
        if (hasActiveRound)
          _ContinueRoundCard(
            label: activeRoundLabel,
            progress: activeRoundProgress,
            onTap: () {
              // Placeholder — navigate to active scorecard later
            },
          )
        else
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
        const SizedBox(height: 28),

        // Section: Stats
        Text('Your Stats', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Best Score',
                value: '287',
                icon: Icons.emoji_events,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'This Month',
                value: '6 rounds',
                icon: Icons.calendar_today,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Section: Recent Activity
        Text('Recent Activity', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const _RecentScoreTile(date: 'Sept 1', type: 'Indoor', score: '275'),
        const _RecentScoreTile(date: 'Aug 28', type: 'Outdoor', score: '281'),
        const _RecentScoreTile(date: 'Aug 24', type: 'Indoor', score: '268'),
      ],
    );
  }
}

class _ContinueRoundCard extends StatelessWidget {
  final String label;
  final double progress;
  final VoidCallback onTap;

  const _ContinueRoundCard({
    required this.label,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onPrimary),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
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

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

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

  const _RecentScoreTile({
    required this.date,
    required this.type,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.circle_outlined),
      title: Text('$type Round'),
      subtitle: Text(date),
      trailing: Text(
        score,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
