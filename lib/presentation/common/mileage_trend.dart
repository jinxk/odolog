import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../domain/value_objects/window_mileage.dart';

/// A dependency-light line chart of mileage per closed full-tank window, oldest
/// to newest.
///
/// No chart package: a small custom painter keeps the build lean. The line and
/// its soft area fill use teal so amber stays reserved for the hero number, and
/// the best window is marked in amber. The line draws in from the baseline once
/// on first paint. Values are km/l (km/kg for CNG); the y axis is scaled to the
/// data, so the chart shows relative movement rather than absolute distance from
/// zero.
class MileageTrend extends StatefulWidget {
  const MileageTrend({
    super.key,
    required this.windows,
    this.height = 132,
    this.unit = 'km/l',
  });

  final List<WindowMileage> windows;
  final double height;

  /// The mileage unit spoken in the chart's screen reader summary, so a CNG
  /// vehicle reads km/kg. Only reaches the semantics, never the drawing.
  final String unit;

  @override
  State<MileageTrend> createState() => _MileageTrendState();
}

class _MileageTrendState extends State<MileageTrend>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _draw = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Deep teal reads well on the light card but drops to 2.69:1 on the dark
    // card, below the 3:1 a graphical object needs, so the dark theme lifts to
    // the brighter teal.
    final isDark = theme.brightness == Brightness.dark;
    final lineColor = isDark
        ? AppColors.tealBright
        : theme.colorScheme.secondary;
    final values = [for (final window in widget.windows) window.mileage];
    return Semantics(
      label: _summary(values, widget.unit),
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _draw,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _TrendPainter(
              values: values,
              lineColor: lineColor,
              bestColor: AppColors.amber,
              labelColor: theme.colorScheme.onSurface.withValues(
                alpha: AppColors.textTertiaryAlpha,
              ),
              progress: _draw.value,
            ),
          ),
        ),
      ),
    );
  }

  /// A spoken summary of the drawn line: the latest window and the best one, so
  /// a screen reader gets the figures the chart shows without the picture.
  String _summary(List<double> values, String unit) {
    if (values.isEmpty) return 'Mileage trend';
    final latest = values.last;
    final best = values.reduce((a, b) => a > b ? a : b);
    return 'Mileage trend, latest ${latest.toStringAsFixed(1)} $unit, '
        'best ${best.toStringAsFixed(1)} $unit';
  }
}

/// Paints the trend line, its area fill, the best and latest point markers, and
/// the min and max value labels, revealing everything left to right by
/// [progress] for the draw-in.
class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.lineColor,
    required this.bestColor,
    required this.labelColor,
    required this.progress,
  });

  final List<double> values;
  final Color lineColor;
  final Color bestColor;
  final Color labelColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    // Room for the value labels that sit above the highest and below the lowest
    // point, so neither clips at the chart edges.
    const topPad = 18.0;
    const bottomPad = 18.0;
    final plotHeight = size.height - topPad - bottomPad;
    if (plotHeight <= 0) return;

    var minValue = values.reduce((a, b) => a < b ? a : b);
    var maxValue = values.reduce((a, b) => a > b ? a : b);
    // A flat series would divide by zero when normalising, so give it a nominal
    // band and let the line sit in the middle.
    if (maxValue - minValue < 0.001) {
      minValue -= 1;
      maxValue += 1;
    }
    final range = maxValue - minValue;

    double xFor(int i) => values.length == 1
        ? size.width / 2
        : (size.width - 8) * i / (values.length - 1) + 4;
    double yFor(double v) => topPad + plotHeight * (1 - (v - minValue) / range);

    final points = [
      for (var i = 0; i < values.length; i++) Offset(xFor(i), yFor(values[i])),
    ];

    final revealX = size.width * progress;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, revealX, size.height));

    if (points.length >= 2) {
      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        line.lineTo(p.dx, p.dy);
      }

      final fill = Path.from(line)
        ..lineTo(points.last.dx, size.height - bottomPad)
        ..lineTo(points.first.dx, size.height - bottomPad)
        ..close();
      canvas.drawPath(fill, Paint()..color = lineColor.withValues(alpha: 0.12));
      canvas.drawPath(
        line,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    final bestIndex = _indexOfMax(values);
    final latestIndex = values.length - 1;
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (i == bestIndex) {
        canvas.drawCircle(p, 4.5, Paint()..color = bestColor);
      } else if (i == latestIndex) {
        // A hollow ring calls out where the story ends now.
        canvas.drawCircle(
          p,
          5,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }
    canvas.restore();

    // Labels ride outside the clip so the min and max read at full strength once
    // their point is revealed.
    final maxIndex = _indexOfMax(values);
    final minIndex = _indexOfMin(values);
    if (points[maxIndex].dx <= revealX) {
      _label(
        canvas,
        size,
        _fmt(values[maxIndex]),
        points[maxIndex],
        above: true,
      );
    }
    if (minIndex != maxIndex && points[minIndex].dx <= revealX) {
      _label(
        canvas,
        size,
        _fmt(values[minIndex]),
        points[minIndex],
        above: false,
      );
    }
  }

  void _label(
    Canvas canvas,
    Size size,
    String text,
    Offset at, {
    required bool above,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final maxDx = (size.width - painter.width).clamp(0.0, double.infinity);
    final dx = (at.dx - painter.width / 2).clamp(0.0, maxDx);
    final dy = above ? at.dy - painter.height - 8 : at.dy + 8;
    painter.paint(canvas, Offset(dx, dy));
  }

  String _fmt(double v) => v.toStringAsFixed(1);

  int _indexOfMax(List<double> xs) {
    var best = 0;
    for (var i = 1; i < xs.length; i++) {
      if (xs[i] > xs[best]) best = i;
    }
    return best;
  }

  int _indexOfMin(List<double> xs) {
    var worst = 0;
    for (var i = 1; i < xs.length; i++) {
      if (xs[i] < xs[worst]) worst = i;
    }
    return worst;
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values ||
      old.progress != progress ||
      old.lineColor != lineColor;
}
