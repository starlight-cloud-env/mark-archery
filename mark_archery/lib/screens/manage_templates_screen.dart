import 'package:flutter/material.dart';
import '../main.dart';
import '../models/scorecard_template.dart';

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

          final templates = snapshot.data ?? [];
          if (templates.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No custom templates saved yet. Check "Save as a reusable template" when building a custom scorecard.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                child: ListTile(
                  title: Text(template.name),
                  subtitle: Text('${template.ends} ends · ${template.arrowsPerEnd} arrows/end'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    onPressed: () => _deleteTemplate(template.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}