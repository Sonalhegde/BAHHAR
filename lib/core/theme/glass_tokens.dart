import 'package:flutter/material.dart';

enum GlassLevel {
  subtle,
  standard,
  prominent,
}

class GlassTokens {
  static const double blurSubtle = 12.0;
  static const double blurStandard = 20.0;
  static const double blurProminent = 30.0;

  static const double radiusSmall = 10.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusPill = 999.0;

  static const double borderWidth = 1.0;

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

  static Color getBackgroundColor(GlassLevel level, {bool dark = false}) {
    if (dark) {
      switch (level) {
        case GlassLevel.subtle:
          return const Color(0xB821262D); // 72% night surface
        case GlassLevel.standard:
          return const Color(0xE021262D); // 88% night surface
        case GlassLevel.prominent:
          return const Color(0xF024292E); // 94% night card
      }
    }
    switch (level) {
      case GlassLevel.subtle:
        return const Color(0xB8FFFFFF); // 72% white
      case GlassLevel.standard:
        return const Color(0xE0FFFFFF); // 88% white
      case GlassLevel.prominent:
        return const Color(0xF7FFFFFF); // 97% white
    }
  }

  static LinearGradient getBorderGradient(GlassLevel level, {bool dark = false}) {
    // On dark glass the edge reads as a faint cool rim-light rather than the
    // light mode's white-to-blue sheen; one treatment serves every level.
    if (dark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.14),
          const Color(0xFF383E45).withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.05),
        ],
      );
    }
    switch (level) {
      case GlassLevel.subtle:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            const Color(0xFFD6E6F7).withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.4),
          ],
        );
      case GlassLevel.standard:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFBFDBFE).withValues(alpha: 0.65),
            Colors.white.withValues(alpha: 0.7),
          ],
        );
      case GlassLevel.prominent:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFF93C5FD).withValues(alpha: 0.8),
            Colors.white,
          ],
        );
    }
  }
}
