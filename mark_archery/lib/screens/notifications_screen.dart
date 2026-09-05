import 'package:flutter/material.dart';
import '../main.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool? _enabled;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('archers')
        .select('notifications_enabled')
        .eq('id', userId)
        .single();

    setState(() {
      _enabled = response['notifications_enabled'] as bool? ?? true;
    });
  }

  Future<void> _togglePreference(bool value) async {
    setState(() {
      _enabled = value;
      _isSaving = true;
    });

    final userId = supabase.auth.currentUser!.id;
    await supabase.from('archers').update({'notifications_enabled': value}).eq('id', userId);

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _enabled == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                SwitchListTile(
                  value: _enabled!,
                  onChanged: _isSaving ? null : _togglePreference,
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Reminders and updates about your rounds'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
    );
  }
}