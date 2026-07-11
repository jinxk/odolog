import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../domain/value_objects/window_mileage.dart';

/// A dependency light bar chart of mileage per closed full tank window, oldest
/// to newest. No chart package: a small custom painter is enough and keeps the
/// build lean. The teal fill keeps amber reserved for the hero number.
class MileageTrend extends StatelessWidget {
  const MileageTrend({super.key, required this.windows, this.height = 96});

  final List<WindowMileage> windows;
  final double height;

  @override
  Widget build(BuildContext context) {
    final values = [for (final window in windows) window.mileage];
    // Deep teal reads well on the light card but drops to 2.69:1 on the dark
    // card, below the 3:1 a graphical object needs. The dark theme uses the
    // brighter teal so the bars stay visible in glare.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark
        ? AppColors.tealBright
        : Theme.of(context).colorScheme.secondary;
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarsPainter(values: values, color: barColor),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return;

    final gap = 6.0;
    final barWidth = (size.width - gap * (values.length - 1)) / values.length;
    final paint = Paint()..color = color;

    for (var i = 0; i < values.length; i++) {
      final normalized = values[i] / maxValue;
      final barHeight = normalized * size.height;
      final left = i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
