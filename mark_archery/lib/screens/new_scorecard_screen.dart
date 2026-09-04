import 'package:flutter/material.dart';
import 'scoring_screen.dart';
import 'custom_scorecard_screen.dart';

class NewScorecardScreen extends StatelessWidget {
  const NewScorecardScreen({super.key});

  // Placeholder data — real templates will come from Supabase later.
  final List<Map<String, dynamic>> _templates = const [
    {
      'name': 'WA 70m Outdoor',
      'ends': 12,
      'arrowsPerEnd': 6,
      'maxScore': 10,
    },
    {
      'name': 'Indoor 18m',
      'ends': 10,
      'arrowsPerEnd': 3,
      'maxScore': 10,
    },
    {
      'name': 'Quick Practice',
      'ends': 5,
      'arrowsPerEnd': 3,
      'maxScore': 10,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Scorecard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Choose a Template', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          ..._templates.map(
            (template) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _TemplateCard(
                name: template['name'],
                ends: template['ends'],
                arrowsPerEnd: template['arrowsPerEnd'],
                maxScore: template['maxScore'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScoringScreen(
                        scorecardName: template['name'],
                        ends: template['ends'],
                        arrowsPerEnd: template['arrowsPerEnd'],
                        maxScore: template['maxScore'],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'or',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomScorecardScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.tune, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Build Custom Scorecard', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            'Set your own ends, arrows, and scoring',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String name;
  final int ends;
  final int arrowsPerEnd;
  final int maxScore;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.name,
    required this.ends,
    required this.arrowsPerEnd,
    required this.maxScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '$ends ends · $arrowsPerEnd arrows/end · max $maxScore',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
