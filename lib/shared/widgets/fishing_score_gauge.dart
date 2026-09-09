import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Fishing probability gauge (Section 4.4)
/// Color-coded by probability band with animated semi-circular fill.
class FishingScoreGauge extends StatefulWidget {
  final int probability; // 0 to 100
  final double size;
  final String label;

  const FishingScoreGauge({
    super.key,
    required this.probability,
    this.size = 180.0,
    this.label = 'Fishing Opportunity',
  });

  @override
  State<FishingScoreGauge> createState() => _FishingScoreGaugeState();
}

class _FishingScoreGaugeState extends State<FishingScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.probability / 100.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant FishingScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.probability != widget.probability) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.probability / 100.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getProbabilityColor(widget.probability);
    final statusLabel = AppColors.getProbabilityLabel(widget.probability);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size * 0.72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugePainter(
                  progress: _animation.value,
                  activeColor: statusColor,
                  trackColor: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.nightBorder
                      : AppColors.borderGray,
                ),
              ),
              Positioned(
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(widget.probability * _animation.value / (widget.probability > 0 ? (widget.probability / 100.0) : 1)).round()}%',
                      style: AppTextStyles.display.copyWith(
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      statusLabel,
                      style: AppTextStyles.captionMedium.copyWith(
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.label,
                      style: AppTextStyles.micro.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : AppColors.deepNavyText.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;

  _GaugePainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.65);
    final radius = size.width * 0.42;
    const strokeWidth = 14.0;
    const startAngle = pi;
    const sweepAngle = pi;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw background track arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Draw active progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress.clamp(0.0, 1.0),
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
