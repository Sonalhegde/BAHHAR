import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../animations/app_animations.dart';

/// Atmospheric Coastal Marine Background Wrapper
/// Soft coastal mountain/fjord silhouettes with two slow, out-of-phase
/// drifting ocean wave layers for a gentle "alive water" texture.
class MarineBackground extends StatefulWidget {
  final Widget child;
  final bool showHeadlandSilhouettes;

  const MarineBackground({
    super.key,
    required this.child,
    this.showHeadlandSilhouettes = true,
  });

  @override
  State<MarineBackground> createState() => _MarineBackgroundState();
}

class _MarineBackgroundState extends State<MarineBackground>
    with SingleTickerProviderStateMixin {
  // Decorative chrome only: drives the slow headland/wave drift on a fixed loop.
  // It is NOT the live tide — real tide state/height arrives via MarineConditions.
  // Named `_waveDrift` (not `_tide`) so nobody mistakes ambient motion for data.
  late final AnimationController _waveDrift =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))
        ..repeat();

  @override
  void dispose() {
    _waveDrift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate =
        widget.showHeadlandSilhouettes && !reduceMotionOf(context);

    return Scaffold(
      backgroundColor: AppColors.bgGradientTop,
      body: Stack(
        children: [
          // Base Soft Sky Gradient with a faint warm sun glow top-right
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF9FBFE),
                    Color(0xFFF2F7FD),
                    Color(0xFFE4F0FB),
                    Color(0xFFD6E7F8),
                  ],
                  stops: [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.85, -0.9),
                    radius: 0.9,
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Coastal Mountain & animated Wave Silhouettes at the bottom
          if (widget.showHeadlandSilhouettes)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 320,
              child: animate
                  ? RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _waveDrift,
                        builder: (context, _) => CustomPaint(
                          painter: _CoastalHeadlandsPainter(phase: _waveDrift.value * 2 * math.pi),
                        ),
                      ),
                    )
                  : CustomPaint(
                      painter: _CoastalHeadlandsPainter(phase: 0),
                    ),
            ),

          // Foreground Interactive Content
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoastalHeadlandsPainter extends CustomPainter {
  final double phase;
  _CoastalHeadlandsPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Distant Misty Mountain Silhouette with Lighthouse Headland
    final mountainPaint1 = Paint()
      ..color = const Color(0xFFD8E7F8).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, h * 0.65);
    path1.quadraticBezierTo(w * 0.25, h * 0.55, w * 0.55, h * 0.45);
    // Lighthouse pinnacle
    path1.lineTo(w * 0.66, h * 0.38);
    path1.lineTo(w * 0.67, h * 0.34); // light tower
    path1.lineTo(w * 0.68, h * 0.38);
    path1.quadraticBezierTo(w * 0.85, h * 0.22, w, h * 0.12);
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();
    canvas.drawPath(path1, mountainPaint1);

    // Layer 2: Midground Coastal Range
    final mountainPaint2 = Paint()
      ..color = const Color(0xFFC7DEF5).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, h * 0.78);
    path2.quadraticBezierTo(w * 0.35, h * 0.68, w * 0.7, h * 0.52);
    path2.quadraticBezierTo(w * 0.88, h * 0.44, w, h * 0.35);
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();
    canvas.drawPath(path2, mountainPaint2);

    // Layer 3: Driving swell — slow full-width wave
    final wavePaintBack = Paint()
      ..color = const Color(0xFFC3DDF7).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawPath(_wavePath(w, h, baseY: 0.84, amp: 0.018, freq: 1.6, shift: phase * 0.55), wavePaintBack);

    // Layer 4: Foreground Ocean Wave — opposite drift for parallax
    final wavePaintFront = Paint()
      ..color = const Color(0xFFB8D7F5).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawPath(_wavePath(w, h, baseY: 0.90, amp: 0.014, freq: 2.4, shift: -phase * 0.85 + 1.3), wavePaintFront);
  }

  /// Samples a sine swell across the canvas width and closes it to the bottom.
  Path _wavePath(double w, double h,
      {required double baseY, required double amp, required double freq, required double shift}) {
    final path = Path();
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final x = w * i / steps;
      final u = i / steps;
      final y = h * (baseY + amp * math.sin(2 * math.pi * freq * u + shift));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _CoastalHeadlandsPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
