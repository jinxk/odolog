import 'package:flutter/material.dart';

/// Small, calm motion primitives shared across screens. Everything eases out and
/// runs once, so nothing bounces or loops: the point is to make a value feel
/// physical when it lands, not to draw attention to the animation itself. Each
/// animation settles in well under a second so a widget test can drain it with
/// pumpAndSettle.

/// Counts a numeric figure up to [value] on mount and re-animates only when
/// [value] itself changes, not on every rebuild.
///
/// The tween ignores its own begin after the first build, so a data change
/// animates from the currently shown number to the new one rather than snapping
/// back to zero. [format] turns the animated double into the displayed string,
/// which keeps units and decimal places in one place at the call site.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    required this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  final double value;
  final String Function(double) format;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => Text(format(animated), style: style),
    );
  }
}

/// Fades and lifts [child] into place once, the moment it mounts.
///
/// [delay] staggers a group of these so a header lands just before the section
/// under it. The slide distance is small on purpose: it reads as settling, not
/// flying in. Rebuilds after the entrance do nothing, so provider updates behind
/// the widget never replay it.
class EntranceFade extends StatefulWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 8,
  });

  final Widget child;

  /// Head start before this element begins, used to stagger siblings.
  final Duration delay;

  /// Vertical distance in logical pixels the child rises through on entry.
  final double offset;

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curve.value) * widget.offset),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
