import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// Plays the app icon's gauge over the first frame of a cold start: the needle
/// sweeps up the dial, overshoots, settles where the icon holds it, and the
/// overlay fades away. Mounted once from the root app builder, so it runs when
/// the process starts and never again: returning from recents keeps this
/// widget's state alive, so the swing stays a cold start moment.
///
/// A user who has animations turned off at the system level gets the app
/// straight away with no overlay at all.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key, required this.child});

  final Widget child;

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// The needle's share of the timeline. easeOutBack carries it past the rest
  /// position once and brings it back, which is the whole point: one swing,
  /// like a cluster sweep at key on.
  late final Animation<double> _sweep = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
  );

  /// The overlay's exit, after a short hold on the settled gauge.
  late final Animation<double> _exit = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
  );

  var _started = false;
  var _done = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _done = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _done = true;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    final theme = Theme.of(context);
    // Amber on the dark scaffold is the icon exactly; on the light scaffold
    // amber sits under 2:1, so the light theme draws the gauge in ink.
    final gaugeColor = theme.brightness == Brightness.dark
        ? AppColors.amber
        : AppColors.ink;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        FadeTransition(
          opacity: ReverseAnimation(_exit),
          child: ExcludeSemantics(
            child: ColoredBox(
              color: theme.scaffoldBackgroundColor,
              child: Center(
                child: SizedBox.square(
                  dimension: 112,
                  child: AnimatedBuilder(
                    animation: _sweep,
                    builder: (context, _) => CustomPaint(
                      painter: _GaugePainter(
                        color: gaugeColor,
                        sweep: _sweep.value,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The launcher icon's gauge: an open arc with the gap at the bottom, a hub,
/// and a needle whose angle follows [sweep] from resting at the low end of the
/// dial to the icon's up and right pose. [sweep] runs past 1.0 during the
/// easeOutBack overshoot, which reads as the needle bouncing off its stop.
class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.color, required this.sweep});

  final Color color;
  final double sweep;

  static const _arcStart = 125 * math.pi / 180;
  static const _arcSpan = 290 * math.pi / 180;
  static const _needleFrom = 140 * math.pi / 180;
  static const _needleTo = 320 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final center = size.center(Offset.zero);
    final radius = side * 0.36;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _arcStart,
      _arcSpan,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.32
        ..strokeCap = StrokeCap.round,
    );

    final angle = _needleFrom + (_needleTo - _needleFrom) * sweep;
    final direction = Offset(math.cos(angle), math.sin(angle));
    canvas.drawLine(
      center - direction * (radius * 0.24),
      center + direction * (radius * 0.72),
      Paint()
        ..color = color
        ..strokeWidth = radius * 0.13
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, radius * 0.21, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.sweep != sweep || old.color != color;
}
