import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/animations/app_animations.dart';

/// Sweeps its progress arc up from zero and counts the score number up,
/// re-animating smoothly whenever [score] changes.
class FishingScoreGauge extends StatelessWidget {
  final int score;
  final double size;

  const FishingScoreGauge({
    super.key,
    required this.score,
    this.size = 84,
  });

  @override
  Widget build(BuildContext context) {
    final probColor = AppColors.getProbabilityColor(score);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (score / 100).clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, fraction, _) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: probColor.withValues(alpha: 0.18 * fraction),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _ModernGaugePainter(fraction: fraction, color: probColor),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CountUpText(
                    value: score,
                    duration: const Duration(milliseconds: 1100),
                    style: TextStyle(
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: AppColors.oceanNavy,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppColors.getProbabilityLabel(score),
                    style: TextStyle(
                      fontSize: size * 0.11,
                      fontWeight: FontWeight.w700,
                      color: probColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModernGaugePainter extends CustomPainter {
  final double fraction;
  final Color color;

  _ModernGaugePainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFE2EDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      trackPaint,
    );

    // Active progress arc (animated sweep)
    final sweepAngle = math.pi * 1.5 * fraction;
    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.65), color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ModernGaugePainter old) =>
      old.fraction != fraction || old.color != color;
}
