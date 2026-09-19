import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// BAHHAR shared motion toolkit.
/// All entrances use a single restrained choreography:
/// fade + gentle upward drift + micro scale, eased with easeOutCubic —
/// the "surface rising out of the water" signature motion.

/// True when the platform/user asked for reduced motion.
bool reduceMotionOf(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// One-shot entrance: fades, slides up and settles scale. [delay] allows
/// parent lists/sections to stagger children.
class SlideFadeReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final double startScale;
  final Curve curve;

  const SlideFadeReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 560),
    this.offsetY = 22,
    this.startScale = 0.985,
    this.curve = Curves.easeOutCubic,
  });

  /// Convenience stagger: children of a list pass their index.
  SlideFadeReveal.staggered({
    super.key,
    required this.child,
    required int index,
    this.duration = const Duration(milliseconds: 560),
    this.offsetY = 22,
    this.startScale = 0.985,
    this.curve = Curves.easeOutCubic,
  }) : delay = Duration(milliseconds: (index * 70).clamp(0, 560));

  @override
  State<SlideFadeReveal> createState() => _SlideFadeRevealState();
}

class _SlideFadeRevealState extends State<SlideFadeReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _anim =
      CurvedAnimation(parent: _controller, curve: widget.curve);

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
    if (reduceMotionOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _anim,
      child: widget.child,
      builder: (context, child) {
        final t = _anim.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - t)),
            child: Transform.scale(
              scale: widget.startScale + (1 - widget.startScale) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Pop-in entrance with a soft overshoot, for emblems and hero icons.
class ScaleFadePop extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const ScaleFadePop({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context)) return child;
    return SlideFadeReveal(
      delay: delay,
      duration: duration,
      offsetY: 14,
      startScale: 0.72,
      curve: Curves.easeOutBack,
      child: child,
    );
  }
}

/// Slow infinite "breathing" pulse (scale + glow) for hero emblems.
class BreathingPulse extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration period;

  const BreathingPulse({
    super.key,
    required this.child,
    this.minScale = 0.985,
    this.maxScale = 1.015,
    this.period = const Duration(milliseconds: 2600),
  });

  @override
  State<BreathingPulse> createState() => _BreathingPulseState();
}

class _BreathingPulseState extends State<BreathingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period)
        ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context) || !TickerMode.of(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final scale =
            widget.minScale + (widget.maxScale - widget.minScale) * Curves.easeInOut.transform(_controller.value);
        return Transform.scale(scale: scale, child: child);
      },
    );
  }
}

/// Counts from 0 to [value] once, for gauge/stat numbers.
class CountUpText extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Duration duration;
  final String Function(double v)? format;

  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 1100),
    this.format,
  });

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context)) {
      return Text(format?.call(value.toDouble()) ?? '$value', style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text(format?.call(v) ?? v.round().toString(), style: style),
    );
  }
}

/// Route transition: content rises like a swell — fade + short upward slide.
CustomTransitionPage<void> fadeSlidePage({
  required String keyName,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: ValueKey(keyName),
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.045), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}
