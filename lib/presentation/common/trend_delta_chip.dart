import 'package:flutter/material.dart';

/// A small signed, arrowed pill that reads a change as good or bad without
/// leaning on colour alone.
///
/// Direction is carried three ways at once so it survives sun washout and colour
/// blindness: an up or down arrow, a plus or minus sign, and the semantic
/// colour. [higherIsBetter] separates the two things that can move in opposite
/// valence: for mileage a rise is good, for spend a rise is bad, so the arrow
/// follows the raw [delta] while the colour follows the valence.
///
/// Callers pass the surface-appropriate [positiveColor] and [negativeColor]
/// rather than reading them from the theme, because the same chip sits on the
/// always-dark hero card in the light theme, where the light semantic greens go
/// muddy. A [delta] of zero renders nothing, since there is no change to report.
class TrendDeltaChip extends StatelessWidget {
  const TrendDeltaChip({
    super.key,
    required this.delta,
    required this.format,
    required this.positiveColor,
    required this.negativeColor,
    this.higherIsBetter = true,
  });

  /// Signed change, current minus baseline, in the figure's own unit.
  final double delta;

  /// Formats the magnitude (already made positive) for display.
  final String Function(double magnitude) format;

  final Color positiveColor;
  final Color negativeColor;

  /// Whether a rise in the figure is the good direction.
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    if (delta == 0) return const SizedBox.shrink();
    final rising = delta > 0;
    final good = rising == higherIsBetter;
    final color = good ? positiveColor : negativeColor;
    final sign = rising ? '+' : '-';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.16),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rising ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$sign${format(delta.abs())}',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
