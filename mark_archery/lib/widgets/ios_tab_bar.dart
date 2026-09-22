import 'dart:ui';

import 'package:flutter/material.dart';

/// Fixed height of [IosTabBar]'s own content, not counting the device's
/// bottom safe-area inset (home indicator / gesture nav). Screens under a
/// [Scaffold] with `extendBody: true` should add this — plus
/// `MediaQuery.of(context).padding.bottom` — to their scrollable content's
/// bottom padding so the last item isn't hidden behind the floating bar.
const double iosTabBarHeight = 56.0;

/// Icon/label pair for one [IosTabBar] destination.
class IosTabDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const IosTabDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// A bottom tab bar matching iOS conventions rather than Material's:
/// a frosted/translucent background, tinted icon+label (no pill indicator),
/// and a brief "pop" animation on the icon when a tab becomes selected.
class IosTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<IosTabDestination> destinations;

  const IosTabBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.75),
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _IosTabItem(
                        destination: destinations[i],
                        isSelected: i == selectedIndex,
                        onTap: () => onDestinationSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IosTabItem extends StatefulWidget {
  final IosTabDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _IosTabItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_IosTabItem> createState() => _IosTabItemState();
}

class _IosTabItemState extends State<_IosTabItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.22,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.22,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _IosTabItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final icon = widget.isSelected
        ? (widget.destination.selectedIcon ?? widget.destination.icon)
        : widget.destination.icon;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _scale,
            builder: (context, child) =>
                Transform.scale(scale: _scale.value, child: child),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 2),
          Text(
            widget.destination.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
