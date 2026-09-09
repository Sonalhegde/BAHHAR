import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Bahhar AI official brand mark (Dhow sail + oceanic wave motif)
/// Hand-crafted vector Painter for crisp rendering at 48x48 up to hero sizes.
class BahharLogoWidget extends StatelessWidget {
  final double size;
  final Color color;
  final bool showWordmark;
  final TextStyle? wordmarkStyle;

  const BahharLogoWidget({
    super.key,
    this.size = 48.0,
    this.color = Colors.white,
    this.showWordmark = false,
    this.wordmarkStyle,
  });

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      size: Size(size, size),
      painter: _DhowSailPainter(color: color),
    );

    if (!showWordmark) {
      return mark;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BAHHAR AI',
              style: wordmarkStyle ??
                  TextStyle(
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: color,
                  ),
            ),
            Text(
              'بحّار',
              style: TextStyle(
                fontSize: size * 0.28,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DhowSailPainter extends CustomPainter {
  final Color color;

  _DhowSailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.width * 0.055).clamp(2.0, 7.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // 1. Triangular Dhow Sail (curved hypotenuse capturing wind)
    final sailPath = Path();
    sailPath.moveTo(w * 0.42, h * 0.20);
    // Right convex curve
    sailPath.quadraticBezierTo(w * 0.65, h * 0.40, w * 0.60, h * 0.58);
    // Flat bottom spar
    sailPath.lineTo(w * 0.42, h * 0.58);
    // Vertical mast
    sailPath.close();
    canvas.drawPath(sailPath, strokePaint);

    // Mast line extending downward into hull
    canvas.drawLine(
      Offset(w * 0.42, h * 0.58),
      Offset(w * 0.42, h * 0.65),
      strokePaint,
    );

    // 2. Dhow Hull
    final hullPath = Path();
    hullPath.moveTo(w * 0.22, h * 0.65);
    hullPath.lineTo(w * 0.32, h * 0.77);
    hullPath.quadraticBezierTo(w * 0.52, h * 0.81, w * 0.76, h * 0.70);
    hullPath.lineTo(w * 0.80, h * 0.65);
    hullPath.close();
    canvas.drawPath(hullPath, strokePaint);

    // 3. Oceanic Wave Line underneath
    final wavePath = Path();
    wavePath.moveTo(w * 0.12, h * 0.82);
    wavePath.quadraticBezierTo(w * 0.35, h * 0.74, w * 0.50, h * 0.85);
    wavePath.quadraticBezierTo(w * 0.70, h * 0.94, w * 0.90, h * 0.82);
    canvas.drawPath(wavePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _DhowSailPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
