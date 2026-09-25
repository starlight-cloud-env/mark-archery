import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/grouped_card.dart';
import '../widgets/ledger_checkbox.dart';
import '../widgets/loading_elevated_button.dart';
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
  bool _saveAsTemplate = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleStart() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_saveAsTemplate) {
        final userId = supabase.auth.currentUser!.id;
        await supabase.from('scorecard_templates').insert({
          'name': _nameController.text.trim(),
          'ends': _ends,
          'arrows_per_end': _arrowsPerEnd,
          'max_score': 10,
          'is_premade': false,
          'created_by': userId,
        });
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScoringScreen(
              scorecardName: _nameController.text.trim(),
              ends: _ends,
              arrowsPerEnd: _arrowsPerEnd,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save template: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
            const SizedBox(height: 10),
            GroupedCard(
              child: Column(
                children: [
                  _NumberStepper(
                    label: 'Ends',
                    value: _ends,
                    min: 1,
                    max: 20,
                    onChanged: (newValue) => setState(() => _ends = newValue),
                  ),
                  const GroupedCardDivider(),
                  _NumberStepper(
                    label: 'Arrows per End',
                    value: _arrowsPerEnd,
                    min: 1,
                    max: 12,
                    onChanged: (newValue) =>
                        setState(() => _arrowsPerEnd = newValue),
                  ),
                  const GroupedCardDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      children: [
                        Text('Total arrows', style: theme.textTheme.bodyLarge),
                        const Spacer(),
                        Text(
                          '${_ends * _arrowsPerEnd}',
                          style: mono(theme.textTheme.titleMedium)
                              ?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                  const GroupedCardDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 2.0,
                    ),
                    child: LedgerCheckbox(
                      value: _saveAsTemplate,
                      onChanged: (checked) =>
                          setState(() => _saveAsTemplate = checked),
                      label: 'Save as a reusable template',
                      subtitle: 'Appears under "Choose a Template" next time',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LoadingElevatedButton(
              isLoading: _isSubmitting,
              onPressed: _handleStart,
              label: 'Start Scoring',
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          IconButton(
            icon: const Icon(CupertinoIcons.minus_circle),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: mono(theme.textTheme.titleMedium),
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
