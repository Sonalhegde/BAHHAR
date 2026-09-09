import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Atmospheric Coastal Marine Background Wrapper
/// Features the exact soft coastal mountain/fjord silhouettes and ocean wave
/// layers seen in the reference design.
class MarineBackground extends StatelessWidget {
  final Widget child;
  final bool showHeadlandSilhouettes;

  const MarineBackground({
    super.key,
    required this.child,
    this.showHeadlandSilhouettes = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientTop,
      body: Stack(
        children: [
          // Base Soft Sky Gradient
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

          // Coastal Mountain & Wave Silhouettes at the bottom
          if (showHeadlandSilhouettes)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 320,
              child: CustomPaint(
                painter: _CoastalHeadlandsPainter(),
              ),
            ),

          // Foreground Interactive Content
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoastalHeadlandsPainter extends CustomPainter {
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

    // Layer 3: Foreground Ocean Waves
    final wavePaint = Paint()
      ..color = const Color(0xFFB8D7F5).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    path3.moveTo(0, h * 0.88);
    path3.quadraticBezierTo(w * 0.25, h * 0.82, w * 0.55, h * 0.88);
    path3.quadraticBezierTo(w * 0.80, h * 0.94, w, h * 0.86);
    path3.lineTo(w, h);
    path3.lineTo(0, h);
    path3.close();
    canvas.drawPath(path3, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
