import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A small circular chip showing one arrow's score, used in both the live
/// scoring screen (where [score] may be null for an unfilled slot) and the
/// read-only scorecard detail view (where every score is already filled).
///
/// When a slot goes from empty to filled, the score "ink-draws" in with a
/// quick overshoot — like ink landing on paper — rather than popping in
/// flatly. Chips that are already filled on first build (history view)
/// don't animate.
class ArrowChip extends StatefulWidget {
  final int? score;

  const ArrowChip({super.key, required this.score});

  @override
  State<ArrowChip> createState() => _ArrowChipState();
}

class _ArrowChipState extends State<ArrowChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    if (widget.score != null) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant ArrowChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score == null && widget.score != null) {
      _controller.forward(from: 0);
    } else if (widget.score == null) {
      _controller.value = 0;
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
    final isEmpty = widget.score == null;

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isEmpty
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.primary,
        ),
      ),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEmpty
                ? null
                : theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
          child: Text(
            isEmpty ? '' : '${widget.score}',
            style: mono(theme.textTheme.bodySmall),
          ),
        ),
      ),
    );
  }
}
