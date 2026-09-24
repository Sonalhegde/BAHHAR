import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/tide_curve.dart';
import '../../core/theme/app_color_tokens.dart';
import '../../core/theme/app_text_styles.dart';

/// The rising/falling tide line drawn between high and low water.
///
/// A hand-painted Canvas 2D curve (CustomPainter), deliberately in the same
/// idiom as the map's flow_overlay_widget: a glowing stroke over a soft
/// gradient fill, no charting package. It reads the whole [TideCurve.points]
/// series so the fisherman sees where the water is going, not just where it is.
///
/// Honesty: it draws only what the provider returned. An empty or unavailable
/// curve renders a labelled placeholder rather than a flat invented line.
class TideChart extends StatelessWidget {
  const TideChart({
    super.key,
    required this.curve,
    this.height = 104,
    this.isArabic = false,
  });

  final TideCurve curve;
  final double height;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    if (curve.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            isArabic ? 'بيانات المد غير متوفرة' : 'Tide curve unavailable',
            style: AppTextStyles.caption.copyWith(color: context.colors.textTertiary),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _TideCurvePainter(curve, context.colors)),
    );
  }
}

class _TideCurvePainter extends CustomPainter {
  _TideCurvePainter(this.curve, this.tokens);

  final TideCurve curve;
  final AppColorTokens tokens;

  static const double _padY = 16;
  static const double _padX = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = curve.points;
    final t0 = pts.first.time.microsecondsSinceEpoch.toDouble();
    final t1 = pts.last.time.microsecondsSinceEpoch.toDouble();
    final spanT = (t1 - t0) == 0 ? 1.0 : (t1 - t0);

    double lo = curve.minM;
    double hi = curve.maxM;
    if (hi - lo < 0.1) {
      // A near-flat spring window still needs room to breathe.
      final mid = (hi + lo) / 2;
      lo = mid - 0.5;
      hi = mid + 0.5;
    }
    final padH = (hi - lo) * 0.18;
    lo -= padH;
    hi += padH;
    final spanH = hi - lo;

    final usableW = size.width - _padX * 2;
    final usableH = size.height - _padY * 2;

    Offset xy(TidePoint p) {
      final fx = (p.time.microsecondsSinceEpoch.toDouble() - t0) / spanT;
      final fy = (p.heightM - lo) / spanH;
      return Offset(_padX + fx * usableW, size.height - _padY - fy * usableH);
    }

    final anchors = pts.map(xy).toList();

    // Smooth tide-like path: quadratics through segment midpoints.
    final line = Path()..moveTo(anchors.first.dx, anchors.first.dy);
    for (var i = 1; i < anchors.length - 1; i++) {
      final mid = Offset(
        (anchors[i].dx + anchors[i + 1].dx) / 2,
        (anchors[i].dy + anchors[i + 1].dy) / 2,
      );
      line.quadraticBezierTo(anchors[i].dx, anchors[i].dy, mid.dx, mid.dy);
    }
    line.lineTo(anchors.last.dx, anchors.last.dy);

    // Fill under the curve to the baseline.
    final fill = Path.from(line)
      ..lineTo(anchors.last.dx, size.height)
      ..lineTo(anchors.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tokens.primaryBlue.withValues(alpha: 0.22),
            tokens.primaryBlue.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    // Mean-water reference line.
    final zeroY = size.height - _padY - ((0 - lo) / spanH) * usableH;
    if (zeroY > _padY && zeroY < size.height - _padY) {
      canvas.drawLine(
        Offset(_padX, zeroY),
        Offset(size.width - _padX, zeroY),
        Paint()
          ..color = tokens.mapContour
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }

    // Glowing curve stroke.
    canvas.drawPath(
      line,
      Paint()
        ..color = tokens.cyanAccent.withValues(alpha: 0.35)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = tokens.primaryBlue
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // "Now" marker: dashed vertical + dot at the live height.
    final now = curve.pointAtNow();
    if (now != null) {
      final c = xy(now);
      final dash = Paint()
        ..color = tokens.skyBlue
        ..strokeWidth = 1.2;
      const seg = 4.0;
      for (var y = _padY * 0.5; y < size.height - _padY; y += seg * 2) {
        canvas.drawLine(
          Offset(c.dx, y),
          Offset(c.dx, math.min(y + seg, size.height - _padY)),
          dash,
        );
      }
      canvas.drawCircle(c, 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(c, 3.2, Paint()..color = tokens.primaryBlue);
    }
  }

  @override
  bool shouldRepaint(_TideCurvePainter old) => old.curve != curve;
}
