import 'package:flutter/material.dart';
import 'scoring_screen.dart';

class CustomScorecardScreen extends StatefulWidget {
  const CustomScorecardScreen({super.key});

  @override
  State<CustomScorecardScreen> createState() => _CustomScorecardScreenState();
}

class _CustomScorecardScreenState extends State<CustomScorecardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  int _ends = 6;
  int _arrowsPerEnd = 3;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleStart() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScoringScreen(
            scorecardName: _nameController.text,
            ends: _ends,
            arrowsPerEnd: _arrowsPerEnd,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Scorecard')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Scorecard Name',
                hintText: 'e.g. Backyard Practice',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            Text('Round Structure', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _NumberStepper(
              label: 'Ends',
              value: _ends,
              min: 1,
              max: 20,
              onChanged: (newValue) {
                setState(() {
                  _ends = newValue;
                });
              },
            ),
            const SizedBox(height: 12),
            _NumberStepper(
              label: 'Arrows per End',
              value: _arrowsPerEnd,
              min: 1,
              max: 12,
              onChanged: (newValue) {
                setState(() {
                  _arrowsPerEnd = newValue;
                });
              },
            ),
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Text(
                  'Total arrows: ${_ends * _arrowsPerEnd}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _handleStart,
              child: const Text('Start Scoring'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: theme.textTheme.bodyLarge),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 32,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}
