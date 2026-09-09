import 'package:flutter/material.dart';
import '../main.dart';
import '../models/scorecard.dart';
import '../models/scorecard_template.dart';
import 'scoring_screen.dart';
import 'custom_scorecard_screen.dart';

class NewScorecardScreen extends StatefulWidget {
  const NewScorecardScreen({super.key});

  @override
  State<NewScorecardScreen> createState() => _NewScorecardScreenState();
}

class _NewScorecardCheckResult {
  final Scorecard? existingActive;
  final List<ScorecardTemplate> templates;

  const _NewScorecardCheckResult({required this.existingActive, required this.templates});
}

class _NewScorecardScreenState extends State<NewScorecardScreen> {
  late Future<_NewScorecardCheckResult> _checkFuture;

  @override
  void initState() {
    super.initState();
    _checkFuture = _check();
  }

  Future<_NewScorecardCheckResult> _check() async {
    final userId = supabase.auth.currentUser!.id;

    final activeRows = await supabase
        .from('scorecards')
        .select()
        .eq('archer_id', userId)
        .eq('status', 'active')
        .order('started_at', ascending: false)
        .limit(1);

    if (activeRows.isNotEmpty) {
      return _NewScorecardCheckResult(
        existingActive: Scorecard.fromJson(activeRows.first),
        templates: const [],
      );
    }

    final templateRows = await supabase
        .from('scorecard_templates')
        .select()
        .or('is_premade.eq.true,created_by.eq.$userId')
        .order('is_premade', ascending: false);

    return _NewScorecardCheckResult(
      existingActive: null,
      templates: templateRows.map((json) => ScorecardTemplate.fromJson(json)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New Scorecard')),
      body: FutureBuilder<_NewScorecardCheckResult>(
        future: _checkFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final result = snapshot.data!;

          if (result.existingActive != null) {
            final active = result.existingActive!;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gps_fixed, size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('You already have a round in progress', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'Finish or abandon "${active.name}" before starting a new one.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScoringScreen(
                              scorecardName: active.name,
                              ends: active.totalEnds,
                              arrowsPerEnd: active.arrowsPerEnd,
                              maxScore: active.maxScore,
                              existingScorecard: active,
                            ),
                          ),
                        );
                      },
                      child: const Text('Go to Active Round'),
                    ),
                  ],
                ),
              ),
            );
          }

          final templates = result.templates;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Choose a Template', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              ...templates.map(
                (template) => Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: _TemplateCard(
                    template: template,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScoringScreen(
                            scorecardName: template.name,
                            ends: template.ends,
                            arrowsPerEnd: template.arrowsPerEnd,
                            maxScore: template.maxScore,
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
                    child: Text('or', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
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
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final ScorecardTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

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
                    Text(template.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${template.ends} ends · ${template.arrowsPerEnd} arrows/end · max ${template.maxScore}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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