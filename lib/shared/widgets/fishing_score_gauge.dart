import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: probColor.withValues(alpha: 0.28),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ModernGaugePainter(score: score, color: probColor),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: AppTextStyles.display.copyWith(
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppColors.getProbabilityLabel(score),
                style: TextStyle(
                  fontSize: size * 0.11,
                  fontWeight: FontWeight.w600,
                  color: probColor,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernGaugePainter extends CustomPainter {
  final int score;
  final Color color;

  _ModernGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Track arc
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      trackPaint,
    );

    // Active progress arc
    final sweepAngle = math.pi * 1.5 * (score / 100.0).clamp(0.0, 1.0);
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
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
      old.score != score || old.color != color;
}
