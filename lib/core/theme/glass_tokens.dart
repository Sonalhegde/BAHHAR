import 'dart:ui';
import 'package:flutter/material.dart';

/// Standardized Glass Levels according to Section 2 of the Modernization Spec
enum GlassLevel {
  /// Subtle glass for passive section dividers, backdrop layers, and ambient cards
  subtle,

  /// Standard glass for interactive cards, stat chips, and list tiles
  standard,

  /// Prominent glass for floating navigation bars, modals, dialogs, and top overlays
  prominent,
}

class GlassTokens {
  // Blur intensities (sigma)
  static const double blurSubtle = 10.0;
  static const double blurStandard = 18.0;
  static const double blurProminent = 28.0;

  // Background tint opacities (Dark / Marine theme)
  static const double opacitySubtleDark = 0.22;
  static const double opacityStandardDark = 0.42;
  static const double opacityProminentDark = 0.68;

  // Background tint opacities (Light mode fallback)
  static const double opacitySubtleLight = 0.55;
  static const double opacityStandardLight = 0.72;
  static const double opacityProminentLight = 0.88;

  // Corner radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 20.0;
  static const double radiusPill = 999.0;

  // Border widths
  static const double borderWidth = 1.0;
  static const double borderWidthThick = 1.5;

  // Helper to obtain blur sigma
  static double getBlurSigma(GlassLevel level) {
    switch (level) {
      case GlassLevel.subtle:
        return blurSubtle;
      case GlassLevel.standard:
        return blurStandard;
      case GlassLevel.prominent:
        return blurProminent;
    }
  }

  // Helper to obtain background color
  static Color getBackgroundColor(GlassLevel level, {bool isDark = true}) {
    if (isDark) {
      switch (level) {
        case GlassLevel.subtle:
          return const Color(0xFF0F263D).withValues(alpha: opacitySubtleDark);
        case GlassLevel.standard:
          return const Color(0xFF0B1E33).withValues(alpha: opacityStandardDark);
        case GlassLevel.prominent:
          return const Color(0xFF071728).withValues(alpha: opacityProminentDark);
      }
    } else {
      switch (level) {
        case GlassLevel.subtle:
          return const Color(0xFFFFFFFF).withValues(alpha: opacitySubtleLight);
        case GlassLevel.standard:
          return const Color(0xFFF7FAFC).withValues(alpha: opacityStandardLight);
        case GlassLevel.prominent:
          return const Color(0xFFFFFFFF).withValues(alpha: opacityProminentLight);
      }
    }
  }

  // Dual-gradient border for glass reflection
  static LinearGradient getBorderGradient(GlassLevel level, {bool isDark = true}) {
    if (isDark) {
      switch (level) {
        case GlassLevel.subtle:
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.18),
              const Color(0xFF00B4D8).withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.04),
            ],
            stops: const [0.0, 0.5, 1.0],
          );
        case GlassLevel.standard:
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.32),
              const Color(0xFF00B4D8).withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.08),
            ],
            stops: const [0.0, 0.45, 1.0],
          );
        case GlassLevel.prominent:
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.48),
              const Color(0xFF00B4D8).withValues(alpha: 0.28),
              Colors.white.withValues(alpha: 0.15),
            ],
            stops: const [0.0, 0.4, 1.0],
          );
      }
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.85),
          const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.4),
        ],
      );
    }
  }
}
