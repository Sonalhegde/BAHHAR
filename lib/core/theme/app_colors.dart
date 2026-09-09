import 'package:flutter/material.dart';

/// BAHHAR Modernized Marine Design Tokens (Glassmorphic + Polymorphic System)
class AppColors {
  // ── Primary Marine Palette ──
  static const Color oceanAbyss = Color(0xFF05111E);       // Deepest abyss background
  static const Color oceanDeep = Color(0xFF071829);        // Atmospheric ocean canvas
  static const Color oceanNavy = Color(0xFF0B2540);        // Primary structural navy
  static const Color marineBlue = Color(0xFF0D3B66);       // Secondary marine blue
  static const Color cyanAccent = Color(0xFF00B4D8);       // High-tech oceanic crest / highlight
  static const Color cyanBright = Color(0xFF48CAE4);       // Micro-glow and active indicator
  static const Color seafoam = Color(0xFF90E0EF);          // Subtle coastal seafoam light

  // ── Glass Surfaces (Dark / Marine Mode) ──
  static const Color glassSubtle = Color(0x380F2A44);      // Subtle translucent backing
  static const Color glassStandard = Color(0x660B1F34);    // Standard glass card
  static const Color glassProminent = Color(0xA8071828);   // Prominent glass modal / floating nav
  static const Color glassBorder = Color(0x3DFFFFFF);      // Translucent hairline edge
  static const Color glassBorderGlow = Color(0x6600B4D8);  // Cyan active rim

  // ── Polymorphic / Soft-Depth Surface Tokens ──
  static const Color softSurfaceDark = Color(0xFF0C2238);   // Soft tactile base
  static const Color softShadowDark = Color(0x99020912);    // Ambient soft drop shadow
  static const Color softHighlightDark = Color(0x2EFFFFFF); // Top-left subtle bevel light

  // ── Semantic Signals (Muted, Highly Distinguishable) ──
  static const Color signalGood = Color(0xFF10B981);       // Emerald Green: Favorable / High Bite
  static const Color signalCaution = Color(0xFFF59E0B);    // Warm Amber: Moderate Opportunity
  static const Color signalAlert = Color(0xFFEF4444);      // Coral Red: Severe Weather / Hazard
  static const Color legalRestricted = Color(0xFF8B5CF6);  // Desaturated Violet: Nature Reserves (Daymaniyat)
  static const Color legalPermitted = Color(0xFF10B981);   // Open Waters

  // ── Typography & Ink Hierarchy ──
  static const Color textPrimary = Color(0xFFF8FAFC);      // Crisp high-contrast white text
  static const Color textSecondary = Color(0xFF94A3B8);    // Soft nautical slate text
  static const Color textTertiary = Color(0xFF64748B);     // Muted micro labels and timestamps
  static const Color textAccent = Color(0xFF38BDF8);       // Highlight text (Cyan)

  // ── Map & Bathymetry Layer Colors ──
  static const Color mapWater = Color(0xFF091C30);         // Nautical digital chart water
  static const Color mapLand = Color(0xFF142738);          // Omani coastal landmass
  static const Color mapContour = Color(0xFF1B3D5E);       // Depth contours / bathymetry grid

  // ── Backwards Compatibility Aliases (Preserves all existing code) ──
  static const Color bgPrimary = oceanDeep;
  static const Color bgSecondary = oceanNavy;
  static const Color cardWhite = glassStandard;
  static const Color hairline = glassBorder;
  static const Color surfacePure = oceanDeep;
  static const Color surfaceSubtle = glassSubtle;
  static const Color borderHairline = glassBorder;
  static const Color inkPrimary = textPrimary;
  static const Color inkSecondary = textSecondary;
  static const Color inkTertiary = textTertiary;
  static const Color accentNavy = cyanAccent;
  static const Color deepSea = oceanNavy;
  static const Color oceanBlue = cyanAccent;
  static const Color aquaTeal = signalGood;
  static const Color sandGold = signalCaution;
  static const Color coralRed = signalAlert;
  static const Color deepNavyText = textPrimary;
  static const Color mistGray = glassSubtle;
  static const Color borderGray = glassBorder;
  static const Color protectedArea = legalRestricted;
  static const Color restrictedZone = legalRestricted;
  static const Color permittedZone = legalPermitted;
  static const Color nightModeBg = oceanAbyss;
  static const Color nightSurface = glassStandard;
  static const Color nightBorder = glassBorder;

  // ── Probability Helpers ──
  static Color getProbabilityColor(int probability) {
    if (probability >= 70) return signalGood;
    if (probability >= 40) return signalCaution;
    return signalAlert;
  }

  static String getProbabilityLabel(int probability) {
    if (probability >= 70) return 'Optimal Bite';
    if (probability >= 40) return 'Moderate Activity';
    return 'Low Opportunity';
  }
}
