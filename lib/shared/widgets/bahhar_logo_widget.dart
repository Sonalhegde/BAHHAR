import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// The signature BAHHAR logo mark as seen in the reference design:
/// A triangular dhow sail / mountain apex with smooth wave ripples underneath.
class BahharLogoWidget extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showWordmark;
  final bool showSubtitle;
  final bool showArabic;

  const BahharLogoWidget({
    super.key,
    this.size = 72,
    this.color,
    this.showWordmark = true,
    this.showSubtitle = true,
    this.showArabic = true,
  });

  @override
  Widget build(BuildContext context) {
    final emblemColor = color ?? AppColors.primaryBlue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The Vector Sail + Wave Emblem
        SizedBox(
          width: size,
          height: size * 0.9,
          child: CustomPaint(
            painter: _BahharSailWavePainter(color: emblemColor),
          ),
        ),

        if (showWordmark) ...[
          const SizedBox(height: 14),
          Text(
            'BAHHAR',
            style: AppTextStyles.screenTitle.copyWith(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.5,
              color: AppColors.oceanNavy,
            ),
          ),
        ],

        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            'Oman Smart Marine Companion',
            style: AppTextStyles.caption.copyWith(
              fontSize: size * 0.19,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],

        if (showArabic) ...[
          const SizedBox(height: 14),
          Container(
            width: 32,
            height: 2.5,
            decoration: BoxDecoration(
              color: emblemColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'بَحّار',
            style: TextStyle(
              fontSize: size * 0.44,
              fontWeight: FontWeight.w700,
              color: AppColors.oceanNavy,
              fontFamily: 'sans-serif',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'رَفِيقُكَ الذَّكِي لِلمَلَاحَة فِي عُمَان',
            style: TextStyle(
              fontSize: size * 0.18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _BahharSailWavePainter extends CustomPainter {
  final Color color;
  _BahharSailWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.085;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // 1. Triangular Sail Apex (with open bottom)
    final sailPath = Path();
    sailPath.moveTo(w * 0.16, h * 0.68);
    sailPath.lineTo(w * 0.50, h * 0.08);
    sailPath.lineTo(w * 0.84, h * 0.68);
    canvas.drawPath(sailPath, paint);

    // 2. Wave Ripple at base
    final wavePath = Path();
    wavePath.moveTo(w * 0.12, h * 0.76);
    wavePath.quadraticBezierTo(w * 0.22, h * 0.62, w * 0.32, h * 0.76);
    wavePath.quadraticBezierTo(w * 0.42, h * 0.90, w * 0.52, h * 0.76);
    wavePath.quadraticBezierTo(w * 0.62, h * 0.62, w * 0.72, h * 0.76);
    wavePath.quadraticBezierTo(w * 0.82, h * 0.90, w * 0.88, h * 0.76);
    canvas.drawPath(wavePath, paint);
  }

  @override
  bool shouldRepaint(covariant _BahharSailWavePainter old) => old.color != color;
}
