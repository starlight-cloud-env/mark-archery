import 'package:flutter/material.dart';

/// A rounded, bordered container used for "grouped list" style content,
/// matching the iOS grouped-table-view look used across the app (Home's
/// stats/activity, Profile's account/preferences/legal sections, etc).
class GroupedCard extends StatelessWidget {
  final Widget child;

  const GroupedCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
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

/// A single row inside a [GroupedCard], with a divider automatically drawn
/// above every row except the first — mirrors iOS grouped-list separators.
class GroupedCardDivider extends StatelessWidget {
  const GroupedCardDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
