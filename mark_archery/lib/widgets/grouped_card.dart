import 'package:flutter/material.dart';

/// A rounded, bordered container used for "grouped list" style content —
/// the ledger's grouped sections (Home's stats/activity, Profile's
/// account/preferences/legal, template and history lists, etc).
class GroupedCard extends StatelessWidget {
  final Widget child;

  const GroupedCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      // The fill is a Material (not a plain colored Container) so that any
      // ListTile/InkWell children inside can paint their ink splashes and
      // tap highlight correctly — a Container's own background would
      // otherwise paint over those effects and hide them.
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: child,
      ),
    );
  }
}

/// A dashed rule between rows inside a [GroupedCard] — the ledger's
/// signature divider, standing in for iOS's solid grouped-list separator.
class GroupedCardDivider extends StatelessWidget {
  const GroupedCardDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 4.0;
    const gapWidth = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
