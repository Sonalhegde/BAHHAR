import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bahhar/core/theme/app_colors.dart';
import 'package:bahhar/core/theme/app_text_styles.dart';
import 'package:bahhar/shared/animations/app_animations.dart';

/// Circular / arc fishing-opportunity index gauge (0 – 100%).
///
/// A 270° arc that sweeps up from zero on first build and re-animates whenever
/// [index] changes, tinted by the probability band ([AppColors.getProbabilityColor])
/// with the numeric readout counting up alongside. Honours reduced-motion: the
/// arc renders at its final value immediately and the number is shown without a
/// tick loop, matching the progressive-enhancement behaviour used elsewhere in
/// the app. Optional [caption] sits under the number (e.g. "bite window").
class OpportunityGaugeWidget extends StatelessWidget {
  const OpportunityGaugeWidget({
    super.key,
    required this.index,
    this.size = 132,
    this.label,
    this.caption,
    this.isArabic = false,
  });

  /// Opportunity index, 0–100. Out-of-range values are clamped.
  final int index;
  final double size;

  /// Overrides the auto band label (e.g. "Optimal Bite").
  final String? label;

  /// Small line rendered under the label.
  final String? caption;
  final bool isArabic;

  static const double _startAngle = math.pi * 0.75; // 135°
  static const double _sweepFull = math.pi * 1.5; // 270°

  @override
  Widget build(BuildContext context) {
    final clamped = index.clamp(0, 100);
    final color = AppColors.getProbabilityColor(clamped);
    final bandLabel = label ?? AppColors.getProbabilityLabel(clamped);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: clamped / 100),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, fraction, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ArcPainter(
              fraction: fraction,
              color: color,
              startAngle: _startAngle,
              sweepFull: _sweepFull,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CountUpText(
                    value: clamped,
                    duration: const Duration(milliseconds: 1100),
                    format: (v) => '${v.round()}%',
                    style: AppTextStyles.stat.copyWith(color: AppColors.oceanNavy),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bandLabel,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.micro.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (caption != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        caption!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
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

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.fraction,
    required this.color,
    required this.startAngle,
    required this.sweepFull,
  });

  final double fraction;
  final Color color;
  final double startAngle;
  final double sweepFull;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * 0.085;
    final radius = size.width / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = const Color(0xFFE2EDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepFull, false, track);

    final active = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.65), color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepFull * fraction, false, active);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.fraction != fraction || old.color != color;
}
