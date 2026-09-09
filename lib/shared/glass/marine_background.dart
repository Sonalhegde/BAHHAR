import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Atmospheric Deep Ocean Background Wrapper
/// Renders subtle oceanic depth gradients and organic ambient light spots
/// to provide optical contrast for floating glass surfaces.
class MarineBackground extends StatelessWidget {
  final Widget child;
  final bool showAmbientGlow;

  const MarineBackground({
    super.key,
    required this.child,
    this.showAmbientGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oceanAbyss,
      body: Stack(
        children: [
          // Base deep ocean linear gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF04101D),
                    Color(0xFF07192C),
                    Color(0xFF0A223B),
                    Color(0xFF061424),
                  ],
                  stops: [0.0, 0.35, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // Ambient subtle radial light (Coastal luminescence)
          if (showAmbientGlow) ...[
            // Top-right subtle cyan ambient light
            Positioned(
              top: -60,
              right: -80,
              width: 320,
              height: 320,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00B4D8).withValues(alpha: 0.12),
                      const Color(0xFF0077B6).withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Bottom-left deep oceanic upwelling glow
            Positioned(
              bottom: 80,
              left: -100,
              width: 360,
              height: 360,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0D3B66).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ],

          // Foreground content
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
