import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/glass_tokens.dart';

/// Core Glassmorphic Container
/// Combines optical blur, dual-gradient border, and subtle inner highlight.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final GlassLevel level;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? customColor;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.level = GlassLevel.standard,
    this.borderRadius = GlassTokens.radiusMedium,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
    this.customColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final blurSigma = GlassTokens.getBlurSigma(level);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        customColor ?? GlassTokens.getBackgroundColor(level, dark: dark);
    final borderGradient =
        GlassTokens.getBorderGradient(level, dark: dark);

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.transparent, // Overwritten by gradient border via CustomPainter or subtle border
                width: 0,
              ),
            ),
            child: CustomPaint(
              painter: _GlassBorderPainter(
                gradient: borderGradient,
                borderRadius: borderRadius,
                borderWidth: GlassTokens.borderWidth,
              ),
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}

class _GlassBorderPainter extends CustomPainter {
  final LinearGradient gradient;
  final double borderRadius;
  final double borderWidth;

  _GlassBorderPainter({
    required this.gradient,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      borderWidth / 2,
      borderWidth / 2,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter old) =>
      old.borderRadius != borderRadius || old.borderWidth != borderWidth;
}
