import 'package:flutter/material.dart';

/// A row of tabs styled as bookmark tabs on a ledger's edge — the active
/// one lifts slightly and casts a shadow, as if it's the page currently
/// open — replacing a sliding-pill segmented control.
class LedgerTabs<T> extends StatelessWidget {
  final T groupValue;
  final List<T> values;
  final List<String> labels;
  final ValueChanged<T> onChanged;

  const LedgerTabs({
    super.key,
    required this.groupValue,
    required this.values,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < values.length; i++)
          _LedgerTab(
            label: labels[i],
            isActive: values[i] == groupValue,
            onTap: () => onChanged(values[i]),
          ),
      ],
    );
  }
}

class _LedgerTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LedgerTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isActive ? -4 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'IBM Plex Mono',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
