import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/grouped_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool? _enabled;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('archers')
          .select('notifications_enabled')
          .eq('id', userId)
          .single();

      setState(() {
        _enabled = response['notifications_enabled'] as bool? ?? true;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Could not load your preference. Please try again.';
      });
    }
  }

  Future<void> _togglePreference(bool value) async {
    setState(() {
      _enabled = value;
      _isSaving = true;
    });

    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from('archers')
        .update({'notifications_enabled': value})
        .eq('id', userId);

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            )
          : _enabled == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                GroupedCard(
                  child: SwitchListTile(
                    value: _enabled!,
                    onChanged: _isSaving ? null : _togglePreference,
                    title: const Text('Enable Notifications'),
                    subtitle: const Text(
                      'Reminders and updates about your rounds',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
