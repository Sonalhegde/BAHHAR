import 'package:flutter/material.dart';

/// Design tokens from Bahhar AI Master Specification Section 4.1
class AppColors {
  // Brand & Nav
  static const Color deepSea = Color(0xFF0B3D5C);       // Primary brand color, headers, primary buttons
  static const Color oceanBlue = Color(0xFF1C7293);     // Secondary actions, links, active nav states
  static const Color deepNavyText = Color(0xFF10222E);  // Primary text on light backgrounds
  static const Color mistGray = Color(0xFFF4F7F9);      // App background (light)
  static const Color cardWhite = Color(0xFFFFFFFF);     // Card surfaces
  static const Color borderGray = Color(0xFFDCE4E8);    // Dividers, card borders

  // Night Mode (Dawn/Dusk for fishermen)
  static const Color nightModeBg = Color(0xFF071824);   // Dark-mode background
  static const Color nightSurface = Color(0xFF0F2636);  // Dark-mode card/surface
  static const Color nightBorder = Color(0xFF1B3B52);   // Dark-mode border

  // Traffic-Light Fishing Probability (RESERVED EXCLUSIVELY for probability indicators)
  static const Color aquaTeal = Color(0xFF2FBF8F);      // High probability / good conditions (>= 70%)
  static const Color sandGold = Color(0xFFE8B84B);      // Medium probability / warning (40% - 69%)
  static const Color coralRed = Color(0xFFE2543B);      // Low probability / danger (< 40%)

  // Regulatory & Protected Areas (DISTINCT VIOLET to never confuse with low probability red)
  static const Color protectedArea = Color(0xFF6A4C93); // Nature reserves / protected marine areas
  static const Color restrictedZone = Color(0xFF8B5CF6);// Military / restricted anchorage zones
  static const Color permittedZone = Color(0xFF10B981); // Open recreational/commercial fishing

  // Utility helpers
  static Color getProbabilityColor(int probability) {
    if (probability >= 70) return aquaTeal;
    if (probability >= 40) return sandGold;
    return coralRed;
  }

  static String getProbabilityLabel(int probability) {
    if (probability >= 70) return 'High';
    if (probability >= 40) return 'Moderate';
    return 'Low';
  }
}
