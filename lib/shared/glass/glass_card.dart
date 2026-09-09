import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_tokens.dart';
import 'glass_container.dart';

/// Standard Reusable Glass Card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final GlassLevel level;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.borderRadius = GlassTokens.radiusMedium,
    this.level = GlassLevel.standard,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      level: level,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

/// Elevated Glass Card with subtle oceanic accent glow
class ElevatedGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? glowColor;
  final VoidCallback? onTap;

  const ElevatedGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = glowColor ?? AppColors.cyanAccent;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: GlassContainer(
        level: GlassLevel.prominent,
        borderRadius: GlassTokens.radiusMedium,
        padding: padding,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
