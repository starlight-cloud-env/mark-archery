import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/scorecard_template.dart';
import '../widgets/grouped_card.dart';

class ManageTemplatesScreen extends StatefulWidget {
  const ManageTemplatesScreen({super.key});

  @override
  State<ManageTemplatesScreen> createState() => _ManageTemplatesScreenState();
}

class _ManageTemplatesScreenState extends State<ManageTemplatesScreen> {
  late Future<List<ScorecardTemplate>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _templatesFuture = _fetchMyTemplates();
  }

  Future<List<ScorecardTemplate>> _fetchMyTemplates() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('scorecard_templates')
        .select()
        .eq('created_by', userId)
        .order('created_at', ascending: false);

    return response.map((json) => ScorecardTemplate.fromJson(json)).toList();
  }

  Future<void> _deleteTemplate(String id) async {
    await supabase.from('scorecard_templates').delete().eq('id', id);
    setState(() {
      _templatesFuture = _fetchMyTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Templates')),
      body: FutureBuilder<List<ScorecardTemplate>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Text(
                  'Could not load templates: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            );
          }

          final templates = snapshot.data ?? [];
          if (templates.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No custom templates saved yet. Check "Save as a reusable template" when building a custom scorecard.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              GroupedCard(
                child: Column(
                  children: [
                    for (var i = 0; i < templates.length; i++) ...[
                      if (i > 0) const GroupedCardDivider(),
                      ListTile(
                        title: Text(templates[i].name),
                        subtitle: Text(
                          '${templates[i].ends} ends · ${templates[i].arrowsPerEnd} arrows/end',
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            CupertinoIcons.delete,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _deleteTemplate(templates[i].id),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
