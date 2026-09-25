import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A circular "stamp" showing "current/total" — the ledger's stand-in for a
/// linear progress bar, styled like a range officer's mark on a scorecard
/// rather than a Material progress indicator.
class LedgerStampBadge extends StatelessWidget {
  final int current;
  final int total;

  const LedgerStampBadge({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Transform.rotate(
      angle: -0.08,
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.primary, width: 2.2),
        ),
        child: Text(
          '$current/$total',
          textAlign: TextAlign.center,
          style: mono(theme.textTheme.labelLarge)?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
